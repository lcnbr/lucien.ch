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
    python3 scripts/build.py --drafts   # private build: include drafts, behind a password

Drafts (`draft: true` in a file's template call) are left out of the normal
build entirely: no page, no listing, no search entry, no graph node, no feed
item, and links to them from public pages render as plain text. The --drafts
build includes them and writes a `_worker.js` that asks for a password
(SHA-256 of $DRAFTS_PASSWORD, baked in at build time). Without
$DRAFTS_PASSWORD the worker refuses every request.
"""
from __future__ import annotations

import argparse
import base64
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
EDITOR_FONTS = ["NewCM10-Regular.otf", "NewCM10-Italic.otf", "NewCM10-Bold.otf",
                "NewCM10-BoldItalic.otf", "NewCMMath-Regular.otf", "DejaVuSansMono.ttf"]

DATED = re.compile(r"^(\d{4}-\d{2}-\d{2})-(.+)$")
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
            if not SLUG.match(slug):
                sys.exit(f"error: {path}: slug '{slug}' must be lowercase letters, digits and dashes")
            if slug in seen:
                sys.exit(f"error: slug '{slug}' used by both {seen[slug]} and {path}")
            seen[slug] = path
            draft = is_draft(path)
            if draft and not DRAFTS:
                hidden.append(slug)
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


# Cloudflare Pages advanced-mode worker for the drafts build: HTTP Basic auth
# in front of every file (any user name, the password from $DRAFTS_PASSWORD).
# Pages never serves _worker.js itself, so the hash is not public. With no
# password configured it refuses everything.
DRAFTS_WORKER = """// Generated by scripts/build.py --drafts. Password gate for the drafts site.
const HASH = %s;
const ISOLATION = {
  "Cross-Origin-Opener-Policy": "same-origin",
  "Cross-Origin-Embedder-Policy": "require-corp",
  "X-Robots-Tag": "noindex, nofollow",
  "Cache-Control": "private, no-store",
};
async function sha256(s) {
  const d = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(d)].map(b => b.toString(16).padStart(2, "0")).join("");
}
function same(a, b) {
  if (a.length !== b.length) return false;
  let x = 0;
  for (let i = 0; i < a.length; i++) x |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return x === 0;
}
async function allowed(request) {
  if (!HASH) return false;
  const h = request.headers.get("Authorization") || "";
  if (!h.startsWith("Basic ")) return false;
  let decoded;
  try { decoded = atob(h.slice(6)); } catch { return false; }
  const pw = decoded.slice(decoded.indexOf(":") + 1);
  return same(await sha256(pw), HASH);
}
export default {
  async fetch(request, env) {
    if (!(await allowed(request))) {
      return new Response(HASH ? "Drafts are private." : "Drafts are not set up yet (no DRAFTS_PASSWORD).", {
        status: 401,
        headers: { "WWW-Authenticate": 'Basic realm="lucien.ch drafts", charset="UTF-8"', "Content-Type": "text/plain; charset=utf-8", ...ISOLATION },
      });
    }
    const r = await env.ASSETS.fetch(request);
    const out = new Response(r.body, r);
    for (const [k, v] of Object.entries(ISOLATION)) out.headers.set(k, v);
    return out;
  },
};
"""


def write_drafts_gate() -> None:
    import hashlib
    pw = os.environ.get("DRAFTS_PASSWORD", "")
    digest = hashlib.sha256(pw.encode()).hexdigest() if pw else ""
    (DIST / "_worker.js").write_text(DRAFTS_WORKER % json.dumps(digest))
    (DIST / "robots.txt").write_text("User-agent: *\nDisallow: /\n")
    print("drafts: password gate " + ("on" if pw else "LOCKED (no DRAFTS_PASSWORD set)"))


def build_editor() -> None:
    """Copy editor/ to dist/edit/ and vendor the compiler, fonts and packages."""
    out = DIST / "edit"
    shutil.copytree(EDITOR, out, ignore=shutil.ignore_patterns("README.md", "codemirror-entry.js"))
    vendor = out / "vendor"
    # Cloudflare Pages header rules: cross-origin isolation lets the editor use
    # typst-wasm's worker backend (SharedArrayBuffer). Without it, it falls
    # back to JSPI, which only recent Chromium-based browsers have. Set on the
    # whole site: the editor docks into every page and previews pages in an
    # iframe, and all of them must be isolated. require-corp (not
    # credentialless) because Safari supports only that; everything the site
    # loads is same-origin or CORS (GitHub API, package registry).
    (DIST / "_headers").write_text(
        "/*\n"
        "  Cross-Origin-Opener-Policy: same-origin\n"
        "  Cross-Origin-Embedder-Policy: require-corp\n"
    )
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
    print(f"editor: built dist/edit/ with {n} mirrored Typst packages")


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

    if DRAFTS and not args.watch:
        write_drafts_gate()

    if args.search and not args.watch:
        subprocess.run(["npx", "--yes", "pagefind@1", "--site", str(DIST)], check=True)


if __name__ == "__main__":
    main()
