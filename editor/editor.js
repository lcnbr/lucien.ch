// lucien.ch browser editor.
//
// Loads the site's Typst sources from GitHub, compiles the open page to HTML
// in the browser with typst-wasm (same Typst version and templates as the real
// build), shows it beside the source, and commits changes back to GitHub with
// a fine-grained token kept in this browser.
import { EditorView, EditorState, basicSetup, keymap, indentWithTab, typst } from "./vendor/codemirror.js";
import { createTypstCompiler } from "typst-wasm";
import { createWebWorker } from "typst-wasm/worker/browser";
import { fixMathML } from "./mathml-fix.js";

const REPO = { owner: "lcnbr", repo: "lucien.ch" };
const SOURCE_DIRS = ["content/", "lib/", "data/"];
const TEXT_EXT = /\.(typ|csv|json|toml|ya?ml|bib|txt|md|svg|xml)$/i;
const VENDOR = new URL("./vendor/", import.meta.url);
const OFFICIAL_PACKAGES = "https://packages.typst.org";
const store = {
  get token() { try { return localStorage.getItem("edit.token") || ""; } catch { return ""; } },
  set token(v) { try { v ? localStorage.setItem("edit.token", v) : localStorage.removeItem("edit.token"); } catch {} },
  get branch() { try { return localStorage.getItem("edit.branch") || "main"; } catch { return "main"; } },
  set branch(v) { try { localStorage.setItem("edit.branch", v || "main"); } catch {} },
  draft(path, text) {
    try { text === undefined ? localStorage.removeItem("edit.draft:" + path) : localStorage.setItem("edit.draft:" + path, text); } catch {}
  },
  getDraft(path) { try { return localStorage.getItem("edit.draft:" + path); } catch { return null; } },
};

const $ = id => document.getElementById(id);
const ui = {
  file: $("file"), save: $("save"), status: $("status"), view: $("view"),
  preview: $("preview"), diagnostics: $("diagnostics"),
};

// path -> { sha, text?, bytes?, loaded, saved (text as on GitHub) }
const files = new Map();
let current = null, compiler = null, view = null, compileTimer = 0, compileSeq = 0;

function setStatus(text, kind = "") { ui.status.textContent = text; ui.status.className = "status " + kind; }

// ---- GitHub ------------------------------------------------------------------
async function gh(path, opts = {}) {
  const headers = { Accept: "application/vnd.github+json", ...(opts.headers || {}) };
  if (store.token) headers.Authorization = "Bearer " + store.token;
  const r = await fetch("https://api.github.com" + path, { ...opts, headers });
  if (!r.ok) {
    let msg = r.status + " " + r.statusText;
    try { msg = (await r.json()).message || msg; } catch {}
    const e = new Error(msg); e.status = r.status; throw e;
  }
  return r;
}
const repoPath = p => `/repos/${REPO.owner}/${REPO.repo}${p}`;

async function loadTree() {
  const r = await gh(repoPath(`/git/trees/${encodeURIComponent(store.branch)}?recursive=1`));
  const tree = (await r.json()).tree.filter(e => e.type === "blob" && SOURCE_DIRS.some(d => e.path.startsWith(d)));
  for (const e of tree) files.set(e.path, { sha: e.sha, loaded: false });
}

async function loadFile(path) {
  const f = files.get(path);
  if (!f || f.loaded) return f;
  const r = await gh(repoPath(`/contents/${path.split("/").map(encodeURIComponent).join("/")}?ref=${encodeURIComponent(store.branch)}`),
    { headers: { Accept: "application/vnd.github.raw" } });
  if (TEXT_EXT.test(path)) { f.text = await r.text(); f.saved = f.text; }
  else f.bytes = new Uint8Array(await r.arrayBuffer());
  f.loaded = true;
  if (compiler) await pushToCompiler(path);
  return f;
}

function b64(text) {
  const bytes = new TextEncoder().encode(text);
  let s = ""; for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

async function save() {
  if (!current) return;
  if (!store.token) { openSettings(); return; }
  const f = files.get(current), text = view.state.doc.toString();
  ui.save.disabled = true; setStatus("Saving…");
  try {
    const body = { message: `Edit ${current}`, content: b64(text), branch: store.branch };
    if (f.sha) body.sha = f.sha;
    const r = await gh(repoPath(`/contents/${current.split("/").map(encodeURIComponent).join("/")}`),
      { method: "PUT", body: JSON.stringify(body), headers: { "Content-Type": "application/json" } });
    const j = await r.json();
    f.sha = j.content.sha; f.saved = text; store.draft(current);
    setStatus(`Saved · commit ${j.commit.sha.slice(0, 7)} · the site rebuilds in about a minute`);
  } catch (e) {
    setStatus(e.status === 409 ? "Save failed: the file changed on GitHub. Reload to merge." : "Save failed: " + e.message, "error");
  }
  refreshDirty();
}

// ---- compiler ----------------------------------------------------------------
async function startCompiler() {
  const core = name => WebAssembly.compileStreaming(fetch(new URL(`typst-wasm/engine/${name}`, VENDOR)));
  const ourPackages = new URL("packages", VENDOR).href;
  compiler = await createTypstCompiler({
    // Worker backend when the page is cross-origin isolated (see _headers), JSPI otherwise.
    backend: "auto",
    worker: () => createWebWorker(new URL("typst-wasm/worker/web-worker.js", VENDOR)),
    coreModules: { "engine.core.wasm": core("engine.core.wasm"), "engine.core2.wasm": core("engine.core2.wasm"), "engine.core3.wasm": core("engine.core3.wasm") },
    packageBaseUrl: ourPackages,
    // Packages the site uses are mirrored next to the editor at build time;
    // anything else comes from the official registry.
    fetch: async (url, init) => {
      const r = await fetch(url, init);
      if (r.ok || !String(url).startsWith(ourPackages)) return r;
      return fetch(String(url).replace(ourPackages, OFFICIAL_PACKAGES), init);
    },
  });
  const fonts = ["NewCM10-Regular.otf", "NewCM10-Italic.otf", "NewCM10-Bold.otf", "NewCM10-BoldItalic.otf", "NewCMMath-Regular.otf", "DejaVuSansMono.ttf"];
  await compiler.addFonts(...fonts.map(f => fetch(new URL("fonts/" + f, VENDOR)).then(r => r.arrayBuffer()).then(b => new Uint8Array(b))));
  for (const path of files.keys()) if (files.get(path).loaded) await pushToCompiler(path);
}

async function pushToCompiler(path) {
  const f = files.get(path);
  if (f.text !== undefined) await compiler.addSource(path, path === current && view ? view.state.doc.toString() : f.text);
  else if (f.bytes) await compiler.addFile(path, f.bytes);
}

function scheduleCompile(delay = 250) { clearTimeout(compileTimer); compileTimer = setTimeout(compile, delay); }

async function compile() {
  if (!compiler || !current) return;
  const seq = ++compileSeq, t0 = performance.now();
  await compiler.addSource(current, view.state.doc.toString());
  let result;
  try {
    result = await compiler.compile({ format: "html", main: current, inputs: { preview: "true" } });
  } catch (e) {
    if (seq === compileSeq) showDiagnostics(e.diagnostics || [{ severity: "error", message: e.message }]);
    return;
  }
  if (seq !== compileSeq) return;
  showDiagnostics(result.diagnostics);
  showPreview(fixMathML(result.output));
  if (!isDirty()) setStatus(`Compiled in ${Math.round(performance.now() - t0)} ms`);
}

function showPreview(html) {
  const win = ui.preview.contentWindow, y = win ? win.scrollY : 0;
  ui.preview.onload = () => { try { ui.preview.contentWindow.scrollTo(0, y); } catch {} };
  ui.preview.srcdoc = html.replace("<head>", '<head><base target="_blank">');
}

function showDiagnostics(list) {
  list = list.filter(d => !/html export is under active development/.test(d.message));
  ui.diagnostics.replaceChildren(...list.map(d => {
    const li = document.createElement("li");
    li.className = d.severity;
    const where = document.createElement("span");
    where.className = "where";
    where.textContent = d.file ? `${d.file}${d.line ? ":" + d.line : ""}${d.column ? ":" + d.column : ""}` : d.severity;
    li.append(where, d.message + (d.hints && d.hints.length ? "\nhint: " + d.hints.join("\nhint: ") : ""));
    if (d.file === current && d.line) li.addEventListener("click", () => {
      const line = view.state.doc.line(Math.min(d.line, view.state.doc.lines));
      const pos = Math.min(line.from + (d.column ? d.column - 1 : 0), line.to);
      view.dispatch({ selection: { anchor: pos }, scrollIntoView: true }); view.focus();
    });
    return li;
  }));
}

// ---- editor ------------------------------------------------------------------
const isDirty = () => current && view && view.state.doc.toString() !== files.get(current).saved;
function refreshDirty() {
  const dirty = isDirty();
  ui.save.disabled = !dirty;
  const opt = [...ui.file.options].find(o => o.value === current);
  if (opt) opt.textContent = (dirty ? "● " : "") + current;
  if (dirty && !/Saving/.test(ui.status.textContent)) setStatus(store.token ? "Unsaved changes" : "Unsaved changes · add a GitHub token to save", "dirty");
}

function urlFor(path) {
  let m;
  if ((m = path.match(/^content\/posts\/\d{4}-\d{2}-\d{2}-(.+)\.typ$/))) return `/blog/${m[1]}/`;
  if ((m = path.match(/^content\/garden\/(.+)\.typ$/))) return `/garden/${m[1]}/`;
  if ((m = path.match(/^content\/pages\/(.+)\.typ$/))) return `/${m[1]}/`;
  return "/";
}

async function open(path) {
  if (!files.has(path)) return;
  setStatus("Opening…");
  const f = await loadFile(path);
  current = path;
  const draft = store.getDraft(path);
  const text = draft !== null && draft !== f.saved ? draft : f.text;
  view.setState(EditorState.create({ doc: text, extensions: extensions() }));
  ui.file.value = path; ui.view.href = urlFor(path);
  if (location.hash.slice(1) !== path) history.replaceState(null, "", "#" + path);
  refreshDirty();
  if (draft !== null && draft !== f.saved) setStatus("Restored unsaved changes from this browser", "dirty");
  scheduleCompile(0);
}

function extensions() {
  return [
    basicSetup, typst(), keymap.of([indentWithTab, { key: "Mod-s", preventDefault: true, run: () => { save(); return true; } }]),
    EditorView.lineWrapping,
    EditorView.updateListener.of(u => {
      if (!u.docChanged) return;
      store.draft(current, isDirty() ? u.state.doc.toString() : undefined);
      refreshDirty(); scheduleCompile();
    }),
  ];
}

function fillFileList() {
  const paths = [...files.keys()].filter(p => p.startsWith("content/") && p.endsWith(".typ")).sort();
  ui.file.replaceChildren(...paths.map(p => { const o = document.createElement("option"); o.value = p; o.textContent = p; return o; }));
}

// ---- dialogs -----------------------------------------------------------------
function openSettings() {
  $("repo-name").textContent = `${REPO.owner}/${REPO.repo}`;
  $("token").value = store.token; $("branch").value = store.branch;
  $("settings-dialog").showModal();
}
$("settings-dialog").addEventListener("close", async () => {
  const v = $("settings-dialog").returnValue;
  if (v === "forget") { store.token = ""; setStatus("Token removed from this browser"); }
  if (v !== "ok") return;
  const branchChanged = $("branch").value.trim() !== store.branch;
  store.token = $("token").value.trim(); store.branch = $("branch").value.trim() || "main";
  if (branchChanged) location.reload(); else refreshDirty();
});

const TEMPLATES = {
  note: (t) => `#import "/lib/note.typ": note\n#import "/lib/links.typ": n\n\n#show: note.with(\n  title: [${t}],\n  summary: "",\n  status: "seedling",\n  tags: (),\n)\n\n`,
  post: (t) => `#import "/lib/post.typ": post\n#import "/lib/links.typ": n\n#import "/lib/figures.typ": diagram-frame\n\n#show: post.with(\n  title: [${t}],\n  summary: "",\n  tags: (),\n)\n\n`,
  page: (t) => `#import "/lib/page.typ": page\n\n#show: page.with(title: [${t}])\n\n`,
};
$("new").addEventListener("click", () => { $("new-title").value = ""; $("new-slug").value = ""; $("new-dialog").showModal(); });
$("new-title").addEventListener("input", () => {
  $("new-slug").value = $("new-title").value.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
});
$("new-dialog").addEventListener("close", async () => {
  if ($("new-dialog").returnValue !== "ok") return;
  const kind = $("new-kind").value, slug = $("new-slug").value, title = $("new-title").value.replace(/[\[\]]/g, "");
  if (!/^[a-z0-9][a-z0-9-]*$/.test(slug)) { setStatus("Slug must be lowercase letters, digits and dashes", "error"); return; }
  const today = new Date().toISOString().slice(0, 10);
  const path = kind === "post" ? `content/posts/${today}-${slug}.typ` : kind === "note" ? `content/garden/${slug}.typ` : `content/pages/${slug}.typ`;
  if (files.has(path)) { open(path); return; }
  files.set(path, { sha: null, text: "", saved: "", loaded: true });
  store.draft(path, TEMPLATES[kind](title));
  fillFileList(); await open(path);
  view.dispatch({ selection: { anchor: view.state.doc.length } }); view.focus();
});

// ---- start -------------------------------------------------------------------
$("settings").addEventListener("click", openSettings);
ui.save.addEventListener("click", save);
ui.file.addEventListener("change", () => open(ui.file.value));
window.addEventListener("hashchange", () => { const p = decodeURIComponent(location.hash.slice(1)); if (p && p !== current) open(p); });
window.addEventListener("beforeunload", e => { if (isDirty()) e.preventDefault(); });

(async () => {
  view = new EditorView({ parent: $("editor"), state: EditorState.create({ doc: "", extensions: [basicSetup] }) });
  try {
    setStatus("Reading the repository…");
    await loadTree();
  } catch (e) {
    setStatus(e.status === 404 || e.status === 401 ? "Can't read the repository: add a GitHub token (⚙)" : "Can't reach GitHub: " + e.message, "error");
    if (e.status === 404 || e.status === 401) openSettings();
    return;
  }
  fillFileList();
  // Templates and data are small and needed by every page; load them up front.
  await Promise.all([...files.keys()].filter(p => p.startsWith("lib/") || p.startsWith("data/")).map(loadFile));
  const wanted = decodeURIComponent(location.hash.slice(1));
  const first = files.has(wanted) ? wanted : ui.file.options[0] && ui.file.options[0].value;
  if (first) await open(first);
  setStatus("Starting the Typst compiler (first visit downloads about 10 MB)…");
  try { await startCompiler(); } catch (e) { setStatus("Typst compiler failed to start: " + e.message, "error"); return; }
  scheduleCompile(0);
})();
