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
| Thesis chapter | `content/thesis/slug.typ` (landing: `index.typ`) | `/thesis/slug/` |

```typst
#import "/lib/post.typ": post        // or note.typ / page.typ
#import "/lib/links.typ": n
#import "/lib/figures.typ": diagram-frame, svg-math

#show: post.with(title: [My post], summary: "One line for lists and RSS.", tags: ("qft",))

Inline $a^2 + b^2 = c^2$, display math, and a link to #n(<berry-phase>)[a note].
```

- **Links between pages:** `#n(<slug>)[text]`. Don't follow it with `;` (Typst
  reads it as the end of the call and drops it). Checked at compile time, and the
  target page lists the source under "Linked from".
- **Notes:** `#show: note.with(title: [...], status: "seedling" | "budding" | "evergreen")`.
  Planted and tended dates come from git.
- **Diagrams and plots:** wrap fletcher, cetz, quill or lilaq output in
  `#diagram-frame(...)`; it becomes inline SVG in HTML and stays native in PDF.
- **Numbered equations:** `#set math.equation(numbering: "(1)")`, label with
  `<eq-name>`, refer with `@eq-name`. Numbers restart on every page.
- **Awkward equation:** `#svg-math[$ ... $]` renders one equation as SVG.
- **Footnotes:** `#footnote[...]` becomes a Tufte-style sidenote in the right
  margin on wide screens, and a tap-to-unfold note on phones. Keep them inline
  (no display math or paragraphs inside).
- **Data for plots:** put CSV/JSON in `data/` and read it with `csv("/data/...")`.

## How it fits together

- `site.typ` — bundle entry point: one `document()` per content file, plus the
  home, blog, garden and tag pages, `feed.xml` and `garden/graph.json`.
- `lib/` — templates (`base`, `post`, `note`, `page`, `indexes`) and helpers.
- `assets/` — CSS, fonts, `graph.js` (the notes graph) and `hover.js` (hover
  previews of linked pages, equations and figures, plus "+" toggles that unfold a
  garden note inline). Both have no dependencies.
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

## Editing in the browser

`/edit/` is a small editor that compiles with Typst in WebAssembly
(typst-wasm, Typst 0.15.0) and shows the page as it will look on the site.

- Open `https://<site>/edit/`, pick a file (or **New…**), and type. The
  preview recompiles about 250 ms after you stop; errors are listed under the
  editor and clicking one jumps to it. Unsaved text is kept in the browser.
- **Save** commits the file to GitHub, which rebuilds and deploys the site.
  It needs a fine-grained token (⚙): GitHub → Settings → Developer settings →
  Fine-grained tokens, repository `lcnbr/lucien.ch` only, permission
  *Contents: read and write*. The token stays in this browser's localStorage.
- Packages the site uses are mirrored into `/edit/vendor/packages/` at build
  time; others are fetched from packages.typst.org.
- In the preview, garden links point to `#` and backlinks/indexes are not
  built (only the open file is compiled).

Locally: `python3 scripts/build.py --editor && python3 scripts/serve.py`
(with Nix, `nix develop` first gives Typst, Python and Node),
then open http://localhost:8000/edit/. `serve.py` sends the
cross-origin-isolation headers (also set for the whole site on Cloudflare in
`dist/_headers`) that let the compiler run in a worker; without them it needs
a browser with JSPI (recent Chrome/Edge). The editor's status line names each
startup step, and the browser console logs `[edit]` timings for each.
