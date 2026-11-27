#import "@preview/fletcher:0.6.0" as fletcher: diagram, node, edge
#import "@preview/lilaq:0.6.0" as lq
#import "/lib/post.typ": post
#import "/lib/links.typ": n
#import "/lib/figures.typ": diagram-frame

#show: post.with(
  title: [Diagrams and plots],
  summary: "Commutative diagrams and a Feynman diagram with fletcher, data plots with lilaq, all as inline SVG.",
  tags: ("meta", "typst"),
)

Packages that draw (fletcher, cetz, quill, lilaq) go through `diagram-frame`,
which emits inline SVG in HTML and leaves the PDF untouched.

== A commutative diagram

// fletcher 0.6: edges inside a math-mode diagram need `in-math: true`.
#let hom = edge.with(in-math: true)
#figure(diagram-frame(diagram(spacing: 4em, $
  G hom(f, ->) hom("d", pi, ->>) & im(f) \
  G slash ker(f) hom("ur", tilde(f), "hook-->")
$)), caption: [First isomorphism theorem.])

== A Feynman diagram

#figure(diagram-frame(diagram(
  spacing: (12mm, 8mm),
  node((0, 0), $e^-$), node((0, 2), $e^+$),
  node((4, 0), $mu^-$), node((4, 2), $mu^+$),
  edge((0, 0), (1, 1), "-|>-"),
  edge((1, 1), (0, 2), "-|>-"),
  edge((1, 1), (3, 1), "~", $gamma$),
  edge((4, 0), (3, 1), "-<|-"),
  edge((3, 1), (4, 2), "-<|-"),
)), caption: [$e^+ e^- -> mu^+ mu^-$ at tree level.])

== A data plot

The data lives in `data/oscillator.csv`, so it can come from a simulation run
elsewhere.

#let rows = csv("/data/oscillator.csv", row-type: dictionary)
#let t = rows.map(r => float(r.t))
#figure(diagram-frame(lq.diagram(
  width: 10cm, height: 5cm,
  xlabel: $t$, ylabel: $x(t)$,
  lq.plot(t, rows.map(r => float(r.x)), mark: none, label: [damped]),
  lq.plot(t, rows.map(r => float(r.envelope)), mark: none, stroke: (dash: "dashed"), label: [envelope]),
)), caption: [Damped harmonic oscillator, $gamma = 0.15 omega_0$.])

Background on the geometry behind gauge fields is in the
#n(<gauge-connection>)[garden note on connections].
