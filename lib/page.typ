// Template for standalone pages such as About: content/pages/slug.typ
#import "base.typ": shell
#import "state.typ": current
#import "util.typ": plain

#let page(title: none, summary: none, body) = context {
  let here = current.get()
  [#metadata((
    ..if here != none { here } else { (:) },
    kind: "page",
    title: title,
    title-text: plain(title),
    summary: summary,
    tags: (),
  )) <page-meta>]
  shell(title: plain(title), description: summary, heading: title, kind: "page", html.elem("article", attrs: ("data-pagefind-body": ""), body))
}
