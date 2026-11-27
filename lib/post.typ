// Template for blog posts: content/posts/YYYY-MM-DD-slug.typ
//
//   #import "/lib/post.typ": post
//   #show: post.with(
//     title: [Gauge fixing without tears],
//     summary: "One sentence for the index and the feed.",
//     tags: ("qft",),
//     draft: true,   // optional: only on the private drafts site
//   )
#import "base.typ": shell
#import "state.typ": current, check-draft, draft-banner
#import "util.typ": plain, parse-date, fmt-date
#import "links.typ": backlinks
#import "comments.typ": comments

#let post(title: none, summary: none, tags: (), draft: false, body) = context {
  check-draft(draft)
  let here = current.get()
  let date = if here != none { parse-date(here.date) } else { none }
  [#metadata((
    ..if here != none { here } else { (:) },
    kind: "post",
    title: title,
    title-text: plain(title),
    summary: summary,
    tags: tags,
    draft: draft,
  )) <page-meta>]
  let meta = {
    if date != none { html.time(datetime: date, fmt-date(date)) }
    for t in tags { [ ]; html.a(class: "tag", href: "/tags/" + t + "/", "#" + t) }
  }
  shell(title: plain(title), description: summary, heading: title, kind: "post", meta: meta, {
    draft-banner(draft)
    html.elem("article", attrs: ("data-pagefind-body": ""), body)
    if here != none { backlinks(here.slug) }
    comments(draft: draft)
  })
}
