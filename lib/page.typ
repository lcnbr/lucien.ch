// Template for standalone pages such as About: content/pages/slug.typ
#import "base.typ": shell
#import "state.typ": current, check-draft, draft-banner
#import "util.typ": plain

// `heading` replaces the title as the visible heading (the CV shows the name);
// `actions` go beside the meta line (see `shell` in base.typ).
#let page(title: none, summary: none, heading: auto, meta: none, actions: none, draft: false, body) = context {
  check-draft(draft)
  let here = current.get()
  [#metadata((
    ..if here != none { here } else { (:) },
    kind: "page",
    title: title,
    title-text: plain(title),
    summary: summary,
    tags: (),
    draft: draft,
  )) <page-meta>]
  shell(title: plain(title), description: summary, heading: if heading == auto { title } else { heading }, kind: "page", meta: meta, actions: actions, {
    draft-banner(draft)
    html.elem("article", attrs: ("data-pagefind-body": ""), body)
  })
}

// The pages under About (config.typ `more`), as a list for the About page.
#let site-pages() = {
  import "config.typ": site
  html.ul(class: "list", site.more.map(m => html.li({
    html.a(href: m.href, m.label)
    html.p(class: "summary", m.summary)
  })).join())
}
