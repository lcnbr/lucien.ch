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
    category-id: "", // filled in once Discussions are enabled
  ),
  nav: (
    (label: "Blog", target: <blog>),
    (label: "Garden", target: <garden>),
    (label: "About", target: <about>),
  ),
)
