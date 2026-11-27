#!/usr/bin/env python3
"""Build lucien.ch.

1. Walk content/ and assets/, read git dates, write build/manifest.json.
2. Run `typst compile --format bundle site.typ dist/`.
3. Optionally index dist/ with Pagefind (--search).

Usage:
    python3 scripts/build.py            # build into dist/
    python3 scripts/build.py --watch    # typst watch with live reload on :3000
    python3 scripts/build.py --search   # also run pagefind (needs npx)
    python3 scripts/build.py --editor   # also build the /edit/ page (needs npm)
    python3 scripts/build.py --drafts   # private build: include drafts, behind GitHub login

Drafts (`draft: true` in a file's template call) are left out of the normal
build entirely: no page, no listing, no search entry, no graph node, no feed
item, and links to them from public pages render as plain text. The --drafts
build includes them and writes a `_worker.js` that only lets through requests
signed by Cloudflare Access (GitHub login), see DRAFTS_WORKER. Without
$DRAFTS_ACCESS_TEAM it refuses every request.
"""
from __future__ import annotations

import argparse
import base64
import gzip
import json
import re
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import tempfile
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
ASSETS = ROOT / "assets"
BUILD = ROOT / "build"
DIST = ROOT / "dist"
DRAFTS = False  # set by --drafts

EDITOR = ROOT / "editor"

# Versions of the in-browser compiler; typst-wasm 1.0.0 embeds Typst 0.15.
EDITOR_NPM = {"typst-wasm": "1.0.0", "@typst-wasm/fonts": "1.0.0", "nanotar": "0.2.1"}
# Tinymist (Typst language server) for the editor; CI builds it for the
# browser (see .github/workflows/build.yml) and passes it in TINYMIST_PKG.
TINYMIST_VERSION = "0.15.2"
EDITOR_FONTS = ["NewCM10-Regular.otf", "NewCM10-Italic.otf", "NewCM10-Bold.otf",
                "NewCM10-BoldItalic.otf", "NewCMMath-Regular.otf", "DejaVuSansMono.ttf"]

DATED = re.compile(r"^(\d{4}-\d{2}-\d{2})-(.+)$")
LABEL_DEF = re.compile(r"(?<![(\w])<([A-Za-z_][\w:.-]*)>")  # <label>, not #link(<label>)
SLUG = re.compile(r"^[a-z0-9][a-z0-9-]*$")
TEMPLATE_CALL = re.compile(r"#show:\s*(?:post|note|page)\.with\(")
DRAFT_ARG = re.compile(r"(?<![\w-])draft\s*:\s*true(?![\w-])")


def is_draft(path: Path) -> bool:
    """True if the file's `#show: post/note/page.with(...)` call says `draft: true`.

    The templates also check this at compile time and stop the public build if
    a draft slipped through, so a miss here fails loudly instead of leaking.
    """
    text = path.read_text(encoding="utf-8")
    m = TEMPLATE_CALL.search(text)
    if not m:
        return False
    depth, i = 1, m.end()
    while i < len(text) and depth:
        depth += {"(": 1, ")": -1}.get(text[i], 0)
        i += 1
    return bool(DRAFT_ARG.search(text[m.end():i]))


def git_dates(path: Path) -> tuple[str | None, str | None]:
    """First and last commit dates (YYYY-MM-DD) of a file, or None if untracked."""
    try:
        out = subprocess.run(
            ["git", "log", "--follow", "--format=%cs", "--", str(path.relative_to(ROOT))],
            cwd=ROOT, capture_output=True, text=True, check=True,
        ).stdout.split()
    except (subprocess.CalledProcessError, FileNotFoundError):
        out = []
    if not out:
        return None, None
    return out[-1], out[0]


def page_entries() -> tuple[list[dict], list[str]]:
    """Pages to build, and the slugs of drafts left out of this build."""
    today = date.today().isoformat()
    entries: list[dict] = []
    hidden: list[str] = []
    seen: dict[str, Path] = {}
    sections = {
        "posts": lambda slug: f"blog/{slug}",
        "garden": lambda slug: f"garden/{slug}",
        "pages": lambda slug: slug,
        # The thesis: content/thesis/index.typ is /thesis/ (slug "thesis"),
        # content/thesis/<stem>.typ is /thesis/<stem>/ (slug "thesis-<stem>").
        "thesis": lambda slug: "thesis" if slug == "thesis" else "thesis/" + slug.removeprefix("thesis-"),
    }
    for section, prefix in sections.items():
        for path in sorted((CONTENT / section).glob("*.typ")):
            stem = path.stem
            post_date = None
            if section == "posts":
                m = DATED.match(stem)
                if not m:
                    sys.exit(f"error: post {path} must be named YYYY-MM-DD-slug.typ")
                post_date, stem = m.groups()
            slug = stem
            if section == "thesis":
                slug = "thesis" if stem == "index" else f"thesis-{stem}"
            if not SLUG.match(slug):
                sys.exit(f"error: {path}: slug '{slug}' must be lowercase letters, digits and dashes")
            if slug in seen:
                sys.exit(f"error: slug '{slug}' used by both {seen[slug]} and {path}")
            seen[slug] = path
            draft = is_draft(path)
            if draft and not DRAFTS:
                # The page's slug and the labels it defines (equations,
                # figures, sections), so links into it can be dropped too.
                hidden.append(slug)
                hidden.extend(l for l in LABEL_DEF.findall(path.read_text(encoding="utf-8")) if l not in hidden)
                continue
            created, updated = git_dates(path)
            base = prefix(slug)
            entries.append({
                "slug": slug,
                "section": section,
                "path": "/" + str(path.relative_to(ROOT)),
                "out": f"{base}/index.html",
                "url": f"/{base}/",
                "date": post_date,
                "created": created or post_date or today,
                "updated": updated or post_date or today,
                "draft": draft,
            })
    return entries, hidden


def asset_entries() -> list[dict]:
    return [
        {"path": "/" + str(p.relative_to(ROOT)), "out": str(p.relative_to(ROOT))}
        for p in sorted(ASSETS.rglob("*")) if p.is_file()
    ]


def typst_package_cache() -> Path:
    if os.environ.get("TYPST_PACKAGE_CACHE_PATH"):
        return Path(os.environ["TYPST_PACKAGE_CACHE_PATH"])
    if platform.system() == "Darwin":
        return Path.home() / "Library/Caches/typst/packages"
    if platform.system() == "Windows":
        return Path(os.environ.get("LOCALAPPDATA", Path.home())) / "typst/packages"
    return Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "typst/packages"


def npm_unpack(spec: str, dest: Path) -> Path:
    """Download an npm package tarball and unpack it; returns its package/ dir."""
    out = subprocess.run(["npm", "pack", spec, "--silent", "--pack-destination", str(dest)],
                         capture_output=True, text=True, check=True).stdout.strip().splitlines()[-1]
    target = dest / spec.replace("/", "__").replace("@", "")
    with tarfile.open(dest / out) as tar:
        # filter= needs Python 3.12+ (or a 3.9-3.11 security backport).
        if hasattr(tarfile, "data_filter"):
            tar.extractall(target, filter="data")
        else:
            tar.extractall(target)
    return target / "package"


def draft_paths() -> set[str]:
    """Repo-relative paths of draft content files."""
    return {p.relative_to(ROOT).as_posix() for p in CONTENT.rglob("*.typ") if is_draft(p)}


# Cloudflare Pages advanced-mode worker for the drafts build. The site sits
# behind Cloudflare Access (GitHub login); this worker checks Access's signed
# JWT on every request as a second lock, so the drafts stay closed even if the
# Access application is missing or misconfigured. The team name comes from
# $DRAFTS_ACCESS_TEAM (without it the worker refuses everything); the
# application's audience tag from $DRAFTS_ACCESS_AUD narrows it further. Pages never serves _worker.js itself.
DRAFTS_WORKER = """// Generated by scripts/build.py --drafts. Cloudflare Access check for the drafts site.
const TEAM = %(team)s;  // <team>.cloudflareaccess.com
const AUD = %(aud)s;    // Access application audience (AUD) tag; optional, see below
const EXTRA = {
  "Cross-Origin-Opener-Policy": "same-origin",
  "Cross-Origin-Embedder-Policy": "require-corp",
  "X-Robots-Tag": "noindex, nofollow",
  "Cache-Control": "private, no-store",
};
let keys = null, keysAt = 0;
async function getKeys() {
  if (keys && Date.now() - keysAt < 3600e3) return keys;
  const r = await fetch(`https://${TEAM}.cloudflareaccess.com/cdn-cgi/access/certs`);
  if (!r.ok) throw new Error("certs " + r.status);
  const { keys: jwks } = await r.json();
  keys = {};
  for (const k of jwks) {
    keys[k.kid] = await crypto.subtle.importKey("jwk", k, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["verify"]);
  }
  keysAt = Date.now();
  return keys;
}
const b64u = s => Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/")), c => c.charCodeAt(0));
async function allowed(request) {
  if (!TEAM) return false;
  const jwt = request.headers.get("Cf-Access-Jwt-Assertion");
  if (!jwt) return false;
  const parts = jwt.split(".");
  if (parts.length !== 3) return false;
  try {
    const header = JSON.parse(new TextDecoder().decode(b64u(parts[0])));
    const claims = JSON.parse(new TextDecoder().decode(b64u(parts[1])));
    if (header.alg !== "RS256") return false;
    const key = (await getKeys())[header.kid];
    if (!key) return false;
    const ok = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", key, b64u(parts[2]), new TextEncoder().encode(parts[0] + "." + parts[1]));
    if (!ok) return false;
    const aud = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
    const now = Date.now() / 1000;
    // Without an AUD tag, any token signed by this team's Access is accepted:
    // only people its policies let in can get one.
    return (!AUD || aud.includes(AUD)) && claims.iss === `https://${TEAM}.cloudflareaccess.com` && claims.exp > now;
  } catch {
    return false;
  }
}
export default {
  async fetch(request, env) {
    if (!(await allowed(request))) {
      return new Response(TEAM ? "Drafts are private. Sign in through Cloudflare Access." : "Drafts are not set up yet (no Cloudflare Access team).", {
        status: 403,
        headers: { "Content-Type": "text/plain; charset=utf-8", ...EXTRA },
      });
    }
    const r = await env.ASSETS.fetch(request);
    const out = new Response(r.body, r);
    for (const [k, v] of Object.entries(EXTRA)) out.headers.set(k, v);
    return out;
  },
};
"""


def write_drafts_gate() -> None:
    team = os.environ.get("DRAFTS_ACCESS_TEAM", "").strip().removesuffix(".cloudflareaccess.com")
    aud = os.environ.get("DRAFTS_ACCESS_AUD", "").strip()
    (DIST / "_worker.js").write_text(DRAFTS_WORKER % {"team": json.dumps(team), "aud": json.dumps(aud)})
    (DIST / "robots.txt").write_text("User-agent: *\nDisallow: /\n")
    print("drafts: Access check " + (f"on (team {team}, {'with' if aud else 'no'} AUD tag)" if team else
          "LOCKED (DRAFTS_ACCESS_TEAM not set)"))


def write_cors_headers() -> None:
    """Let giscus' iframe (giscus.app) load the comments theme and its fonts."""
    with open(DIST / "_headers", "a") as f:
        for path in ("/assets/giscus.css", "/assets/fonts/*"):
            f.write(f"{path}\n  Access-Control-Allow-Origin: *\n")


def build_editor() -> None:
    """Copy editor/ to dist/edit/ and vendor the compiler, fonts and packages."""
    out = DIST / "edit"
    shutil.copytree(EDITOR, out, ignore=shutil.ignore_patterns("README.md", "codemirror-entry.js"))
    vendor = out / "vendor"
    # Cloudflare Pages header rules: cross-origin isolation lets the editor use
    # typst-wasm's worker backend (SharedArrayBuffer). Without it, it falls
    # back to JSPI, which only recent Chromium-based browsers have.
    # require-corp (not credentialless) because Safari supports only that.
    # Only /edit/ is always isolated: isolation would also block the giscus
    # comments iframe for every reader. Pages get isolated only while the
    # editor is docked on them (edit=1 cookie, see functions/_middleware.js).
    (DIST / "_headers").write_text(
        "/edit/*\n"
        "  Cross-Origin-Opener-Policy: same-origin\n"
        "  Cross-Origin-Embedder-Policy: require-corp\n"
    )
    # Run that function on pages only, not on static files. Not on the drafts
    # site, whose _worker.js must see every request (it is the Access check).
    if not DRAFTS:
        (DIST / "_routes.json").write_text(json.dumps({
            "version": 1, "include": ["/*"],
            "exclude": ["/assets/*", "/edit/*", "/pagefind/*", "/feed.xml"],
        }) + "\n")
    with tempfile.TemporaryDirectory() as tmp:
        t = Path(tmp)
        tw = npm_unpack(f"typst-wasm@{EDITOR_NPM['typst-wasm']}", t)
        shutil.copytree(tw / "dist", vendor / "typst-wasm", ignore=shutil.ignore_patterns("*.map", "*.d.ts"))
        fonts = npm_unpack(f"@typst-wasm/fonts@{EDITOR_NPM['@typst-wasm/fonts']}", t)
        (vendor / "fonts").mkdir(parents=True, exist_ok=True)
        for f in EDITOR_FONTS:
            shutil.copy(fonts / "dist/files" / f, vendor / "fonts" / f)
        nt = npm_unpack(f"nanotar@{EDITOR_NPM['nanotar']}", t)
        (vendor / "nanotar").mkdir(exist_ok=True)
        shutil.copy(nt / "dist/index.mjs", vendor / "nanotar/index.mjs")
    vendor_tinymist(vendor / "tinymist")
    # Snapshot of the sources, used when GitHub's API can't be reached.
    snap = {}
    skip = set() if DRAFTS else draft_paths()
    for d in ("content", "lib", "data"):
        for f in sorted((ROOT / d).rglob("*")):
            if f.is_file():
                rel = f.relative_to(ROOT).as_posix()
                if rel in skip:
                    continue
                try:
                    snap[rel] = f.read_text(encoding="utf-8")
                except UnicodeDecodeError:
                    snap[rel] = {"base64": base64.b64encode(f.read_bytes()).decode()}
    # The branch the editor reads and commits to by default: the one this
    # site was built from (CI sets GITHUB_HEAD_REF on pull requests).
    branch = os.environ.get("GITHUB_HEAD_REF") or os.environ.get("GITHUB_REF_NAME") or subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip() or "main"
    (out / "build.json").write_text(json.dumps({"branch": branch, "built": date.today().isoformat()}))
    (out / "snapshot.json").write_text(json.dumps(
        {"built": date.today().isoformat(), "files": snap}, ensure_ascii=False))
    # Mirror the Typst packages this build used, so the editor works offline
    # from the registry and with exactly the same versions.
    cache = typst_package_cache()
    n = 0
    for version_dir in sorted(cache.glob("*/*/*")):
        if not version_dir.is_dir():
            continue
        ns, name, version = version_dir.parts[-3:]
        dest = vendor / "packages" / ns / f"{name}-{version}.tar.gz"
        dest.parent.mkdir(parents=True, exist_ok=True)
        with tarfile.open(dest, "w:gz") as tar:
            for p in sorted(version_dir.rglob("*")):
                tar.add(p, arcname=str(p.relative_to(version_dir)), recursive=False)
        n += 1
    (vendor / "packages" / "index.json").write_text(json.dumps(sorted(
        p.relative_to(vendor / "packages").as_posix() for p in (vendor / "packages").rglob("*.tar.gz"))))
    print(f"editor: built dist/edit/ with {n} mirrored Typst packages")


def vendor_tinymist(dest: Path) -> None:
    """Add the browser build of tinymist (completion, hover, go to definition).

    Optional: without it the editor works as before. TINYMIST_PKG points at a
    wasm-pack output (crates/tinymist/pkg) or at CI's cached copy. The wasm is
    ~36 MB, over Cloudflare Pages' 25 MiB file limit, so it ships gzipped and
    the editor unpacks it.
    """
    src = Path(os.environ.get("TINYMIST_PKG") or "/nonexistent")
    if not (src / "tinymist.js").exists():
        print("editor: tinymist not added (set TINYMIST_PKG to a wasm-pack build)")
        return
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy(src / "tinymist.js", dest / "tinymist.js")
    if (src / "tinymist_bg.wasm.gz").exists():
        shutil.copy(src / "tinymist_bg.wasm.gz", dest / "tinymist_bg.wasm.gz")
    else:
        with open(src / "tinymist_bg.wasm", "rb") as f, gzip.open(dest / "tinymist_bg.wasm.gz", "wb", 9) as g:
            shutil.copyfileobj(f, g)
    print(f"editor: added tinymist from {src}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--watch", action="store_true")
    ap.add_argument("--search", action="store_true")
    ap.add_argument("--editor", action="store_true")
    ap.add_argument("--drafts", action="store_true", help="include drafts (private build)")
    ap.add_argument("--out", type=Path, help="output directory (default: dist/)")
    args = ap.parse_args()

    global DIST, DRAFTS
    DRAFTS = args.drafts
    if args.out:
        DIST = args.out.resolve()

    BUILD.mkdir(exist_ok=True)
    pages, hidden = page_entries()
    manifest = {"pages": pages, "hidden": hidden, "assets": asset_entries()}
    (BUILD / "manifest.json").write_text(json.dumps(manifest, indent=2))
    n_drafts = sum(p["draft"] for p in pages)
    print(f"manifest: {len(pages)} pages ({n_drafts} drafts included, {len(hidden)} left out), "
          f"{len(manifest['assets'])} assets")

    if DIST.exists():
        shutil.rmtree(DIST)
    cmd = ["typst", "watch" if args.watch else "compile",
           "--features", "html,bundle", "--format", "bundle", "--root", str(ROOT),
           "--input", f"drafts={'true' if DRAFTS else 'false'}",
           str(ROOT / "site.typ"), str(DIST)]
    subprocess.run(cmd, check=True)

    if not args.watch:
        sys.path.insert(0, str(ROOT / "scripts"))
        from mathml_fix import fix_tree
        print(f"mathml_fix: {fix_tree(DIST)} files changed")

    if args.editor and not args.watch:
        build_editor()

    if not args.watch:
        write_cors_headers()

    if DRAFTS and not args.watch:
        write_drafts_gate()

    if args.search and not args.watch:
        subprocess.run(["npx", "--yes", "pagefind@1", "--site", str(DIST)], check=True)


if __name__ == "__main__":
    main()
