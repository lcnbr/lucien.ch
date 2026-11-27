// The HTML shell shared by every page: <head>, site header, footer.
#import "config.typ": site
#import "state.typ": current

// Which header section a path belongs to, and the trail of links above the
// page heading ("About › Thesis" on a thesis chapter). Sections and the pages
// under them are set in config.typ (`nav`, `more`).
#let section-of(path) = if path == none { none } else {
  site.nav.find(n => path.starts-with(n.href) or n.also.any(a => path.starts-with(a)))
}
#let crumbs(path) = {
  let n = section-of(path)
  if n == none { return () }
  let out = if path != n.href { ((label: n.label, href: n.href),) } else { () }
  // Pages between the section and this one, e.g. a thesis above its chapters.
  let parts = path.trim("/").split("/")
  let metas = query(<page-meta>).map(m => m.value)
  for i in range(1, parts.len()) {
    let url = "/" + parts.slice(0, i).join("/") + "/"
    if url == n.href { continue }
    let m = metas.find(m => m.at("url", default: none) == url)
    if m != none { out.push((label: m.title-text, href: url)) }
  }
  out
}

#let nav-bar(path) = html.header(class: "site-header", {
  html.a(class: "site-title", href: "/", site.title)
  html.nav(aria-label: "Site", {
    let here = section-of(path)
    for n in site.nav {
      if here != none and here.href == n.href {
        html.a(href: n.href, aria-current: if path == n.href { "page" } else { true }, n.label)
      } else { html.a(href: n.href, n.label) }
    }
    // Opens the search overlay (assets/search.js); also Ctrl/⌘ K or "/".
    html.button(class: "search-open", type: "button", aria-label: "Search", {
      html.elem("svg", attrs: (viewBox: "0 0 24 24", "aria-hidden": "true"), html.elem("path", attrs: (d: "M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Zm5.3-2.2L21 21")))
      html.span(class: "search-label", "Search")
      html.elem("kbd", attrs: (class: "search-key"), "⌘K")
    })
  })
})

// `title` is plain text for <title>; `heading` is the visible page heading
// (content, so it may contain math). `kind` becomes a body class.
//
// Every page has the same head: an optional trail of links (`crumbs`, from
// the path), the heading, and an optional `meta` line (date, status, tags…).
// `path` is the page's URL; content pages take it from the manifest.
#let shell(title: none, description: none, heading: none, kind: "page", path: none, meta: none, body) = {
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
    html.body(class: kind, context {
      let path = if path != none { path } else {
        let e = current.get()
        if type(e) == dictionary and "url" in e { e.url } else { none }
      }
      nav-bar(path)
      html.main({
        if heading != none {
          html.header(class: "page-head", {
            let cs = crumbs(path)
            if cs.len() > 0 {
              html.nav(class: "crumbs", aria-label: "Breadcrumb", cs.map(c => html.a(href: c.href, c.label)).join(html.span(class: "sep", aria-hidden: true, "/")))
            }
            html.h1(heading)
            if meta != none { html.p(class: "meta", meta) }
          })
        }
        body
      })
      html.footer(class: "site-footer", {
        html.span[© #site.author]
        html.nav(aria-label: "More", {
          for m in site.more { html.a(href: m.href, m.label) }
          html.a(href: "/feed.xml", "RSS")
          // Link each content page to its source in the browser editor.
          if kind in ("post", "note", "page") {
            let e = current.get()
            if type(e) == dictionary and "path" in e {
              html.a(class: "edit-link", href: "/edit/#" + e.path.trim("/", at: start), "Edit")
            }
          }
        })
      })
    })
  })
}
