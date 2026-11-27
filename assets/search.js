// Site search as an overlay on every page: the header's Search button,
// Ctrl/⌘ K or "/" opens it, results appear as you type. Uses the Pagefind
// index built by `scripts/build.py --search`. No dependencies.
(function () {
  const ROOT = new URL("../", document.currentScript ? document.currentScript.src : location.origin + "/assets/");
  const MAX = 8;
  let dialog, input, list, note, pagefind = null, active = -1, results = [], seq = 0;

  const isMac = /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent);
  document.querySelectorAll(".search-key").forEach(k => { k.textContent = isMac ? "⌘K" : "Ctrl K"; });

  function build() {
    dialog = document.createElement("dialog");
    dialog.className = "search-dialog";
    dialog.setAttribute("aria-label", "Search");
    dialog.innerHTML = `
      <div class="search-box">
        <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
        <input type="search" placeholder="Search posts and notes" autocomplete="off" spellcheck="false"
          role="combobox" aria-expanded="true" aria-controls="search-results" aria-autocomplete="list">
        <kbd>Esc</kbd>
      </div>
      <ol id="search-results" class="search-results" role="listbox"></ol>
      <p class="search-note"></p>`;
    document.body.append(dialog);
    input = dialog.querySelector("input");
    list = dialog.querySelector(".search-results");
    note = dialog.querySelector(".search-note");
    input.addEventListener("input", () => run(input.value));
    input.addEventListener("keydown", e => {
      if (e.key === "Escape") { e.preventDefault(); dialog.close(); return; } // not "clear the field"
      if (e.key === "ArrowDown" || e.key === "ArrowUp") {
        e.preventDefault();
        if (!results.length) return;
        select((active + (e.key === "ArrowDown" ? 1 : -1) + results.length) % results.length);
      } else if (e.key === "Enter" && results[active]) {
        e.preventDefault();
        go(results[active].url, e.metaKey || e.ctrlKey);
      }
    });
    // Click on the backdrop (outside the panel) closes.
    dialog.addEventListener("click", e => { if (e.target === dialog) dialog.close(); });
    list.addEventListener("mousemove", e => {
      const li = e.target.closest("li");
      if (li) select(+li.dataset.i, false);
    });
  }

  async function load() {
    if (pagefind) return pagefind;
    try {
      pagefind = await import(new URL("pagefind/pagefind.js", ROOT).href);
      await pagefind.options({ baseUrl: ROOT.pathname, excerptLength: 22 });
      pagefind.init();
    } catch (e) {
      pagefind = null;
      throw e;
    }
    return pagefind;
  }

  function open() {
    if (!dialog) build();
    if (dialog.open) { input.select(); return; }
    dialog.showModal();
    input.select();
    hint();
    load().catch(() => { note.textContent = "Search isn't available here: the index is built when the site is published."; });
  }

  function hint() {
    if (!input.value.trim()) {
      list.replaceChildren(); results = []; active = -1;
      note.textContent = "Type to search. ↑ ↓ to move, Enter to open.";
    }
  }

  async function run(q) {
    const my = ++seq;
    if (!q.trim()) { hint(); return; }
    let pf;
    try { pf = await load(); } catch { return; }
    const search = await pf.debouncedSearch(q, {}, 120);
    if (search === null || my !== seq) return; // superseded by newer input
    const data = await Promise.all(search.results.slice(0, MAX).map(r => r.data()));
    if (my !== seq) return;
    results = data.map(d => ({ url: d.url, title: (d.meta && d.meta.title) || d.url, excerpt: d.excerpt }));
    render(search.results.length);
  }

  function render(total) {
    list.replaceChildren(...results.map((r, i) => {
      const li = document.createElement("li");
      li.id = "search-r" + i; li.dataset.i = i; li.setAttribute("role", "option");
      const a = document.createElement("a");
      a.href = r.url;
      const t = document.createElement("span"); t.className = "search-title"; t.textContent = r.title.replace(/ · .*$/, "");
      const where = document.createElement("span"); where.className = "search-where";
      const section = (r.url.match(/\/(blog|garden)\/[^/]/) || [])[1];
      where.textContent = section === "blog" ? "Post" : section === "garden" ? "Note" : "Page";
      const x = document.createElement("span"); x.className = "search-excerpt";
      // Pagefind excerpts are escaped text with <mark> around matches.
      x.innerHTML = r.excerpt;
      x.querySelectorAll("*:not(mark)").forEach(n => n.replaceWith(...n.childNodes));
      a.append(t, where, x);
      li.append(a);
      return li;
    }));
    note.textContent = total ? (total > MAX ? `${MAX} of ${total} results` : `${total} result${total === 1 ? "" : "s"}`) : "No results.";
    select(results.length ? 0 : -1);
  }

  function select(i, scroll = true) {
    active = i;
    list.querySelectorAll("li").forEach((li, j) => li.setAttribute("aria-selected", String(j === i)));
    input.setAttribute("aria-activedescendant", i >= 0 ? "search-r" + i : "");
    if (scroll && i >= 0) list.children[i].scrollIntoView({ block: "nearest" });
  }

  function go(url, newTab) {
    if (newTab) window.open(url, "_blank", "noopener");
    else { dialog.close(); location.href = url; }
  }

  document.addEventListener("click", e => { if (e.target.closest(".search-open")) { e.preventDefault(); open(); } });
  document.addEventListener("keydown", e => {
    const typing = /^(INPUT|TEXTAREA|SELECT)$/.test(e.target.tagName) || e.target.isContentEditable;
    if ((e.key === "k" || e.key === "K") && (e.metaKey || e.ctrlKey)) { e.preventDefault(); open(); }
    else if (e.key === "/" && !typing && !e.metaKey && !e.ctrlKey && !e.altKey) { e.preventDefault(); open(); }
  });
})();
