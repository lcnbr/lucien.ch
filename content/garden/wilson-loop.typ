#import "/lib/note.typ": note
#import "/lib/links.typ": n

#show: note.with(
  title: [Wilson loop],
  summary: "The trace of the holonomy of a gauge field around a closed loop.",
  status: "seedling",
  tags: ("geometry", "qft"),
)

For a #n(<gauge-connection>)[gauge connection] $A$ and a closed curve $C$,

$ W_R (C) = tr_R cal(P) exp(i integral.cont_C A) $

is gauge invariant. In pure Yang-Mills an area law
$chevron.l W(C) chevron.r ~ e^(-sigma "Area"(C))$ signals confinement.
