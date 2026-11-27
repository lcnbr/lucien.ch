// Generated pages: home, blog index, garden index, tag pages, RSS, graph data.
#import "base.typ": shell
#import "config.typ": site
#import "util.typ": parse-date, fmt-date, iso-date
#import "links.typ": all-edges

// All page metadata, needs context.
#let metas() = query(<page-meta>).map(m => m.value)
#let posts() = metas().filter(m => m.kind == "post" and not m.draft).sorted(key: m => m.date).rev()
#let notes() = metas().filter(m => m.kind == "note").sorted(key: m => m.at("updated", default: "")).rev()

#let post-item(m) = html.li({
  html.time(datetime: parse-date(m.date), fmt-date(parse-date(m.date)))
  [ ]
  link(label(m.slug), m.title)
  if m.summary != none { html.p(class: "summary", m.summary) }
})

#let note-item(m) = html.li({
  html.span(class: "status " + m.status, m.status)
  [ ]
  link(label(m.slug), m.title)
  if m.summary != none { html.p(class: "summary", m.summary) }
})

#let home() = context shell(kind: "home", {
  html.p(class: "lede", site.description)
  html.h2("Recent posts")
  html.ul(class: "list", posts().slice(0, calc.min(5, posts().len())).map(post-item).join())
  html.h2("Recently tended in the garden")
  html.ul(class: "list", notes().slice(0, calc.min(5, notes().len())).map(note-item).join())
})

#let blog-index() = context shell(title: "Blog", heading: [Blog], kind: "index", {
  html.ul(class: "list", posts().map(post-item).join())
})

#let garden-index() = context shell(title: "Garden", heading: [Garden], kind: "index", {
  html.p[Evergreen notes, linked to each other. Seedlings are rough, budding notes are taking shape, evergreen notes are stable.]
  html.elem("div", attrs: (class: "garden-graph"))
  html.ul(class: "list", notes().map(note-item).join())
})

#let all-tags() = metas().map(m => m.at("tags", default: ())).flatten().dedup().sorted()

#let tag-page(tag) = context shell(title: "#" + tag, heading: [Tagged #raw("#" + tag)], kind: "index", {
  let ms = metas().filter(m => tag in m.at("tags", default: ()))
  html.ul(class: "list", ms.map(m => if m.kind == "post" { post-item(m) } else if m.kind == "note" { note-item(m) } else { html.li(link(label(m.slug), m.title)) }).join())
})

// --- feeds and data ---------------------------------------------------------

#let xml-escape(s) = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")

#let rss() = {
  let items = posts().slice(0, calc.min(20, posts().len())).map(m => {
    let d = parse-date(m.date)
    let url = site.url + m.url
    "<item><title>" + xml-escape(m.title-text) + "</title><link>" + url + "</link><guid>" + url + "</guid>" + "<pubDate>" + d.display("[weekday repr:short], [day] [month repr:short] [year] 00:00:00 +0000") + "</pubDate>" + if m.summary != none { "<description>" + xml-escape(m.summary) + "</description>" } else { "" } + "</item>"
  })
  "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<rss version=\"2.0\"><channel><title>" + xml-escape(site.title) + "</title><link>" + site.url + "/</link><description>" + xml-escape(site.description) + "</description>" + items.join() + "</channel></rss>\n"
}

#let graph-data() = {
  let ms = metas().filter(m => m.kind in ("note", "post"))
  let slugs = ms.map(m => m.slug)
  (
    nodes: ms.map(m => (id: m.slug, title: m.title-text, url: m.url, kind: m.kind, status: m.at("status", default: none))),
    links: all-edges().filter(e => e.from in slugs and e.to in slugs).map(e => (source: e.from, target: e.to)),
  )
}
