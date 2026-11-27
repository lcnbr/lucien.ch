// lucien.ch browser editor.
//
// Loads the site's Typst sources from GitHub, compiles the open page to HTML
// in the browser with typst-wasm (same Typst version and templates as the real
// build), shows it beside the source, and commits changes back to GitHub with
// a fine-grained token kept in this browser.
import {
  EditorView, EditorState, basicSetup, keymap, indentWithTab, typst, typstTags,
  HighlightStyle, syntaxHighlighting, tags as t, setDiagnostics, lintGutter,
} from "./vendor/codemirror.js";
import { createTypstCompiler } from "typst-wasm";
import { createWebWorker } from "typst-wasm/worker/browser";
import { fixMathML } from "./mathml-fix.js";

const REPO = { owner: "lcnbr", repo: "lucien.ch" };
const SOURCE_DIRS = ["content/", "lib/", "data/"];
const TEXT_EXT = /\.(typ|csv|json|toml|ya?ml|bib|txt|md|svg|xml)$/i;
const VENDOR = new URL("./vendor/", import.meta.url);
const OFFICIAL_PACKAGES = "https://packages.typst.org";
let BUILD = { branch: "main" };
const store = {
  get token() { try { return localStorage.getItem("edit.token") || ""; } catch { return ""; } },
  set token(v) { try { v ? localStorage.setItem("edit.token", v) : localStorage.removeItem("edit.token"); } catch {} },
  // Default: the branch this site was built from (edit/build.json).
  get branch() { try { return localStorage.getItem("edit.branch") || BUILD.branch; } catch { return BUILD.branch; } },
  set branch(v) { try { !v || v === BUILD.branch ? localStorage.removeItem("edit.branch") : localStorage.setItem("edit.branch", v); } catch {} },
  draft(path, text) {
    try { text === undefined ? localStorage.removeItem("edit.draft:" + path) : localStorage.setItem("edit.draft:" + path, text); } catch {}
  },
  getDraft(path) { try { return localStorage.getItem("edit.draft:" + path); } catch { return null; } },
};

const $ = id => document.getElementById(id);
// Embedded mode (#!path): the editor runs in a panel docked on the page itself
// (see assets/edit.js) and sends each compiled page to it instead of showing it.
const EMBED = location.hash.startsWith("#!");
const HASH = EMBED ? "#!" : "#";
const hashPath = () => decodeURIComponent(location.hash.slice(HASH.length));
const toHost = msg => { try { window.parent.postMessage({ source: "lucien-edit", ...msg }, "*"); } catch {} };
if (EMBED) document.body.classList.add("embed");
const ui = {
  file: $("file"), save: $("save"), status: $("status"), view: $("view"),
  preview: $("preview"), diagnostics: $("diagnostics"),
};

// path -> { sha, text?, bytes?, loaded, saved (text as on GitHub) }
const files = new Map();
let compiled = false; // has the preview shown a compile yet?
let ready = false;    // compiler started and every loaded source handed to it
let current = null, compiler = null, view = null, compileTimer = 0, compileSeq = 0;

function setStatus(text, kind = "") { ui.status.textContent = text; ui.status.className = "status " + kind; }

// Startup steps: shown in the status line, timed in the console, and flagged
// when one takes unusually long, so a stall says where it is.
let stage = "", stageT0 = 0, stageNote = "";
function step(label, note = "") {
  const now = performance.now();
  if (stage) console.info(`[edit] ${stage}: ${Math.round(now - stageT0)} ms`);
  const wasShowing = stage && ui.status.textContent.startsWith(stage);
  stage = label; stageT0 = now; stageNote = note;
  if (label) setStatus(label + (note ? " " + note : "") + "…", "busy");
  else if (wasShowing) setStatus(compiled ? "Ready" : "Waiting for the page…", compiled ? "" : "busy");
}
setInterval(() => {
  if (!stage) return;
  const s = Math.round((performance.now() - stageT0) / 1000);
  if (s >= 15) setStatus(`${stage}${stageNote ? " " + stageNote : ""}… still waiting after ${s} s (details in the browser console)`, "busy");
}, 1000);
const backendName = () => (typeof SharedArrayBuffer !== "undefined" && self.crossOriginIsolated) ? "worker" : (typeof WebAssembly.Suspending === "function" ? "JSPI" : "none");

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
  if (!tree.some(e => e.path.startsWith("content/") && e.path.endsWith(".typ")))
    throw new Error(`branch "${store.branch}" has no pages in content/ yet`);
  for (const e of tree) files.set(e.path, { sha: e.sha, loaded: false });
}

// Fallback when GitHub is unreachable (offline, or a sandboxed preview):
// the sources as of the last build, written by build.py. Read-only.
let snapshot = null;
async function loadSnapshot() {
  const r = await fetch(new URL("./snapshot.json", import.meta.url));
  if (!r.ok) throw new Error("no snapshot");
  snapshot = await r.json();
  for (const [path, v] of Object.entries(snapshot.files)) {
    const f = { loaded: true };
    if (typeof v === "string") { f.text = v; f.saved = v; }
    else f.bytes = Uint8Array.from(atob(v.base64), c => c.charCodeAt(0));
    files.set(path, f);
  }
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
  if (snapshot) { setStatus("Saving needs GitHub; this copy can't reach it. Edits stay in this browser.", "error"); return; }
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
// Hosts with file-size or file-type limits get the same bytes in another
// wrapper: <file>.gz (gzip) or <file>.json ({"base64": …}, maybe of the .gz).
async function fetchWrapped(url, init) {
  let r = await fetch(url, init);
  if (r.ok) return r;
  for (const alt of [url + ".gz", url + ".gz.json", url + ".json"]) {
    const a = await fetch(alt, init).catch(() => null);
    if (!a || !a.ok) continue;
    let bytes = alt.endsWith(".json")
      ? Uint8Array.from(atob((await a.json()).base64), c => c.charCodeAt(0))
      : new Uint8Array(await a.arrayBuffer());
    // Un-gzip unless the file is itself a gzip archive (.tar.gz) or the host already did.
    if (alt.includes(".gz") && !/\.tar\.gz$/.test(url) && bytes[0] === 0x1f && bytes[1] === 0x8b)
      bytes = new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"))).arrayBuffer());
    return new Response(bytes, { status: 200 });
  }
  return r;
}

async function loadWasm(url, onBytes) {
  let r = await fetchWrapped(url);
  if (!r.ok) throw new Error(`can't load ${url}: ${r.status}`);
  if (onBytes && r.body) {
    let n = 0;
    const counted = r.body.pipeThrough(new TransformStream({ transform(chunk, c) { n += chunk.byteLength; onBytes(n); c.enqueue(chunk); } }));
    r = new Response(counted, { headers: { "content-type": r.headers.get("content-type") || "" } });
  }
  if (/wasm/.test(r.headers.get("content-type") || "")) return WebAssembly.compileStreaming(r);
  return WebAssembly.compile(await r.arrayBuffer());
}
async function startCompiler() {
  step("Downloading the Typst compiler");
  console.info(`[edit] backend: ${backendName()}, cross-origin isolated: ${self.crossOriginIsolated}`);
  const progress = n => { if (stage.startsWith("Downloading")) { stageNote = `(${(n / 1e6).toFixed(1)} MB)`; if (performance.now() - stageT0 < 15000) setStatus(`${stage} ${stageNote}…`, "busy"); } };
  const core = name => loadWasm(new URL(`typst-wasm/engine/${name}`, VENDOR).href, name === "engine.core.wasm" ? progress : null)
    .then(m => { if (name === "engine.core.wasm") step("Starting the Typst compiler", `(${backendName()})`); return m; });
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
      if (!String(url).startsWith(ourPackages)) return fetch(url, init);
      const r = await fetchWrapped(String(url), init);
      if (r.ok) return r;
      return fetch(String(url).replace(ourPackages, OFFICIAL_PACKAGES), init);
    },
  });
  step("Loading fonts");
  const fonts = ["NewCM10-Regular.otf", "NewCM10-Italic.otf", "NewCM10-Bold.otf", "NewCM10-BoldItalic.otf", "NewCMMath-Regular.otf", "DejaVuSansMono.ttf"];
  await compiler.addFonts(...fonts.map(f => fetch(new URL("fonts/" + f, VENDOR)).then(r => r.arrayBuffer()).then(b => new Uint8Array(b))));
  for (const path of files.keys()) if (files.get(path).loaded) await pushToCompiler(path);
  step("");
}

// ---- labels on other pages ---------------------------------------------------
// The preview compiles one page, so labels defined on other pages (equations,
// figures, page slugs) don't exist and #link(<x>) / @x to them fail. Hidden
// placeholders for those labels let the page compile; references to them read
// "Equation ?" since the number lives on the other page.
let otherPages = {}; // content path -> source, from the built copy
async function loadLabelIndex() {
  try {
    const j = snapshot || await (await fetch(new URL("./snapshot.json", import.meta.url))).json();
    for (const [p, v] of Object.entries(j.files)) if (p.startsWith("content/") && typeof v === "string") otherPages[p] = v;
  } catch {}
}
const LABEL = /<([\p{L}\p{N}_:.-]+)>/gu;
// Labels a source defines: `<x>` not used as an argument, i.e. not after "(" or ",".
function labelsDefined(text) {
  const out = new Map();
  for (const m of text.matchAll(LABEL)) {
    const before = text.slice(Math.max(0, m.index - 400), m.index).trimEnd();
    const c = before.slice(-1);
    if (c === "(" || c === ",") continue;
    out.set(m[1], c === "$" ? "Equation" : /#figure\(/.test(before) && (c === ")" || c === "]") ? "Figure" : "Section");
  }
  return out;
}
function slugOf(path) {
  const m = path.match(/^content\/(?:posts\/\d{4}-\d{2}-\d{2}-|garden\/|pages\/)(.+)\.typ$/);
  return m && m[1];
}
function withLabelStubs(path, text) {
  const own = labelsDefined(text);
  const used = new Set([...text.matchAll(LABEL)].map(m => m[1]));
  for (const m of text.matchAll(/@([\p{L}\p{N}_:.-]+)/gu)) used.add(m[1].replace(/[.:]+$/, ""));
  const elsewhere = new Map();
  for (const [p, src] of Object.entries(otherPages)) {
    if (p === path) continue;
    const slug = slugOf(p); if (slug) elsewhere.set(slug, "Page");
    for (const [l, kind] of labelsDefined(src)) elsewhere.set(l, kind);
  }
  const stubs = [...used].filter(l => !own.has(l) && elsewhere.has(l));
  if (!stubs.length) return text;
  return text + "\n#html.div(hidden: true)[" + stubs.map(l =>
    `#figure(kind: "preview-stub", supplement: [${elsewhere.get(l)}], numbering: _ => "?", []) <${l}>`).join(" ") + "]\n";
}

async function pushToCompiler(path) {
  const f = files.get(path);
  if (f.text !== undefined) await compiler.addSource(path, path === current && view ? withLabelStubs(path, view.state.doc.toString()) : f.text);
  else if (f.bytes) await compiler.addFile(path, f.bytes);
}

function scheduleCompile(delay = 250) { clearTimeout(compileTimer); compileTimer = setTimeout(compile, delay); }

async function compile() {
  if (!ready || !current) return;
  const seq = ++compileSeq, t0 = performance.now();
  if (!compiled) step("Compiling the page");
  await compiler.addSource(current, withLabelStubs(current, view.state.doc.toString()));
  let result;
  try {
    result = await compiler.compile({ format: "html", main: current, inputs: { preview: "true" } });
  } catch (e) {
    if (!compiled) step("");
    if (seq === compileSeq) { showDiagnostics(e.diagnostics || [{ severity: "error", message: e.message }]); setStatus("The page has errors (see below)", "error"); }
    return;
  }
  if (seq !== compileSeq) return;
  showDiagnostics(result.diagnostics);
  if (!compiled) step("");
  showPreview(fixMathML(result.output)); compiled = true;
  if (!isDirty()) setStatus(`Compiled in ${Math.round(performance.now() - t0)} ms`);
}

function showPreview(html) {
  if (EMBED) { toHost({ type: "preview", html }); return; }
  let y = 0;
  try { y = ui.preview.contentWindow.scrollY; } catch {} // a page the browser won't let us read
  ui.preview.onload = () => { try { ui.preview.contentWindow.scrollTo(0, y); } catch {} };
  // Site-absolute paths (/assets/style.css, /blog/…) resolve from the site root,
  // which is the editor's parent directory, wherever the site is served from.
  const root = new URL("../", import.meta.url).href;
  ui.preview.srcdoc = html.replace("<head>", '<head><base target="_blank">')
    .replace(/(\s(?:href|src))="\/(?!\/)/g, `$1="${root}`);
}

function showDiagnostics(list) {
  list = list.filter(d => !/html export is under active development/.test(d.message));
  if (view && current) {
    const doc = view.state.doc, marks = [];
    for (const d of list) {
      if (d.file !== current || !d.line || d.line > doc.lines) continue;
      const line = doc.line(d.line), from = Math.min(line.from + Math.max((d.column || 1) - 1, 0), line.to);
      const word = /^[\p{L}\p{N}_.-]+/u.exec(doc.sliceString(from, line.to));
      marks.push({ from, to: Math.max(from + (word ? word[0].length : 1), from), severity: d.severity === "warning" ? "warning" : "error",
        message: d.message + (d.hints && d.hints.length ? "\nhint: " + d.hints.join("\nhint: ") : "") });
    }
    view.dispatch(setDiagnostics(view.state, marks.map(m => ({ ...m, to: Math.min(m.to, doc.length) }))));
  }
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
const editorTheme = EditorView.theme({
  "&": { height: "100%", fontSize: "13.5px", backgroundColor: "var(--panel)", color: "var(--fg)" },
  ".cm-scroller": { fontFamily: "var(--mono)", lineHeight: "1.7" },
  ".cm-content": { padding: "14px 0 40vh", caretColor: "var(--accent)" },
  ".cm-line": { padding: "0 20px 0 8px" },
  ".cm-gutters": { backgroundColor: "var(--panel)", color: "var(--ed-gutter)", border: "none", paddingLeft: "6px" },
  ".cm-lineNumbers .cm-gutterElement": { minWidth: "28px", fontVariantNumeric: "tabular-nums" },
  ".cm-activeLine": { backgroundColor: "var(--ed-active)" },
  ".cm-activeLineGutter": { backgroundColor: "transparent", color: "var(--fg)" },
  "&.cm-focused": { outline: "none" },
  ".cm-cursor, .cm-dropCursor": { borderLeft: "2px solid var(--accent)" },
  "&.cm-focused > .cm-scroller > .cm-selectionLayer .cm-selectionBackground, .cm-selectionBackground, .cm-content ::selection": { backgroundColor: "var(--ed-sel) !important" },
  ".cm-matchingBracket": { backgroundColor: "var(--ed-sel)", outline: "none" },
  ".cm-foldPlaceholder": { backgroundColor: "var(--ed-active)", border: "none", color: "var(--muted)", padding: "0 6px", borderRadius: "4px" },
  ".cm-tooltip": { backgroundColor: "var(--panel)", color: "var(--fg)", border: "1px solid var(--rule)", borderRadius: "8px", boxShadow: "0 10px 30px rgb(0 0 0 / 0.15)", overflow: "hidden" },
  ".cm-tooltip.cm-tooltip-autocomplete > ul": { fontFamily: "var(--mono)", maxHeight: "16em" },
  ".cm-tooltip.cm-tooltip-autocomplete > ul > li": { padding: "3px 10px" },
  ".cm-tooltip.cm-tooltip-autocomplete > ul > li[aria-selected]": { backgroundColor: "var(--accent)", color: "var(--accent-fg)" },
  ".cm-completionDetail": { color: "var(--muted)", fontStyle: "normal", marginLeft: "1em" },
  ".cm-panels": { backgroundColor: "var(--bar)", color: "var(--fg)" },
  ".cm-panels.cm-panels-bottom": { borderTop: "1px solid var(--rule)" },
  ".cm-searchMatch": { backgroundColor: "rgb(255 200 0 / 0.25)" },
  ".cm-diagnostic": { fontFamily: "system-ui, sans-serif", padding: "6px 10px", whiteSpace: "pre-wrap" },
  ".cm-lintRange-error": { backgroundImage: "none", textDecoration: "underline wavy var(--error)", textUnderlineOffset: "3px" },
  ".cm-lintRange-warning": { backgroundImage: "none", textDecoration: "underline wavy var(--warning)", textUnderlineOffset: "3px" },
});
const typstColours = syntaxHighlighting(HighlightStyle.define([
  { tag: t.comment, color: "var(--hl-comment)", fontStyle: "italic" },
  { tag: [t.keyword, t.bool, t.null, t.atom], color: "var(--hl-keyword)" },
  { tag: t.function(t.variableName), color: "var(--hl-func)" },
  { tag: t.string, color: "var(--hl-string)" },
  { tag: t.number, color: "var(--hl-number)" },
  { tag: [typstTags.mathDelimiter, t.escape, t.labelName], color: "var(--hl-math)" },
  { tag: [typstTags.interpolated, t.propertyName], color: "var(--hl-interp)" },
  { tag: typstTags.listMarker, color: "var(--hl-keyword)", fontWeight: "600" },
  { tag: [t.operator, t.punctuation, t.paren], color: "var(--hl-op)" },
  { tag: t.heading, fontWeight: "700", color: "var(--fg)" },
  { tag: t.strong, fontWeight: "700" },
  { tag: t.emphasis, fontStyle: "italic" },
  { tag: t.link, color: "var(--accent)", textDecoration: "underline" },
  { tag: t.monospace, color: "var(--muted)" },
  { tag: t.invalid, color: "var(--error)" },
]));

const isDirty = () => current && view && view.state.doc.toString() !== files.get(current).saved;
function refreshDirty() {
  const dirty = isDirty();
  ui.save.disabled = !dirty;
  const opt = [...ui.file.options].find(o => o.value === current);
  if (opt) opt.textContent = (dirty ? "● " : "") + current;
  if (dirty && !/Saving/.test(ui.status.textContent)) setStatus(snapshot ? "Edited · preview only, kept in this browser" : store.token ? "Unsaved changes" : "Unsaved changes · add a GitHub token to save", "dirty");
}

// A site path as a link from here; adds index.html where the host needs it
// (i.e. when this page itself was opened as …/index.html).
function siteHref(p) {
  const u = new URL(p.replace(/^\//, ""), new URL("../", import.meta.url));
  if (/\/index\.html$/.test(location.pathname) && u.pathname.endsWith("/")) u.pathname += "index.html";
  return u.href;
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
  setStatus("Opening…", "busy");
  const f = await loadFile(path);
  current = path;
  const draft = store.getDraft(path);
  const text = draft !== null && draft !== f.saved ? draft : f.text;
  view.setState(EditorState.create({ doc: text, extensions: extensions() }));
  ui.file.value = path; ui.view.href = siteHref(urlFor(path));
  if (!EMBED && !compiled && files.get(path).sha !== null) ui.preview.src = siteHref(urlFor(path));
  if (hashPath() !== path) history.replaceState(null, "", HASH + path);
  refreshDirty();
  if (draft !== null && draft !== f.saved) setStatus("Restored unsaved changes from this browser", "dirty");
  scheduleCompile(0);
}

function extensions() {
  return [
    basicSetup, typst(), editorTheme, typstColours, lintGutter(), keymap.of([indentWithTab, { key: "Mod-s", preventDefault: true, run: () => { save(); return true; } }]),
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
  store.token = $("token").value.trim(); store.branch = $("branch").value.trim() || BUILD.branch;
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

// ---- panel -------------------------------------------------------------------
const PANEL_KEY = "edit.panelWidth";
function setPanel(open) {
  if (EMBED) { if (!open) toHost({ type: "close" }); return; }
  document.body.classList.toggle("closed", !open);
  if (open && view) requestAnimationFrame(() => view.focus());
}
$("close").addEventListener("click", () => setPanel(false));
$("reopen").addEventListener("click", () => setPanel(true));
document.addEventListener("keydown", e => {
  if (e.key === "Escape" && !document.querySelector("dialog[open]") && !document.querySelector(".cm-tooltip-autocomplete, .cm-search")) setPanel(false);
  if ((e.key === "e" || e.key === "E") && (e.metaKey || e.ctrlKey) && e.shiftKey) { e.preventDefault(); setPanel(document.body.classList.contains("closed")); }
});
try { const w = localStorage.getItem(PANEL_KEY); if (w) document.documentElement.style.setProperty("--panel-w", w); } catch {}
{
  const handle = $("resizer");
  const widthAt = x => Math.round(Math.min(Math.max(window.innerWidth - x, 340), window.innerWidth - 240)) + "px";
  const apply = w => { document.documentElement.style.setProperty("--panel-w", w); try { localStorage.setItem(PANEL_KEY, w); } catch {} };
  handle.addEventListener("pointerdown", e => {
    handle.setPointerCapture(e.pointerId); document.body.classList.add("resizing");
    const move = ev => apply(widthAt(ev.clientX));
    const up = () => { document.body.classList.remove("resizing"); handle.removeEventListener("pointermove", move); handle.removeEventListener("pointerup", up); };
    handle.addEventListener("pointermove", move); handle.addEventListener("pointerup", up);
  });
  handle.addEventListener("keydown", e => {
    if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
    const w = $("panel").getBoundingClientRect().width + (e.key === "ArrowLeft" ? 40 : -40);
    apply(widthAt(window.innerWidth - w)); e.preventDefault();
  });
}

// ---- start -------------------------------------------------------------------
$("settings").addEventListener("click", openSettings);
ui.save.addEventListener("click", save);
ui.file.addEventListener("change", () => open(ui.file.value));
window.addEventListener("hashchange", () => { const p = hashPath(); if (p && p !== current) open(p); });
window.addEventListener("beforeunload", e => { if (isDirty()) e.preventDefault(); });

(async () => {
  view = new EditorView({ parent: $("editor"), state: EditorState.create({ doc: "", extensions: [basicSetup, editorTheme] }) });
  // Download and start the compiler while the sources load.
  const compilerReady = startCompiler().then(() => true, e => {
    step(""); console.error("[edit] compiler failed to start", e);
    setStatus("Typst compiler failed to start: " + e.message + (backendName() === "none" ? " (this browser lacks the features it needs; try a recent Chrome, Edge or Firefox)" : ""), "error");
    return false;
  });
  try { const r = await fetch(new URL("./build.json", import.meta.url)); if (r.ok) BUILD = { ...BUILD, ...(await r.json()) }; } catch {}
  let fallbackReason = "";
  try {
    if (!stage) setStatus("Reading the repository…", "busy");
    await loadTree();
  } catch (e) {
    files.clear();
    fallbackReason = e.message;
    console.warn("[edit] can't use GitHub, using the built-in copy:", e);
    try { await loadSnapshot(); }
    catch {
      setStatus(e.status === 404 || e.status === 401 ? "Can't read the repository: add a GitHub token (⚙)" : "Can't reach GitHub: " + e.message, "error");
      if (e.status === 404 || e.status === 401) openSettings();
      return;
    }
  }
  fillFileList();
  // Templates and data are small and needed by every page; load them up front.
  await Promise.all([...files.keys()].filter(p => p.startsWith("lib/") || p.startsWith("data/")).map(loadFile));
  const wanted = hashPath();
  const first = files.has(wanted) ? wanted : ui.file.options[0] && ui.file.options[0].value;
  if (!first) { step(""); setStatus(`No pages to edit on branch "${store.branch}" (change it under ⚙)`, "error"); return; }
  await open(first);
  if (wanted && wanted !== first) console.warn(`[edit] ${wanted} isn't on branch ${store.branch}; opened ${first}`);
  await loadLabelIndex();
  if (!(await compilerReady)) return;
  for (const path of files.keys()) if (files.get(path).loaded) await pushToCompiler(path);
  ready = true;
  scheduleCompile(0);
  if (snapshot) setTimeout(() => {
    if (!ui.status.classList.contains("error"))
      setStatus(`Built-in copy from ${snapshot.built}${fallbackReason ? " (GitHub: " + fallbackReason + ")" : ""} · edits preview live but can't be saved`);
  }, 1500);
})();
