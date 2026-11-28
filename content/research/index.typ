#import "/lib/page.typ": page
#import "/lib/thesis.typ": thesis-list

#show: page.with(
  title: [Research],
  summary: "My theses, in full, one page per chapter.",
)

#html.p(class: "lede")[I work on theoretical physics, currently on automating high-precision predictions in quantum field theory for my PhD at the University of Bern. My theses are here in full, one page per chapter, with the typeset PDFs.]

= Theses

#thesis-list()
