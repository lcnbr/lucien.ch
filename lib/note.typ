// Template for garden notes: content/garden/slug.typ
//
//   #import "/lib/note.typ": note
//   #show: note.with(title: [Berry phase], status: "budding", tags: ("geometry",))
//
// status: "seedling" (rough), "budding" (taking shape), "evergreen" (stable).
// draft: true keeps the note off the public site (only on the drafts site).
#import "base.typ": shell
#import "state.typ": current, check-draft, draft-banner
#import "util.typ": plain, parse-date, fmt-date
#import "links.typ": backlinks
#import "comments.typ": comments

#let note(title: none, summary: none, status: "seedling", tags: (), draft: false, body) = context {
  check-draft(draft)
  let here = current.get()
  let planted = if here != none { parse-date(here.created) } else { none }
  let tended = if here != none { parse-date(here.updated) } else { none }
  [#metadata((
    ..if here != none { here } else { (:) },
    kind: "note",
    title: title,
    title-text: plain(title),
    summary: summary,
    status: status,
    tags: tags,
    draft: draft,
  )) <page-meta>]
  shell(title: plain(title), description: summary, heading: title, kind: "note", {
    draft-banner(draft)
    html.p(class: "meta", {
      html.span(class: "status " + status, status)
      if planted != none [ · planted #fmt-date(planted)]
      if tended != none and tended != planted [ · tended #fmt-date(tended)]
      for t in tags { [ ]; html.a(class: "tag", href: "/tags/" + t + "/", "#" + t) }
    })
    html.elem("article", attrs: ("data-pagefind-body": ""), body)
    if here != none {
      backlinks(here.slug)
      html.elem("div", attrs: (class: "local-graph", data-slug: here.slug))
    }
    comments()
  })
}
