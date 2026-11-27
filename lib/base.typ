// The HTML shell shared by every page: <head>, site header, footer.
#import "config.typ": site

#let nav-bar() = html.header(class: "site-header", {
  html.a(class: "site-title", href: "/", site.title)
  html.nav({
    html.a(href: "/blog/", "Blog")
    html.a(href: "/garden/", "Garden")
    html.a(href: "/about/", "About")
    html.a(href: "/search/", "Search")
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
    })
    html.body(class: kind, {
      nav-bar()
      html.main({
        if heading != none { html.h1(heading) }
        body
      })
      html.footer(class: "site-footer", {
        [© #datetime.today().year() #site.author · ]
        html.a(href: "/feed.xml", "RSS")
      })
    })
  })
}
