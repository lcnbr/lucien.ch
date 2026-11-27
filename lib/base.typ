// The HTML shell shared by every page: <head>, site header, footer.
#import "config.typ": site
#import "state.typ": current

#let nav-bar() = html.header(class: "site-header", {
  html.a(class: "site-title", href: "/", site.title)
  html.nav({
    html.a(href: "/blog/", "Blog")
    html.a(href: "/garden/", "Garden")
    html.a(href: "/cv/", "CV")
    html.a(href: "/blogroll/", "Blogroll")
    html.a(href: "/about/", "About")
    // Opens the search overlay (assets/search.js); also Ctrl/⌘ K or "/".
    html.button(class: "search-open", type: "button", aria-label: "Search", {
      html.span("Search")
      html.elem("kbd", attrs: (class: "search-key"), "⌘K")
    })
  })
})

// `title` is plain text for <title>; `heading` is the visible page heading
// (content, so it may contain math). `kind` becomes a body class.
#let shell(title: none, description: none, heading: none, kind: "page", body) = {
  set text(lang: site.lang)
  // HTML export drops equation numbers; put them back beside numbered equations.
  show math.equation.where(block: true): it => {
    if target() == "html" and it.numbering != none {
      html.div(class: "equation", {
        it
        html.span(class: "eq-num", context counter(math.equation).display(it.numbering))
      })
    } else { it }
  }
  // Footnotes become Tufte-style sidenotes (styled in assets/style.css): a
  // margin note on wide screens, a tap-to-unfold note on narrow ones. The
  // label/checkbox pair needs no JavaScript. Typst still emits its endnote
  // list; the entries are dropped and the empty list is hidden by CSS.
  show footnote.entry: it => if target() == "html" { none } else { it }
  show footnote: it => {
    if target() != "html" { return it }
    let num = counter(footnote).display(it.numbering)
    let id = "sn-" + str(counter(footnote).get().first())
    html.elem("label", attrs: ("for": id, class: "sidenote-number", aria-label: "Note " + num), html.sup(num))
    html.input(type: "checkbox", id: id, class: "sidenote-toggle")
    html.span(class: "sidenote", role: "note", { html.sup(class: "sidenote-mark", num); [ ]; it.body })
  }
  html.html(lang: site.lang, {
    html.head({
      html.meta(charset: "utf-8")
      html.meta(name: "viewport", content: "width=device-width, initial-scale=1")
      html.title(if title == none or title == "" { site.title } else { title + " · " + site.title })
      if description != none { html.meta(name: "description", content: description) }
      html.elem("link", attrs: (rel: "preload", href: "/assets/fonts/NewCMMath-Regular.woff2", "as": "font", type: "font/woff2", crossorigin: ""))
      html.link(rel: "stylesheet", href: "/assets/style.css")
      html.link(rel: "alternate", type: "application/rss+xml", title: site.title, href: "/feed.xml")
      if kind in ("note", "index") { html.script(src: "/assets/graph.js", defer: true, "") }
      html.script(src: "/assets/hover.js", defer: true, "")
      html.script(src: "/assets/search.js", defer: true, "")
      if kind in ("post", "note", "page") { html.script(src: "/assets/edit.js", defer: true, "") }
    })
    html.body(class: kind, {
      nav-bar()
      html.main({
        if heading != none { html.h1(heading) }
        body
      })
      html.footer(class: "site-footer", {
        [© #site.author · ]
        html.a(href: "/feed.xml", "RSS")
        // Link each content page to its source in the browser editor.
        if kind in ("post", "note", "page") {
          context {
            let e = current.get()
            if type(e) == dictionary and "path" in e {
              [ · ]
              html.a(class: "edit-link", href: "/edit/#" + e.path.trim("/", at: start), "Edit")
            }
          }
        }
      })
    })
  })
}
