// The manifest entry of the page currently being emitted. site.typ updates it
// right before including a content file, so templates and link helpers know
// which page they are on (slug, url, git dates).
#let current = state("current-page", none)

// True when compiling a single page in the browser editor preview. Cross-page
// labels do not exist there, so link helpers degrade to plain URLs.
#let preview = sys.inputs.at("preview", default: "false") == "true"
