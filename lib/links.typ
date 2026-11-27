// Garden links and backlinks.
//
// Write `#n(<berry-phase>)[Berry phase]` to link to another page by its slug,
// or `#n(<eq-berry>)[...]` to link to an equation, figure or section on one.
// The link is checked at compile time (a typo is an error), and it records an
// edge so the target page can list this page under "Linked from".
#import "state.typ": current, preview

#let n(target, body) = {
  if preview {
    // Single-page preview: other pages are not part of the compile.
    link("#", body)
  } else if str(target) in json("/build/manifest.json").at("hidden", default: ()) {
    // A draft (or a label on one) left out of this (public) build: keep the words, drop the link
    // and the edge, so nothing points at it.
    html.span(class: "draft-link", body)
  } else {
    // The edge metadata sits inside the link body: placed after the link it
    // would make HTML export insert a stray space before punctuation.
    let to-page = json("/build/manifest.json").pages.any(p => p.slug == str(target))
    link(target, body + context {
      let here = current.get()
      if here != none and to-page [#metadata((from: here.slug, to: str(target))) <edge>]
    })
  }
}

// All edges as (from, to) pairs, deduplicated. Needs context.
#let all-edges() = query(<edge>).map(e => e.value).dedup()

// Pages that link to `slug`, as page-meta values. Needs context.
#let backlinks-of(slug) = {
  let sources = all-edges().filter(e => e.to == slug and e.from != slug).map(e => e.from).dedup()
  let metas = query(<page-meta>).map(m => m.value)
  sources.map(s => metas.find(m => m.slug == s)).filter(m => m != none)
}

#let backlinks(slug) = if not preview {
  context {
    let bl = backlinks-of(slug)
    if bl.len() > 0 {
      html.aside(class: "backlinks", {
        html.h2("Linked from")
        html.ul(bl.map(m => html.li(link(label(m.slug), m.title))).join())
      })
    }
  }
}
