// Template and helpers for the master's thesis: content/thesis/*.typ
//
// The landing page is content/thesis/index.typ (/thesis/); each chapter is
// content/thesis/<stem>.typ (/thesis/<stem>/), with slug "thesis-<stem>".
#import "page.typ": page
#import "links.typ": n
#import "acronyms.typ": acronyms
#import "state.typ": preview

#let thesis = (
  title: [Gravitational Waves from Feynman Diagrams],
  author: "Lucien Huber",
  date: "October 2022",
  school: "ETH Zürich",
  advisor: "Prof. Babis Anastasiou",
  pdf: "/assets/thesis/gravitational-waves-from-feynman-diagrams.pdf",
  bib: "/data/thesis-references.bib",
)

#let chapters = (
  (number: 1, slug: "thesis-introduction", title: "Introduction"),
  (number: 2, slug: "thesis-gw-generation", title: "Gravitational Wave Generation"),
  (number: 3, slug: "thesis-gw-detection", title: "Gravitational Wave Detection"),
  (number: 4, slug: "thesis-waveform-generation", title: "Waveform Generation"),
  (number: 5, slug: "thesis-scattering-amplitudes", title: "Scattering Amplitudes and GWs"),
  (number: 6, slug: "thesis-conclusion", title: "Conclusion"),
)

// Acronym: form "short" (an <abbr> with the long form as tooltip), "long", or
// "full" ("Long Form (SHORT)", used on first use in a chapter).
#let acr(key, form: "short", plural: false) = context {
  let a = acronyms.at(key)
  let s = if plural { a.short + "s" } else { a.short }
  let l = if plural { a.long + "s" } else { a.long }
  let abbr = if target() == "html" { html.elem("abbr", attrs: (title: l), s) } else { s }
  if form == "long" { l } else if form == "full" [#l (#abbr)] else { abbr }
}

// Thesis figure image, served from assets/thesis/figures/.
#let timg(name, alt: "") = context {
  let src = "/assets/thesis/figures/" + name
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

#let chapter-nav(number) = {
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
#let chapter(number: none, summary: none, body) = {
  let ch = chapters.find(c => c.number == number)
  page(title: [#number. #ch.title], summary: summary,
    meta: [Chapter #number of #xref(<thesis>)[my master's thesis] · #thesis.school, #thesis.date · #link(thesis.pdf)[PDF]],
  {
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
    chapter-nav(number)
  })
}
