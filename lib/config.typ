// Site-wide settings.
#let site = (
  title: "Lucien",
  url: "https://lucien.ch",
  description: "Notes on physics, photography and other things.",
  author: "Lucien",
  lang: "en",
  // Comments on posts and garden notes (lib/comments.typ). Needs Discussions
  // enabled on the repo and the giscus app installed; ids from giscus.app.
  giscus: (
    repo: "lcnbr/lucien.ch",
    repo-id: "R_kgDOV-Hg-Q",
    category: "Announcements",
    category-id: "DIC_kwDOV-Hg-c4DMHZj",
  ),
  // Header: three sections plus search. `also` lists the pages that live
  // under a section, so its link is marked current there too.
  nav: (
    (label: "Blog", href: "/blog/", also: ("/tags/",)),
    (label: "Garden", href: "/garden/", also: ()),
    (label: "Research", href: "/research/", also: ()),
    (label: "About", href: "/about/", also: ("/cv/", "/blogroll/")),
  ),
  // Pages under About: listed on the About page and in the footer.
  // (Pages inside a section, like a thesis under Research, get their trail
  // from the path, see `crumbs` in base.typ.)
  more: (
    (label: "CV", href: "/cv/", summary: "Education and work, in English and French, with PDFs."),
    (label: "Blogroll", href: "/blogroll/", summary: "Recent posts from blogs I read, updated daily."),
  ),
)
