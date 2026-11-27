#import "/lib/note.typ": note
#import "/lib/links.typ": n

#show: note.with(
  title: [Gauge connection],
  summary: "A rule for comparing fibres at nearby points; physicists call it a gauge field.",
  status: "seedling",
  tags: ("geometry",),
)

A connection on a principal $G$-bundle is a Lie-algebra valued one-form $A$.
Under a gauge transformation $g(x)$ it transforms as

$ A -> g A g^(-1) + g dif g^(-1) $

and its curvature is $F = dif A + A and A$. Parallel transport around a closed
loop gives the #n(<wilson-loop>)[Wilson loop]. For a $U(1)$ bundle over
parameter space it is the #n(<berry-phase>)[Berry phase].
