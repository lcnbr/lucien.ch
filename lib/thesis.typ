// Theses: content/research/<thesis>/index.typ is the landing page
// (/research/<thesis>/, slug "<thesis>"), and each chapter is
// content/research/<thesis>/<stem>.typ (/research/<thesis>/<stem>/, slug
// "<thesis>-<stem>"). Each thesis is described once in `theses` below; the
// Research page (/research/) lists them in this order.
//
// To add one: a new entry here, a folder in content/research/, and figures
// in assets/research/<thesis>/figures/.
#import "page.typ": page
#import "links.typ": n
#import "acronyms.typ": acronyms
#import "state.typ": preview, current

#let theses = (
  "msc-thesis": (
    title: [Gravitational Waves from Feynman Diagrams],
    degree: "Master's thesis",
    school: "ETH Zürich",
    date: "October 2022",
    advisor: "Prof. Babis Anastasiou",
    summary: "Scattering amplitudes in gravitational wave physics: from Feynman diagrams to the classical two-body problem.",
    pdf: "/assets/research/msc-thesis/gravitational-waves-from-feynman-diagrams.pdf",
    bib: "/data/thesis-references.bib",
    chapters: (
      (number: 1, slug: "msc-thesis-introduction", title: "Introduction"),
      (number: 2, slug: "msc-thesis-gw-generation", title: "Gravitational Wave Generation"),
      (number: 3, slug: "msc-thesis-gw-detection", title: "Gravitational Wave Detection"),
      (number: 4, slug: "msc-thesis-waveform-generation", title: "Waveform Generation"),
      (number: 5, slug: "msc-thesis-scattering-amplitudes", title: "Scattering Amplitudes and GWs"),
      (number: 6, slug: "msc-thesis-conclusion", title: "Conclusion"),
    ),
  ),
)

// The thesis the current page belongs to: the one its `chapter` call names,
// else the one in its URL (/research/<thesis>/…). The editor preview compiles
// a chapter on its own, without a URL, so the chapter's word counts.
#let thesis-key = state("thesis", none)
#let here-thesis() = {
  let key = thesis-key.get()
  if key != none { return key }
  let e = current.get()
  if type(e) == dictionary and "url" in e { e.url.split("/").at(2, default: none) } else { none }
}

// Acronym: form "short" (an <abbr> with the long form as tooltip), "long", or
// "full" ("Long Form (SHORT)", used on first use in a chapter).
#let acr(key, form: "short", plural: false) = context {
  let a = acronyms.at(key)
  let s = if plural { a.short + "s" } else { a.short }
  let l = if plural { a.long + "s" } else { a.long }
  let abbr = if target() == "html" { html.elem("abbr", attrs: (title: l), s) } else { s }
  if form == "long" { l } else if form == "full" [#l (#abbr)] else { abbr }
}

// Thesis figure image, served from assets/research/<thesis>/figures/.
#let timg(name, alt: "", thesis: auto) = context {
  let key = if thesis == auto { here-thesis() } else { thesis }
  if key == none { panic("timg: not on a thesis page; pass thesis: \"<thesis>\"") }
  let src = "/assets/research/" + key + "/figures/" + name
  if target() == "html" {
    html.img(class: "plate", src: src, alt: alt, loading: "lazy")
  } else { image(src) }
}

// Several images laid out in a grid, as one figure.
#let subfigs(columns: 4, ..items) = context {
  if target() == "html" {
    html.div(class: "subfigs", style: "--cols: " + str(columns), items.pos().join())
  } else { grid(columns: columns, gutter: 0.75em, ..items.pos()) }
}

// Link to a label on another thesis page (a plain "#" link in the editor preview,
// where other pages are not compiled).
#let xref(target, body) = if preview { link("#", body) } else { link(target, body) }

#let chapter-nav(chapters, number) = {
  let i = chapters.position(c => c.number == number)
  let prev = if i > 0 { chapters.at(i - 1) }
  let next = if i + 1 < chapters.len() { chapters.at(i + 1) }
  html.nav(class: "pager", aria-label: "Chapters", {
    html.span(class: "prev", if prev != none { xref(label(prev.slug))[#html.small[Previous] #prev.number. #prev.title] })
    html.span(class: "next", if next != none { xref(label(next.slug))[#html.small[Next] #next.number. #next.title] })
  })
}

// One chapter page. Sections are numbered "<chapter>.<n>", and only labelled
// display equations get a number, as in the PDF.
#let chapter(thesis: none, number: none, summary: none, body) = {
  let key = thesis
  let thesis = theses.at(key)
  let ch = thesis.chapters.find(c => c.number == number)
  page(title: [#number. #ch.title], summary: summary,
    meta: [Chapter #number of #thesis.chapters.len() · #thesis.degree, #thesis.school, #thesis.date · #link(thesis.pdf)[PDF]],
  {
    thesis-key.update(key)
    counter(heading).update(0)
    set heading(numbering: (..n) => str(number) + "." + n.pos().map(str).join("."))
    set math.equation(numbering: k => "(" + str(number) + "." + str(k) + ")", supplement: [Eq.])
    set figure(numbering: k => str(number) + "." + str(k))
    show math.equation.where(block: true): it => {
      if it.numbering == none or it.has("label") { it } else {
        counter(math.equation).update(k => k - 1)
        math.equation(it.body, block: true, numbering: none)
      }
    }
    body
    bibliography(thesis.bib, title: [References], style: "american-physics-society")
    chapter-nav(thesis.chapters, number)
    thesis-key.update(none)
  })
}

// The theses as a list, for the Research page.
#let thesis-list() = html.ul(class: "list", theses.pairs().map(((key, t)) => html.li({
  html.span(class: "list-meta", t.date.split(" ").last())
  [ ]
  if preview { link("#", t.title) } else { link(label(key), t.title) }
  html.p(class: "summary", [#t.degree, #t.school. #t.summary])
})).join())
