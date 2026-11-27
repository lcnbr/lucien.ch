#!/usr/bin/env python3
"""Build lucien.ch.

1. Walk content/ and assets/, read git dates, write build/manifest.json.
2. Run `typst compile --format bundle site.typ dist/`.
3. Optionally index dist/ with Pagefind (--search).

Usage:
    python3 scripts/build.py            # build into dist/
    python3 scripts/build.py --watch    # typst watch with live reload on :3000
    python3 scripts/build.py --search   # also run pagefind (needs npx)
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
ASSETS = ROOT / "assets"
BUILD = ROOT / "build"
DIST = ROOT / "dist"

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


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--watch", action="store_true")
    ap.add_argument("--search", action="store_true")
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

    if args.search and not args.watch:
        subprocess.run(["npx", "--yes", "pagefind@1", "--site", str(DIST)], check=True)


if __name__ == "__main__":
    main()
