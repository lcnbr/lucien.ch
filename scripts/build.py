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
"""
from __future__ import annotations

import argparse
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

EDITOR = ROOT / "editor"

# Versions of the in-browser compiler; typst-wasm 1.0.0 embeds Typst 0.15.
EDITOR_NPM = {"typst-wasm": "1.0.0", "@typst-wasm/fonts": "1.0.0", "nanotar": "0.2.1"}
EDITOR_FONTS = ["NewCM10-Regular.otf", "NewCM10-Italic.otf", "NewCM10-Bold.otf",
                "NewCM10-BoldItalic.otf", "NewCMMath-Regular.otf", "DejaVuSansMono.ttf"]

DATED = re.compile(r"^(\d{4}-\d{2}-\d{2})-(.+)$")
SLUG = re.compile(r"^[a-z0-9][a-z0-9-]*$")


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


def page_entries() -> list[dict]:
    today = date.today().isoformat()
    entries: list[dict] = []
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
            })
    return entries


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
        tar.extractall(target, filter="data")
    return target / "package"


def build_editor() -> None:
    """Copy editor/ to dist/edit/ and vendor the compiler, fonts and packages."""
    out = DIST / "edit"
    shutil.copytree(EDITOR, out, ignore=shutil.ignore_patterns("README.md", "codemirror-entry.js"))
    vendor = out / "vendor"
    # Cloudflare Pages header rules: cross-origin isolation lets the editor use
    # typst-wasm's worker backend (SharedArrayBuffer). Without it, it falls
    # back to JSPI, which only recent Chromium-based browsers have.
    (DIST / "_headers").write_text(
        "/edit/*\n"
        "  Cross-Origin-Opener-Policy: same-origin\n"
        "  Cross-Origin-Embedder-Policy: credentialless\n"
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
    args = ap.parse_args()

    BUILD.mkdir(exist_ok=True)
    manifest = {"pages": page_entries(), "assets": asset_entries()}
    (BUILD / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"manifest: {len(manifest['pages'])} pages, {len(manifest['assets'])} assets")

    if DIST.exists():
        shutil.rmtree(DIST)
    cmd = ["typst", "watch" if args.watch else "compile",
           "--features", "html,bundle", "--format", "bundle", "--root", str(ROOT),
           str(ROOT / "site.typ"), str(DIST)]
    subprocess.run(cmd, check=True)

    if not args.watch:
        sys.path.insert(0, str(ROOT / "scripts"))
        from mathml_fix import fix_tree
        print(f"mathml_fix: {fix_tree(DIST)} files changed")

    if args.editor and not args.watch:
        build_editor()

    if args.search and not args.watch:
        subprocess.run(["npx", "--yes", "pagefind@1", "--site", str(DIST)], check=True)


if __name__ == "__main__":
    main()
