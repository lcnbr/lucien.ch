// The manifest entry of the page currently being emitted. site.typ updates it
// right before including a content file, so templates and link helpers know
// which page they are on (slug, url, git dates).
#let current = state("current-page", none)

// True when compiling a single page in the browser editor preview. Cross-page
// labels do not exist there, so link helpers degrade to plain URLs.
#let preview = sys.inputs.at("preview", default: "false") == "true"

// True for the private drafts build (scripts/build.py --drafts). The public
// build leaves drafts out entirely; see `check-draft`.
#let drafts = sys.inputs.at("drafts", default: "false") == "true"

// Called by every template with its `draft:` argument. build.py decides which
// files are drafts before compiling; if a draft still reaches the public
// build, stop it here rather than publish it.
#let check-draft(draft) = {
  if draft and not drafts and not preview {
    panic("a page marked draft: true reached the public build; scripts/build.py did not detect it")
  }
}

// Banner on a draft page in the drafts build and the editor preview.
#let draft-banner(draft) = if draft {
  html.p(class: "draft-banner", [Draft · only visible on the private drafts site])
}
