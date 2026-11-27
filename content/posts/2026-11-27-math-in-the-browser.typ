#import "/lib/post.typ": post
#import "/lib/links.typ": n
#import "/lib/figures.typ": diagram-frame, svg-math

#show: post.with(
  title: [A very easily editable blog, with typst],
  summary: "I created this blog / personal site, so that editing / creating is really easy",
  tags: ("meta", "typst"),
)

I've been wanting to have a personal site for a long time. I've always been very particular in my choice of tech stack, and I had never found anything that felt perfect, until now! This site ticks every box. 

 - Typst as the content. I've been a fan of typst the moment I heard of it (4 years now!). It is the modern Latex, better in every way, extensible etc.
 - Static-CMS.  Static sites are great, free to host on many platforms, but there was always some friction to actually producing content. Here I can (and you can) edit in the browser, from anywhere and see it live in the website.



Every equation on this page is written in Typst and exported as native MathML.
No JavaScript renders it; the browser does, using the same New Computer Modern
Math font Typst uses for PDF.#footnote[Firefox has rendered MathML for years; Chromium caught up in version 109, and Safari follows its own WebKit implementation.]

== Inline and display

The Gaussian integral $integral_(-oo)^oo e^(-x^2) dif x = sqrt(pi)$ sits inline,
and its $n$-dimensional cousin#footnote[Valid for symmetric positive-definite $A$: diagonalise it and the integral factorises into $n$ one-dimensional Gaussians.] gets its own line:

$ integral_(RR^n) e^(-1/2 x^T A x + J^T x) dif^n x
  = sqrt((2 pi)^n / (det A)) thin e^(1/2 J^T A^(-1) J) $

== Aligned systems

Maxwell's equations in differential form:#footnote[In SI units. In Gaussian units the factors of $epsilon_0$ and $mu_0$ give way to powers of $c$.]

$ nabla dot bold(E) &= rho / epsilon_0 \
  nabla dot bold(B) &= 0 \
  nabla times bold(E) &= -(partial bold(B)) / (partial t) \
  nabla times bold(B) &= mu_0 bold(J) + mu_0 epsilon_0 (partial bold(E)) / (partial t) $

== Matrices, cases and Dirac notation

$ sigma_x = mat(0, 1; 1, 0), quad
  sigma_y = mat(0, -i; i, 0), quad
  sigma_z = mat(1, 0; 0, -1) $

$ theta(x) = cases(1 & "if" x > 0, 0 & "otherwise") $

$ chevron.l psi_f | e^(-i H t / planck) | psi_i chevron.r
  = integral cal(D) q thin e^(i S[q] / planck) $

The geometric phase picked up around a closed loop is treated in the
#n(<berry-phase>)[note on the Berry phase].

== A plot drawn with plain Typst

#let plot-sinc() = {
  let w = 10cm
  let h = 4cm
  let f(x) = if x == 0 { 1.0 } else { calc.sin(x) / x }
  let xs = range(0, 401).map(i => -20 + i * 0.1)
  let to-pt(x, y) = ((x + 20) / 40 * w, h * 0.75 - y * h * 0.7)
  box(width: w, height: h, {
    place(line(start: (0pt, h * 0.75), end: (w, h * 0.75), stroke: 0.5pt + gray))
    place(line(start: (w / 2, 0pt), end: (w / 2, h), stroke: 0.5pt + gray))
    place(curve(stroke: 1.2pt + rgb("#1f5fa8"),
      curve.move(to-pt(xs.first(), f(xs.first()))),
      ..xs.slice(1).map(x => curve.line(to-pt(x, f(x)))),
    ))
    place(dx: w - 1.8cm, dy: 0.2cm, text(size: 9pt)[$y = sin(x) / x$])
  })
}

#figure(diagram-frame(plot-sinc()), caption: [$sin(x) slash x$ on $[-20, 20]$, drawn with `curve` and exported as SVG.])

== The escape hatch

If a browser ever draws an equation badly, `svg-math` renders that one as SVG:

#svg-math[$ Z = integral cal(D) phi.alt thin exp(-integral dif^d x [1/2 (partial phi.alt)^2 + V(phi.alt)]) $]


and now this is neat! This is really cool!!