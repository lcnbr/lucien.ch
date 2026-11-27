// Rendering helpers for content that only exists as laid-out graphics.
//
// Packages like fletcher, cetz, quill and lilaq produce laid-out frames, which
// HTML export cannot express as HTML. `diagram-frame` turns them into inline
// SVG in HTML and leaves them untouched in PDF, so the same source works for
// both targets.

#let diagram-frame(body, class: "diagram") = context {
  if target() == "html" {
    html.div(class: class, html.frame(body))
  } else {
    align(center, body)
  }
}

// Escape hatch: render one equation as SVG instead of MathML, for the rare
// construct a browser draws badly. Usage: #svg-math[$ ... $]
#let svg-math(body) = context {
  if target() == "html" {
    html.div(class: "svg-math", html.frame(body))
  } else {
    body
  }
}
