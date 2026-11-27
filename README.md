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
- **Drafts:** add `draft: true` to the template call (`post.with`, `note.with`
  or `page.with`). See [Drafts](#drafts).
- **Footnotes:** `#footnote[...]` becomes a Tufte-style sidenote in the right
  margin on wide screens, and a tap-to-unfold note on phones. Keep them inline
  (no display math or paragraphs inside).
- **Data for plots:** put CSV/JSON in `data/` and read it with `csv("/data/...")`.

## CV

`/cv/` shows the CV in English and French with a switch (`/cv/#fr` opens
the French one). The text of both languages lives in `lib/cv.typ`; the page
is `content/pages/cv.typ`, and `scripts/build.py` also compiles
`cv/cv-pdf.typ` into `/cv/lucien-huber-cv-en.pdf` and `-fr.pdf`. Which
personal details are shown is set by `public` at the top of `lib/cv.typ`.

## How it fits together

- `site.typ` — bundle entry point: one `document()` per content file, plus the
  home, blog, garden and tag pages, `feed.xml` and `garden/graph.json`.
- `lib/` — templates (`base`, `post`, `note`, `page`, `indexes`) and helpers.
  Every page goes through `shell` in `lib/base.typ`: one header, one page head
  (trail of links, heading, meta line) and one footer. The header has three
  sections (Blog, Garden, About); CV, Thesis and Blogroll live under About.
  Both lists are in `lib/config.typ` (`nav`, `more`), so a new page is added
  there, not in the header code.
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

## Blogroll

`/blogroll/` lists the newest posts of the blogs in [`blogroll.txt`](blogroll.txt),
newest first (idea from [matklad](https://matklad.github.io/links.html)). Add one
RSS or Atom feed URL per line; anything after the URL is a comment.

`scripts/blogroll.py` fetches the feeds at build time (three newest posts per
blog) into `build/blogroll.json`, which `site.typ` reads. A feed that fails is
skipped with a warning, never fatal. CI rebuilds main every day at 05:17 UTC so
the page stays fresh. `python3 scripts/build.py --offline` skips the fetch and
reuses the last one.

## Drafts

A post, note or page with `draft: true` in its `#show: ….with(...)` call is
left out of the public build completely: no page at its URL, not in the blog,
garden, tag or home lists, not in search, the graph, backlinks or `feed.xml`,
and not in the editor's built-in snapshot. A public page that links to it with
`#n(<slug>)` keeps the words but loses the link.

CI also builds a second, private site with drafts included (marked with a
"draft" badge) and deploys it to its own Cloudflare Pages project,
`lucien-ch-drafts` (https://lucien-ch-drafts.pages.dev, PR previews at
`<branch>.lucien-ch-drafts.pages.dev`). You sign in with GitHub through
Cloudflare Access, and only the accounts the Access policy allows get in.
The site's worker also checks Access's signed token on every request, so if
Access is off or misconfigured the drafts site refuses everyone instead of
opening up.

One-time setup (free Cloudflare Zero Trust plan):

1. In the [Zero Trust dashboard](https://one.dash.cloudflare.com/), pick a
   team name (gives `<team>.cloudflareaccess.com`) and the Free plan.
2. [Create a GitHub OAuth app](https://github.com/settings/applications/new):
   homepage `https://<team>.cloudflareaccess.com`, callback
   `https://<team>.cloudflareaccess.com/cdn-cgi/access/callback`. In Zero
   Trust → Settings → Authentication → Login methods, add GitHub with its
   client ID and secret.
3. Zero Trust → Access → Applications → Add → Self-hosted. Hostnames
   `lucien-ch-drafts.pages.dev` and `*.lucien-ch-drafts.pages.dev`, login
   method GitHub only. Policy: Allow, include Emails → your GitHub email.
4. The team name (`lcnbr`) and the application's audience (AUD) tag are set
   in the workflow; the `DRAFTS_ACCESS_TEAM` / `DRAFTS_ACCESS_AUD`
   [Actions variables](https://github.com/lcnbr/lucien.ch/settings/variables/actions)
   override them. The AUD tag is the `kid=` value in the Access login URL.

`scripts/build.py` finds drafts by reading the template call before compiling;
the templates check again during the compile and stop the public build if a
draft got through, so a miss fails the build instead of publishing.

Locally: `python3 scripts/build.py --drafts` builds the drafts site into
`dist/` (add `--out dist-drafts` to keep both).

The source files themselves are as visible as the repository: while it is
public, anyone can read a draft's `.typ` file on GitHub.

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
cross-origin-isolation headers that let the compiler run in a worker. On
Cloudflare, `/edit/` always gets them (`dist/_headers`); other pages get them
only while the editor is docked (an `edit=1` cookie read by
`functions/_middleware.js`), because isolation would also block the giscus
comments for readers; without them it needs
a browser with JSPI (recent Chrome/Edge). The editor's status line names each
startup step, and the browser console logs `[edit]` timings for each.
