// Edit in place: "Edit" slides the browser editor in from the right, docked
// beside this page, without leaving it. The page reflows to the left and its
// content is replaced live by each compile; closing restores the published page.
// The editor itself lives at /edit/ (opened with #!path it runs as this panel).
(function () {
  const link = document.querySelector("a.edit-link");
  const main = document.querySelector("main");
  if (!link || !main) return;
  const root = document.documentElement;
  const W_KEY = "edit.panelWidth";
  let dock = null, frame = null, published = null;

  // A tab on the right edge, so the editor is one click away from anywhere on the page.
  const tab = document.createElement("button");
  tab.type = "button"; tab.className = "edit-tab"; tab.title = "Edit this page (E)";
  tab.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16v4z"/><path d="M13.5 6.5l4 4"/></svg><span>Edit</span>';
  document.body.append(tab);

  function open() {
    if (dock) return;
    published = main.innerHTML;
    try { const w = localStorage.getItem(W_KEY); if (w) root.style.setProperty("--edit-w", w); } catch {}
    dock = document.createElement("div");
    dock.className = "edit-dock";
    const handle = document.createElement("div");
    handle.className = "edit-dock-handle"; handle.setAttribute("role", "separator"); handle.setAttribute("aria-label", "Resize editor");
    frame = document.createElement("iframe");
    frame.title = "Editor";
    const u = new URL(link.href, location.href);
    u.hash = "#!" + u.hash.slice(1);
    frame.src = u.href;
    dock.append(handle, frame);
    document.body.append(dock);
    dragToResize(handle);
    // Two frames so the start position is painted before the transition begins.
    requestAnimationFrame(() => requestAnimationFrame(() => root.classList.add("editing")));
    frame.addEventListener("load", () => { try { frame.contentWindow.focus(); } catch {} }, { once: true });
  }

  function close() {
    if (!dock) return;
    root.classList.remove("editing");
    const d = dock; dock = null; frame = null;
    if (published !== null) { main.innerHTML = published; published = null; }
    setTimeout(() => d.remove(), 400);
    tab.focus({ preventScroll: true });
  }

  function dragToResize(handle) {
    handle.addEventListener("pointerdown", e => {
      handle.setPointerCapture(e.pointerId);
      root.classList.add("edit-resizing");
      const move = ev => {
        const w = Math.round(Math.min(Math.max(window.innerWidth - ev.clientX, 340), window.innerWidth - 240)) + "px";
        root.style.setProperty("--edit-w", w);
        try { localStorage.setItem(W_KEY, w); } catch {}
      };
      const up = () => { root.classList.remove("edit-resizing"); handle.removeEventListener("pointermove", move); handle.removeEventListener("pointerup", up); };
      handle.addEventListener("pointermove", move); handle.addEventListener("pointerup", up);
    });
  }

  // Compiled pages and close requests from the editor.
  window.addEventListener("message", e => {
    if (!frame || e.source !== frame.contentWindow) return;
    const m = e.data || {};
    if (m.source !== "lucien-edit") return;
    if (m.type === "close") close();
    if (m.type === "preview" && typeof m.html === "string") {
      const next = new DOMParser().parseFromString(m.html, "text/html").querySelector("main");
      if (next) main.innerHTML = next.innerHTML;
    }
  });

  const wants = e => e.button === 0 && !e.metaKey && !e.ctrlKey && !e.shiftKey && !e.altKey;
  link.addEventListener("click", e => { if (wants(e)) { e.preventDefault(); open(); } });
  tab.addEventListener("click", open);
  document.addEventListener("keydown", e => {
    if (e.key === "Escape" && dock) close();
    const typing = /^(INPUT|TEXTAREA|SELECT)$/.test(e.target.tagName) || e.target.isContentEditable;
    if ((e.key === "e" || e.key === "E") && !typing && !e.metaKey && !e.ctrlKey && !e.altKey && !dock) { e.preventDefault(); open(); }
  });
})();
