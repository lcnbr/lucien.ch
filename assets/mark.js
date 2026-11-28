// The scroll mark: the logo from the CV (dash dot dot dash dot dot) runs
// clockwise round the edge of the window as the page scrolls. It takes over
// from the logo in the header once that has scrolled away, setting out from
// the top edge right above where it was, and is back there at the bottom of
// the page, leaving a hairline behind it, so the line shows how far you have
// read. It is one SVG path round the window whose dashes are the logo, so
// the dashes bend round the corners. Sizes are set in CSS (.scroll-mark).
(() => {
  const NS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(NS, "svg");
  svg.setAttribute("class", "scroll-mark");
  svg.setAttribute("aria-hidden", "true");
  // The hairline, then the logo twice: once wide in the page colour (a halo,
  // so it stays clear over text scrolling under it) and once on top of that.
  const [trail, halo, mark] = ["trail", "halo", "mark"].map(name => {
    const path = document.createElementNS(NS, "path");
    path.setAttribute("class", name);
    return path;
  });
  svg.append(trail, halo, mark);
  document.body.append(svg);

  const root = document.documentElement;
  const anchor = document.querySelector(".site-title .logo");
  let u = 10, len = 0;

  // The logo in units of u, as in pdf-logo (lib/cv.typ): bars 1 × 0.4, dots
  // 0.4 × 0.4, gaps 0.6. With round caps 0.4 wide, a bar is a 0.6 dash, a dot
  // a zero-length dash, and a gap 1. It is 6.6 long from cap to cap.
  const LOGO = [0.6, 1, 0, 1, 0, 1, 0.6, 1, 0, 1, 0];

  function layout() {
    const cs = getComputedStyle(svg);
    const box = svg.getBoundingClientRect();
    const w = box.width, h = box.height;
    u = parseFloat(cs.getPropertyValue("--u")) || 10;
    const i = (parseFloat(cs.getPropertyValue("--inset")) || 0) + 0.2 * u;
    const r = Math.max(0, Math.min(parseFloat(cs.getPropertyValue("--corner")) || 0, w / 2 - i, h / 2 - i));
    const x0 = i, y0 = i, x1 = w - i, y1 = h - i;
    // Clockwise from the top edge, above the header logo (or the corner).
    const xs = Math.min(Math.max(anchor ? anchor.getBoundingClientRect().left : 0, x0 + r), x1 - r - 7 * u);
    const d = `M${xs} ${y0}H${x1 - r}A${r} ${r} 0 0 1 ${x1} ${y0 + r}V${y1 - r}`
      + `A${r} ${r} 0 0 1 ${x1 - r} ${y1}H${x0 + r}A${r} ${r} 0 0 1 ${x0} ${y1 - r}V${y0 + r}`
      + `A${r} ${r} 0 0 1 ${x0 + r} ${y0}H${xs}Z`;
    for (const path of [trail, halo, mark]) path.setAttribute("d", d);
    len = 2 * (x1 - x0 + y1 - y0 - 4 * r) + 2 * Math.PI * r;
    // The logo, then a gap longer than the whole path.
    const dashes = LOGO.map(x => x * u).concat(len + 10 * u).join(" ");
    halo.style.strokeDasharray = mark.style.strokeDasharray = dashes;
    update();
  }

  function update() {
    const max = root.scrollHeight - innerHeight;
    const p = max > 0 ? Math.min(1, Math.max(0, scrollY / max)) : 0;
    // Where the first bar starts: its cap touches the start of the path at
    // the top of the page, and at the bottom the last dot stops one gap short
    // of it, so the logo has gone round once.
    const s = 0.2 * u + p * (len - 7.2 * u);
    halo.style.strokeDashoffset = mark.style.strokeDashoffset = -s;
    // The hairline runs from the start of the path to one gap behind the logo.
    trail.style.strokeDasharray = `${Math.max(0, s - 0.8 * u)} ${len + u}`;
  }

  let queued = false;
  const queue = () => {
    if (queued) return;
    queued = true;
    requestAnimationFrame(() => { queued = false; update(); });
  };
  addEventListener("scroll", queue, { passive: true });
  // The window changes size: redraw the path. The page changes length
  // (images load, a note unfolds): move the logo.
  new ResizeObserver(layout).observe(svg);
  new ResizeObserver(queue).observe(document.body);
  // Shown only while the header logo is out of sight.
  if (anchor && "IntersectionObserver" in window) {
    new IntersectionObserver(([e]) => svg.classList.toggle("shown", !e.isIntersecting)).observe(anchor);
  } else {
    svg.classList.add("shown");
  }
})();
