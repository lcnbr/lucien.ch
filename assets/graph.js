// Notes graph for the garden. No dependencies.
// <div class="garden-graph" data-graph="/garden/graph.json"> draws every note;
// <div class="local-graph" data-slug="x"> draws x and its direct neighbours.
(function () {
  // Resolve site paths from this script's location (assets/ is at the site root),
  // so the graph also works when the site is served from a subdirectory.
  const ROOT = new URL("../", document.currentScript ? document.currentScript.src : location.origin + "/assets/");
  const site = p => new URL(String(p).replace(/^\//, ""), ROOT).href;
  const targets = [...document.querySelectorAll(".garden-graph, .local-graph")];
  if (!targets.length) return;
  fetch(site("garden/graph.json")).then(r => r.json()).then(g => targets.forEach(el => draw(el, g)));

  function draw(el, g) {
    let nodes = g.nodes, links = g.links;
    const focus = el.dataset.slug;
    if (focus) {
      const near = new Set([focus]);
      links.forEach(l => { if (l.source === focus) near.add(l.target); if (l.target === focus) near.add(l.source); });
      if (near.size < 2) return; // nothing to show
      nodes = nodes.filter(n => near.has(n.id));
      links = links.filter(l => near.has(l.source) && near.has(l.target));
    }
    if (!nodes.length) return;
    const css = getComputedStyle(document.documentElement);
    const fg = css.getPropertyValue("--fg").trim(), muted = css.getPropertyValue("--muted").trim(),
      accent = css.getPropertyValue("--accent").trim(), rule = css.getPropertyValue("--rule").trim();
    const canvas = document.createElement("canvas");
    el.appendChild(canvas);
    const dpr = window.devicePixelRatio || 1;
    let W = el.clientWidth, H = el.clientHeight;
    canvas.width = W * dpr; canvas.height = H * dpr; canvas.style.width = W + "px"; canvas.style.height = H + "px";
    const ctx = canvas.getContext("2d"); ctx.scale(dpr, dpr);

    const byId = new Map(nodes.map((n, i) => [n.id, Object.assign({}, n, {
      x: W / 2 + 80 * Math.cos(i * 2.4), y: H / 2 + 80 * Math.sin(i * 2.4), vx: 0, vy: 0, deg: 0 })]));
    const N = [...byId.values()];
    const L = links.map(l => ({ s: byId.get(l.source), t: byId.get(l.target) })).filter(l => l.s && l.t);
    L.forEach(l => { l.s.deg++; l.t.deg++; });
    let hover = null, alpha = 1;

    function step() {
      for (let i = 0; i < N.length; i++) for (let j = i + 1; j < N.length; j++) {
        const a = N[i], b = N[j]; let dx = b.x - a.x, dy = b.y - a.y, d2 = dx * dx + dy * dy + 0.01;
        const f = 900 / d2 * alpha; a.vx -= dx * f; a.vy -= dy * f; b.vx += dx * f; b.vy += dy * f;
      }
      L.forEach(({ s, t }) => { const dx = t.x - s.x, dy = t.y - s.y, d = Math.hypot(dx, dy) || 1, f = (d - 70) * 0.02 * alpha;
        s.vx += dx / d * f; s.vy += dy / d * f; t.vx -= dx / d * f; t.vy -= dy / d * f; });
      N.forEach(n => { n.vx += (W / 2 - n.x) * 0.004 * alpha; n.vy += (H / 2 - n.y) * 0.004 * alpha;
        n.x = Math.max(12, Math.min(W - 12, n.x + (n.vx *= 0.6))); n.y = Math.max(12, Math.min(H - 12, n.y + (n.vy *= 0.6))); });
      alpha *= 0.985;
    }
    function render() {
      ctx.clearRect(0, 0, W, H);
      ctx.strokeStyle = rule; ctx.lineWidth = 1;
      L.forEach(({ s, t }) => { ctx.beginPath(); ctx.moveTo(s.x, s.y); ctx.lineTo(t.x, t.y); ctx.stroke(); });
      N.forEach(n => {
        const r = 3 + Math.sqrt(n.deg) * 1.6, on = n === hover || n.id === focus;
        ctx.fillStyle = on ? accent : (n.kind === "post" ? muted : fg);
        ctx.beginPath(); ctx.arc(n.x, n.y, r, 0, 2 * Math.PI); ctx.fill();
        if (on || N.length <= 25) {
          ctx.fillStyle = on ? fg : muted; ctx.font = "12px sans-serif";
          const label = n.title.length > 32 ? n.title.slice(0, 31) + "…" : n.title, tw = ctx.measureText(label).width;
          const lx = n.x + r + 3 + tw > W - 4 ? n.x - r - 3 - tw : n.x + r + 3;
          ctx.fillText(label, lx, n.y + 4);
        }
      });
    }
    (function loop() { step(); render(); if (alpha > 0.02) requestAnimationFrame(loop); })();

    const pick = e => { const b = canvas.getBoundingClientRect(), x = e.clientX - b.left, y = e.clientY - b.top;
      return N.find(n => Math.hypot(n.x - x, n.y - y) < 10) || null; };
    canvas.addEventListener("mousemove", e => { hover = pick(e); canvas.style.cursor = hover ? "pointer" : "default"; render(); });
    canvas.addEventListener("click", e => { const n = pick(e); if (n) location.href = site(n.url); });
  }
})();
