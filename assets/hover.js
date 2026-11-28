// Hover previews (MyST-style) and inline windows (Rookery-style). No dependencies.
//
// Hovering an internal link shows its target in a card: the element with the
// link's #id (an equation, figure, footnote) or the opening of the linked
// page. The card holds the target page's own HTML, so MathML and SVG
// diagrams render as they do there. Garden links in notes also get a small
// toggle that unfolds the target inline.
(function () {
  const pages = new Map(); // url without hash -> Promise<Document>
  const MAX_DEPTH = 3;
  let card = null, owner = null, showTimer = 0, hideTimer = 0, lastPointer = "mouse";

  // The editor's preview is an about:srcdoc frame (origin "null"); its links
  // resolve against the site, which is the frame's base URL.
  const origin = location.origin !== "null" ? location.origin : new URL(document.baseURI).origin;
  const internal = a => {
    if (!a.href || a.target || a.hasAttribute("download") || a.closest(".hover-card")) return false;
    const u = new URL(a.href, location.href);
    if (u.origin !== origin) return false;
    if (/\.(xml|json|pdf|png|jpe?g|webp|avif|svg)$/i.test(u.pathname)) return false;
    return true;
  };
  const pageKey = u => { const x = new URL(u, location.href); x.hash = ""; return x.href; };
  const samePage = u => pageKey(u) === pageKey(location.href);

  function load(url) {
    const key = pageKey(url);
    if (samePage(url)) return Promise.resolve(document);
    if (!pages.has(key)) {
      pages.set(key, fetch(key).then(r => { if (!r.ok) throw new Error(r.status); return r.text(); })
        .then(t => new DOMParser().parseFromString(t, "text/html"))
        .catch(e => { pages.delete(key); throw e; }));
    }
    return pages.get(key);
  }

  // Rewrite relative links in borrowed HTML so they resolve from the target page.
  function rebase(node, base) {
    node.querySelectorAll("a[href], img[src]").forEach(el => {
      const attr = el.tagName === "A" ? "href" : "src", v = el.getAttribute(attr);
      if (v) el.setAttribute(attr, new URL(v, base).href);
    });
    node.querySelectorAll("[id]").forEach(el => el.removeAttribute("id"));
    // Sidenotes aren't shown in previews; leaving them in would also match the
    // page's body:has(.sidenote) layout rule and shift the page sideways.
    node.querySelectorAll(".sidenote").forEach(el => el.remove());
    return node;
  }

  // What to show for a URL: the #target element, or the page's head and opening.
  async function preview(url) {
    const u = new URL(url, location.href), doc = await load(u.href), frag = document.createElement("div");
    const id = decodeURIComponent(u.hash.slice(1));
    if (id) {
      const el = doc.getElementById(id);
      if (!el) return null;
      const box = el.closest("figure, li, p, math[display=block], .diagram, h2, h3, h4") || el;
      frag.append(box.cloneNode(true));
      if (/^H[2-4]$/.test(box.tagName)) { // a section: heading plus what follows
        let n = box.nextElementSibling;
        for (let i = 0; n && i < 3 && !/^H[2-4]$/.test(n.tagName); i++, n = n.nextElementSibling) frag.append(n.cloneNode(true));
      }
    } else {
      const h1 = doc.querySelector("main h1"), meta = doc.querySelector("main .page-head .meta"), art = doc.querySelector("main article");
      if (h1) { const t = document.createElement("div"); t.className = "hover-title"; t.textContent = h1.textContent; frag.append(t); }
      if (meta) frag.append(meta.cloneNode(true));
      if (art) {
        let used = 0;
        for (const el of art.children) {
          if (used >= 3 || (used > 0 && /^H[2-4]$/.test(el.tagName))) break;
          frag.append(el.cloneNode(true)); used++;
        }
      } else if (!h1) return null;
    }
    return rebase(frag, u.href);
  }

  // ---- popover card ----------------------------------------------------------
  function place(a) {
    const r = a.getBoundingClientRect(), w = Math.min(448, window.innerWidth - 16);
    card.style.width = w + "px";
    let x = r.left + window.scrollX, y = r.bottom + window.scrollY + 6;
    x = Math.max(8 + window.scrollX, Math.min(x, window.scrollX + window.innerWidth - w - 8));
    card.style.left = x + "px"; card.style.top = y + "px";
    const cr = card.getBoundingClientRect(); // flip above if it would leave the screen
    if (cr.bottom > window.innerHeight - 8 && r.top > cr.height + 12) card.style.top = (r.top + window.scrollY - cr.height - 6) + "px";
  }
  function hide() { if (card) card.remove(); card = null; owner = null; }
  async function show(a) {
    if (owner === a && card) return;
    let body;
    try { body = await preview(a.href); } catch { return; }
    if (!body || !a.matches(":hover, :focus") && lastPointer !== "touch") return;
    hide();
    card = document.createElement("div");
    card.className = "hover-card"; card.setAttribute("role", "tooltip");
    card.append(body);
    card.addEventListener("mouseenter", () => clearTimeout(hideTimer));
    card.addEventListener("mouseleave", () => { hideTimer = setTimeout(hide, 250); });
    document.body.append(card); owner = a; place(a);
  }

  document.addEventListener("pointerdown", e => { lastPointer = e.pointerType; }, true);
  document.addEventListener("mouseover", e => {
    const a = e.target.closest("a"); if (!a || !internal(a) || lastPointer === "touch") return;
    clearTimeout(hideTimer); clearTimeout(showTimer);
    showTimer = setTimeout(() => show(a), 300);
  });
  document.addEventListener("mouseout", e => {
    const a = e.target.closest("a"); if (!a || !internal(a)) return;
    clearTimeout(showTimer); hideTimer = setTimeout(hide, 250);
  });
  document.addEventListener("focusin", e => { const a = e.target.closest("a"); if (a && internal(a)) show(a); });
  document.addEventListener("keydown", e => { if (e.key === "Escape") hide(); });
  // Touch: the first tap previews, a second tap on the same link follows it.
  document.addEventListener("click", e => {
    const a = e.target.closest("a");
    if (!a || lastPointer !== "touch" || !internal(a) || owner === a) return;
    e.preventDefault(); show(a);
  });
  document.addEventListener("click", e => { if (card && !e.target.closest(".hover-card, a")) hide(); });

  // ---- inline windows ----------------------------------------------------------
  function addToggles(root, depth) {
    if (depth >= MAX_DEPTH) return;
    root.querySelectorAll("a").forEach(a => {
      if (!internal(a) || a.classList.contains("window-open") || samePage(a.href) || new URL(a.href).hash || !/\/garden\//.test(new URL(a.href).pathname)) return;
      if (a.nextElementSibling && a.nextElementSibling.classList.contains("window-toggle")) return;
      const b = document.createElement("button");
      b.type = "button"; b.className = "window-toggle"; b.textContent = "+";
      b.setAttribute("aria-expanded", "false"); b.setAttribute("aria-label", "Unfold " + a.textContent + " here");
      b.addEventListener("click", async () => {
        const block = a.closest("p, li, td, figcaption") || a.parentElement;
        const open = b.getAttribute("aria-expanded") === "true";
        if (open) { b._window && b._window.remove(); b.setAttribute("aria-expanded", "false"); b.textContent = "+"; return; }
        let body; try { body = await preview(a.href); } catch { return; }
        if (!body) return;
        const w = document.createElement("div"); w.className = "window";
        const link = document.createElement("a"); link.className = "window-open"; link.href = a.href; link.textContent = "Open note →";
        w.append(body, link); block.after(w); b._window = w;
        b.setAttribute("aria-expanded", "true"); b.textContent = "−";
        addToggles(w, depth + 1);
      });
      a.after(b);
    });
  }
  if (document.body.classList.contains("note")) document.querySelectorAll("main article").forEach(art => addToggles(art, 0));
})();
