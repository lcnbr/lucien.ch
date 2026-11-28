# lucien.ch

Blog, digital garden and (soon) photo albums, written in [Typst](https://typst.app)
and built into a static site with Typst's HTML bundle export.

## Build

Requires Typst (version in [`typst-version`](typst-version)) and Rust (cargo);
with Nix, `nix develop` gives both, and Node for search.

```sh
cargo site build            # build into dist/
cargo site build --watch    # live-reloading preview on http://127.0.0.1:3000
cargo site build --search   # also build the Pagefind search index (needs npx)
cargo site serve            # serve dist/ on http://127.0.0.1:8000
cargo site help             # every command and option
```

`cargo site serve --host 0.0.0.0` also lets other devices on the network (a
phone) reach it, and `--dir DIR` serves another build than `dist/`.

`cargo site` is the build tool in [`tools/site/`](tools/site) (an alias in
`.cargo/config.toml`; the first run compiles it). `cargo site build` writes
`build/manifest.json` (every content file with its slug, output path and git
dates), fetches the blogroll, runs
`typst compile --features html,bundle --format bundle site.typ dist`, then
applies a small MathML fix-up (see below).

## Writing

| Kind | File | URL |
| --- | --- | --- |
| Blog post | `content/posts/YYYY-MM-DD-slug.typ` | `/blog/slug/` |
| Garden note | `content/garden/slug.typ` | `/garden/slug/` |
| Page | `content/pages/slug.typ` | `/slug/` |
| Thesis chapter | `content/research/<thesis>/slug.typ` (landing: `index.typ`; see `lib/thesis.typ`) | `/research/<thesis>/slug/` |

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
is `content/pages/cv.typ`, and `cargo site build` also compiles
`cv/cv-pdf.typ` into `/cv/lucien-huber-cv-en.pdf` and `-fr.pdf`. Phone,
address and birthday are not in the repository, which is public: pass them
as `--input`s to put them in a PDF you build yourself (see the top of
`lib/cv.typ`). The site only shows the name, email and photo.

## How it fits together

- `site.typ` — bundle entry point: one `document()` per content file, plus the
  home, blog, garden and tag pages, `feed.xml` and `garden/graph.json`.
- `lib/` — templates (`base`, `post`, `note`, `page`, `indexes`) and helpers.
  Every page goes through `shell` in `lib/base.typ`: one header, one page head
  (trail of links, heading, meta line) and one footer. The header has four
  sections (Blog, Garden, Research, About); theses live under Research, CV and
  Blogroll under About.
  Both lists are in `lib/config.typ` (`nav`, `more`), so a new page is added
  there, not in the header code.
- `assets/` — CSS, fonts, `graph.js` (the notes graph), `hover.js` (hover
  previews of linked pages, equations and figures, plus "+" toggles that unfold a
  garden note inline) and `mark.js` (the scroll mark: the logo from the CV runs
  round the edge of the window as the page scrolls, leaving a line behind it).
  None has dependencies.
- `tools/site/` — the build tool (Rust): manifest, blogroll, Typst, CV PDFs,
  MathML fix-up, the editor, the drafts gate and a local server.
- `tools/site/src/mathml.rs` — Chromium sizes stretchy delimiters by their widest
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

The build fetches the feeds (three newest posts per blog) into
`build/blogroll.json`, which `site.typ` reads. A feed that fails is skipped with
a warning, never fatal, and links that aren't `http(s)` are dropped. CI rebuilds
main every day at 05:17 UTC so the page stays fresh. `cargo site build --offline`
skips the fetch and reuses the last one; `cargo site blogroll FEED.xml` shows
what a feed file would give.

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

The build finds drafts by reading the template call before compiling;
the templates check again during the compile and stop the public build if a
draft got through, so a miss fails the build instead of publishing.

Locally: `cargo site build --drafts` builds the drafts site into
`dist/` (add `--out dist-drafts` to keep both;
`cargo site serve --dir dist-drafts` serves it).

The source files themselves are as visible as the repository: while it is
public, anyone can read a draft's `.typ` file on GitHub.

## Fonts

The site uses two faces and one math font:

- **Literata** for reading text, made for long reading on screens.
- **STIX Two Math** for equations.
- **Atkinson Hyperlegible** for headings, navigation and small print, as in
  the CV PDF.

`assets/fonts/` holds them as WOFF2 for the browser. Literata is subset to
Latin and Greek. `fonts/` holds Literata and STIX Two Math as TTF/OTF for
Typst, which draws diagrams, plots and `#svg-math` as SVG with the same fonts
(see `shell` in `lib/base.typ`). The build passes it with `--font-path`, and
the editor loads it too. Literata 3.103 and STIX Two 2.13 come from nixpkgs,
Atkinson Hyperlegible from `cv/fonts/`. All three are under the SIL Open Font
License 1.1.

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

Locally: `cargo site build --editor && cargo site serve`
(with Nix, `nix develop` first gives Typst, Rust and Node),
then open http://127.0.0.1:8000/edit/. `cargo site serve` sends the
cross-origin-isolation headers that let the compiler run in a worker. On
Cloudflare, `/edit/` always gets them (`dist/_headers`); other pages get them
only while the editor is docked (an `edit=1` cookie read by
`functions/_middleware.js`), because isolation would also block the giscus
comments for readers; without them it needs
a browser with JSPI (recent Chrome/Edge). The editor's status line names each
startup step, and the browser console logs `[edit]` timings for each.
