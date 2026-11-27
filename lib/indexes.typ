// Generated pages: home, blog index, garden index, tag pages, RSS, graph data.
#import "base.typ": shell
#import "config.typ": site
#import "util.typ": parse-date, fmt-date, iso-date
#import "links.typ": all-edges

// All page metadata, needs context.
#let metas() = query(<page-meta>).map(m => m.value)
// Drafts only exist in the private drafts build; there they are listed with a badge.
#let is-draft(m) = m.at("draft", default: false)
#let posts() = metas().filter(m => m.kind == "post").sorted(key: m => m.date).rev()
#let notes() = metas().filter(m => m.kind == "note").sorted(key: m => m.at("updated", default: "")).rev()

#let draft-badge(m) = if is-draft(m) { html.span(class: "draft-badge", "draft"); [ ] }

#let post-item(m) = html.li({
  draft-badge(m)
  html.time(datetime: parse-date(m.date), fmt-date(parse-date(m.date)))
  [ ]
  link(label(m.slug), m.title)
  if m.summary != none { html.p(class: "summary", m.summary) }
})

#let note-item(m) = html.li({
  draft-badge(m)
  html.span(class: "status " + m.status, m.status)
  [ ]
  link(label(m.slug), m.title)
  if m.summary != none { html.p(class: "summary", m.summary) }
})

// A labelled section with an optional "see all" link: the same head is used
// for every list on the home page, backlinks, comments and the blogroll.
#let section-head(title, href: none, more: none) = html.div(class: "section-head", {
  html.h2(title)
  if href != none { html.a(href: href, more) }
})

#let home() = context shell(kind: "home", path: "/", {
  html.p(class: "lede", site.description)
  section-head("Recent posts", href: "/blog/", more: "All posts →")
  html.ul(class: "list", posts().slice(0, calc.min(5, posts().len())).map(post-item).join())
  section-head("Recently tended in the garden", href: "/garden/", more: "The garden →")
  html.ul(class: "list", notes().slice(0, calc.min(5, notes().len())).map(note-item).join())
})

#let blog-index() = context shell(title: "Blog", heading: [Blog], kind: "index", path: "/blog/", {
  html.p(class: "lede", [Longer pieces, newest first.])
  html.ul(class: "list", posts().map(post-item).join())
})

#let garden-index() = context shell(title: "Garden", heading: [Garden], kind: "index", path: "/garden/", {
  html.p(class: "lede", [Evergreen notes, linked to each other. Seedlings are rough, budding notes are taking shape, evergreen notes are stable.])
  html.elem("div", attrs: (class: "garden-graph"))
  html.ul(class: "list", notes().map(note-item).join())
})

#let all-tags() = metas().map(m => m.at("tags", default: ())).flatten().dedup().sorted()

#let tag-page(tag) = context shell(title: "#" + tag, heading: [Tagged #raw("#" + tag)], kind: "index", path: "/tags/" + tag + "/", {
  html.p(class: "lede", [Posts and notes tagged #raw("#" + tag).])
  let ms = metas().filter(m => tag in m.at("tags", default: ()))
  html.ul(class: "list", ms.map(m => if m.kind == "post" { post-item(m) } else if m.kind == "note" { note-item(m) } else { html.li(link(label(m.slug), m.title)) }).join())
})

// Blogroll: the newest posts of the blogs in blogroll.txt, fetched at build
// time by scripts/blogroll.py into build/blogroll.json.
#let blogroll-page(data) = shell(title: "Blogroll", heading: [Blogroll], description: "Recent posts from blogs I read.", kind: "index", path: "/blogroll/",
  meta: if data.fetched != none [Updated daily · last fetched #fmt-date(parse-date(data.fetched))] else [Updated daily],
{
  html.p(class: "lede", [Recent posts from blogs I read, newest first.])
  if data.posts.len() == 0 {
    html.p(class: "meta", [No posts fetched in this build.])
  } else {
    html.ul(class: "list", data.posts.map(p => html.li({
      html.time(datetime: parse-date(p.date), fmt-date(parse-date(p.date)))
      [ ]
      html.a(href: p.url, p.title)
      html.p(class: "summary", html.a(class: "quiet", href: p.at("blog-url"), p.blog))
    })).join())
  }
  if data.blogs.len() > 0 {
    section-head("Blogs")
    html.ul(class: "list compact", data.blogs.map(b => html.li({
      html.a(href: b.url, b.title)
      [ ]
      html.a(class: "quiet", href: b.feed, "feed")
    })).join())
  }
})

// --- feeds and data ---------------------------------------------------------

#let xml-escape(s) = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")

#let rss() = {
  let ps = posts().filter(m => not is-draft(m))
  let items = ps.slice(0, calc.min(20, ps.len())).map(m => {
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
