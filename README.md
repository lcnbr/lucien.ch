# lucien.ch

Blog, digital garden and (soon) photo albums, written in [Typst](https://typst.app)
and built into a static site with Typst's HTML bundle export.

## Build

Requires Typst (version in [`typst-version`](typst-version)) and Python 3.

```sh
python3 scripts/build.py            # build into dist/
python3 scripts/build.py --watch    # live-reloading preview on http://127.0.0.1:3000
python3 scripts/build.py --search   # also build the Pagefind search index (needs npx)
```

`scripts/build.py` writes `build/manifest.json` (every content file with its
slug, output path and git dates), runs
`typst compile --features html,bundle --format bundle site.typ dist`, then
applies a small MathML fix-up (see below).

## Writing

| Kind | File | URL |
| --- | --- | --- |
| Blog post | `content/posts/YYYY-MM-DD-slug.typ` | `/blog/slug/` |
| Garden note | `content/garden/slug.typ` | `/garden/slug/` |
| Page | `content/pages/slug.typ` | `/slug/` |

```typst
#import "/lib/post.typ": post        // or note.typ / page.typ
#import "/lib/links.typ": n
#import "/lib/figures.typ": diagram-frame, svg-math

#show: post.with(title: [My post], summary: "One line for lists and RSS.", tags: ("qft",))

Inline $a^2 + b^2 = c^2$, display math, and a link to #n(<berry-phase>)[a note].
```

- **Links between pages:** `#n(<slug>)[text]`. Checked at compile time, and the
  target page lists the source under "Linked from".
- **Notes:** `#show: note.with(title: [...], status: "seedling" | "budding" | "evergreen")`.
  Planted and tended dates come from git.
- **Diagrams and plots:** wrap fletcher, cetz, quill or lilaq output in
  `#diagram-frame(...)`; it becomes inline SVG in HTML and stays native in PDF.
- **Awkward equation:** `#svg-math[$ ... $]` renders one equation as SVG.
- **Data for plots:** put CSV/JSON in `data/` and read it with `csv("/data/...")`.

## How it fits together

- `site.typ` — bundle entry point: one `document()` per content file, plus the
  home, blog, garden, tag and search pages, `feed.xml` and `garden/graph.json`.
- `lib/` — templates (`base`, `post`, `note`, `page`, `indexes`) and helpers.
- `assets/` — CSS, fonts, `graph.js` (the notes graph, no dependencies).
- `scripts/mathml_fix.py` — Chromium sizes stretchy delimiters by their widest
  variant, which makes `f(x)` look like `f ( x )` with New Computer Modern Math.
  The fix marks fences around short content as `stretchy="false"`.
- `.github/workflows/build.yml` — builds on every push and PR, uploads the site
  as an artifact, and deploys to Cloudflare Pages once the
  `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` secrets are set.

Typst's HTML and bundle export are experimental, so the Typst version is pinned.

## Fonts

`assets/fonts/` holds New Computer Modern (text subset to Latin and Greek) and
New Computer Modern Math, converted to WOFF2 from the copies shipped with Typst.
They are distributed under the GUST Font License.
