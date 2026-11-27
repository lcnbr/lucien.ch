// Bundle entry point: emits every page of lucien.ch.
//
//   python3 scripts/build.py          (writes build/manifest.json, then compiles)
//   typst compile --features html,bundle --format bundle site.typ dist
#import "lib/state.typ": current
#import "lib/indexes.typ": home, blog-index, garden-index, tag-page, all-tags, rss, graph-data

#let manifest = json("build/manifest.json")

// Content pages, each labelled with its slug so #link(<slug>) and #n(<slug>) work.
#for entry in manifest.pages {
  [#document(entry.out, {
    current.update(entry)
    // Counters are global across a bundle; number each page from 1.
    counter(math.equation).update(0)
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(figure.where(kind: raw)).update(0)
    counter(footnote).update(0)
    include entry.path
  }) #label(entry.slug)]
}

// Generated pages.
#document("index.html", home()) <home>
#document("blog/index.html", blog-index()) <blog>
#document("garden/index.html", garden-index()) <garden>

#context for tag in all-tags() {
  document("tags/" + tag + "/index.html", tag-page(tag))
}

#context asset("feed.xml", rss())
#context asset("garden/graph.json", json.encode(graph-data(), pretty: false))

// Static files: css, fonts, scripts.
#for a in manifest.assets {
  asset(a.out, read(a.path, encoding: none))
}
