// Template for standalone pages such as About: content/pages/slug.typ
#import "base.typ": shell
#import "state.typ": current, check-draft, draft-banner
#import "util.typ": plain

#let page(title: none, summary: none, draft: false, body) = context {
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
  shell(title: plain(title), description: summary, heading: title, kind: "page", {
    draft-banner(draft)
    html.elem("article", attrs: ("data-pagefind-body": ""), body)
  })
}
