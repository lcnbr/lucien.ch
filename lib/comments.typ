// Comments via giscus (https://giscus.app): each page gets a GitHub
// Discussion in the repo, created on the first comment. Readers sign in with
// GitHub; replies and moderation happen on github.com.
#import "config.typ": site
#import "state.typ": preview, drafts

// Off for drafts, on the whole private drafts site, in the editor preview,
// and until the repo and category ids are set, so no discussion is opened
// for a page that is not public yet.
#let comments(draft: false) = {
  let g = site.at("giscus", default: none)
  if draft or drafts or preview or g == none or g.repo-id == "" or g.category-id == "" { return }
  html.elem("section", attrs: (class: "comments", aria-label: "Comments"), {
    html.h2("Comments")
    html.elem("script", attrs: (
      src: "https://giscus.app/client.js",
      data-repo: g.repo,
      data-repo-id: g.repo-id,
      data-category: g.category,
      data-category-id: g.category-id,
      // One discussion per page, matched exactly on the URL path.
      data-mapping: "pathname",
      data-strict: "1",
      data-reactions-enabled: "1",
      data-emit-metadata: "0",
      data-input-position: "bottom",
      // Follows the OS light/dark setting, like assets/style.css.
      data-theme: "preferred_color_scheme",
      data-lang: site.lang,
      data-loading: "lazy",
      crossorigin: "anonymous",
      async: "",
    ), "")
  })
}
