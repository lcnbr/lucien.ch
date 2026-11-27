// Tinymist (the Typst language server) running in the browser, for the editor.
//
// The WASM build of tinymist sees only files it is told about as open
// documents, so this worker opens every site source and the Typst packages the
// site uses before handing the connection to the editor. It speaks JSON-RPC
// with @codemirror/lsp-client over postMessage:
//   main -> worker  { setup: { files: [{ path, text }], packages: [url], wasm: url } }
//   main -> worker  { rpc: "<json-rpc message>" }
//   worker -> main  { rpc: "<json-rpc message>" } | { status, error? }
import { parseTarGzip } from "./vendor/nanotar/index.mjs";

const ROOT = "file:///site/";              // the site's sources
const PKG = "/@packages";                  // where packages are mounted
const TEXT = /\.(typ|toml|csv|json|ya?ml|bib|txt|xml|svg|tsv)$/i;

let server = null, ready = false;
const queue = [];                          // client messages before setup is done
const events = [];
const openDocs = new Map();                // uri -> version
const packages = new Set();                // "ns/name/version"
let setupFiles = [], packageFiles = [];
let drainScheduled = false;

const post = msg => self.postMessage(msg);
const send = obj => post({ rpc: JSON.stringify(obj) });

// The server asks us to run its internal events outside the current call.
function scheduleDrain() {
  if (drainScheduled) return;
  drainScheduled = true;
  setTimeout(() => {
    drainScheduled = false;
    while (events.length) server.on_event(events.shift());
  }, 0);
}

const isLspError = v => v && typeof v === "object" && typeof v.code === "number" && typeof v.message === "string" && !("result" in v);

function notify(method, params) {
  server.on_notification(method, params);
  scheduleDrain();
}

function openDoc(uri, text) {
  if (openDocs.has(uri)) {
    const version = openDocs.get(uri) + 1;
    openDocs.set(uri, version);
    notify("textDocument/didChange", { textDocument: { uri, version }, contentChanges: [{ text }] });
  } else {
    openDocs.set(uri, 0);
    notify("textDocument/didOpen", { textDocument: { uri, languageId: "typst", version: 0, text } });
  }
}

async function handleClient(raw) {
  const msg = JSON.parse(raw);
  const { method, params, id } = msg;
  if (method === undefined) { server.on_response(msg); scheduleDrain(); return; } // reply to a server request
  if (id === undefined) {
    // Keep every file open: tinymist reads imports only from open documents,
    // so the editor's file stays visible after switching to another one.
    if (method === "textDocument/didClose") return;
    if (method === "textDocument/didOpen") { openDoc(params.textDocument.uri, params.textDocument.text); return; }
    if (method === "textDocument/didChange") openDocs.set(params.textDocument.uri, params.textDocument.version);
    notify(method, params);
    if (method === "initialized") openProject();
    return;
  }
  let result;
  try {
    result = await Promise.resolve(server.on_request(method, params));
  } catch (e) {
    send({ jsonrpc: "2.0", id, error: { code: -32603, message: String(e && e.message || e) } });
    return;
  } finally { scheduleDrain(); }
  // @codemirror/lsp-client follows plain Locations, tinymist answers with
  // LocationLinks: convert them.
  if (Array.isArray(result) && /^textDocument\/(definition|declaration|typeDefinition|implementation)$/.test(method))
    result = result.map(l => l.targetUri ? { uri: l.targetUri, range: l.targetSelectionRange || l.targetRange } : l);
  if (isLspError(result)) send({ jsonrpc: "2.0", id, error: result });
  else send({ jsonrpc: "2.0", id, result: result === undefined ? null : result });
}

function openProject() {
  for (const f of packageFiles) openDoc("file://" + f.path, f.text);
  for (const f of setupFiles) openDoc(ROOT + f.path, f.text);
  post({ status: "ready", files: setupFiles.length, packages: packages.size });
}

async function fetchBytes(url) {
  let r = await fetch(url);
  let wrapped = null;
  if (!r.ok) for (const alt of [".gz", ".gz.json", ".json"]) {
    const a = await fetch(url + alt).catch(() => null);
    if (a && a.ok) { r = a; wrapped = alt; break; }
  }
  if (!r.ok) throw new Error(`${url}: ${r.status}`);
  let bytes = wrapped && wrapped.endsWith(".json")
    ? Uint8Array.from(atob((await r.json()).base64), c => c.charCodeAt(0))
    : new Uint8Array(await r.arrayBuffer());
  if (!/\.tar\.gz$/.test(url) && bytes[0] === 0x1f && bytes[1] === 0x8b)
    bytes = new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"))).arrayBuffer());
  return bytes;
}

async function loadPackage(url) {
  // .../packages/<ns>/<name>-<version>.tar.gz
  const m = url.match(/\/packages\/([^/]+)\/(.+)-(\d+\.\d+\.\d+)\.tar\.gz$/);
  if (!m) return;
  const [, ns, name, version] = m;
  const entries = await parseTarGzip(await fetchBytes(url));
  const dec = new TextDecoder();
  for (const e of entries) {
    if (e.type && e.type !== "file") continue;
    const rel = e.name.replace(/^\.?\//, "");
    if (!TEXT.test(rel) || !e.data) continue;
    packageFiles.push({ path: `${PKG}/${ns}/${name}/${version}/${rel}`, text: dec.decode(e.data) });
  }
  packages.add(`${ns}/${name}/${version}`);
}

async function setup({ files, packages: pkgUrls, wasm }) {
  setupFiles = files;
  post({ status: "loading" });
  const [{ default: init, TinymistLanguageServer }, bytes] = await Promise.all([
    import("./vendor/tinymist/tinymist.js"),
    fetchBytes(wasm),
    ...pkgUrls.map(u => loadPackage(u).catch(e => console.warn("[lsp] package", u, e))),
  ]);
  await init({ module_or_path: bytes });
  server = new TinymistLanguageServer({
    sendEvent: e => { events.push(e); scheduleDrain(); },
    sendRequest: req => {
      // Answer the server's own requests here (configuration, capability
      // registration, progress); the editor doesn't need them.
      setTimeout(() => {
        let result = null;
        if (req.method === "workspace/configuration")
          result = ((req.params && req.params.items) || []).map(() => ({ exportPdf: "never", lint: { enabled: false } }));
        server.on_response({ id: req.id, result });
        scheduleDrain();
      }, 0);
    },
    sendNotification: n => {
      // The editor shows the real compiler's errors; drop tinymist's own.
      if (n.method === "textDocument/publishDiagnostics" || n.method.startsWith("window/") || n.method.startsWith("$/") || n.method.startsWith("tinymist/")) return;
      send({ jsonrpc: "2.0", method: n.method, params: n.params });
    },
    resolveFn: spec => packages.has(`${spec.namespace}/${spec.name}/${spec.version}`)
      ? `${PKG}/${spec.namespace}/${spec.name}/${spec.version}` : undefined,
  });
  ready = true;
  while (queue.length) await handleClient(queue.shift());
}

self.onmessage = async ({ data }) => {
  try {
    if (data.setup) await setup(data.setup);
    else if (data.update) { const f = data.update; if (ready) openDoc(ROOT + f.path, f.text); else setupFiles.push(f); }
    else if (data.rpc !== undefined) { if (ready) await handleClient(data.rpc); else queue.push(data.rpc); }
  } catch (e) {
    console.error("[lsp]", e);
    post({ status: "error", error: String(e && e.message || e) });
  }
};
