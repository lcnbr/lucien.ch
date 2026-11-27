// Cloudflare Pages Function: cross-origin isolation for pages, on request.
//
// The browser editor compiles in a worker only when the page is
// cross-origin isolated (COOP + COEP). Isolation also blocks third-party
// iframes such as the giscus comments, so readers get pages without it.
// assets/edit.js sets the `edit=1` cookie and reloads when the editor is
// docked on a page; while that cookie is set, pages are served isolated.
// /edit/ itself is always isolated through dist/_headers.
// (The drafts site uses its own _worker.js, which replaces this.)
export async function onRequest({ request, next }) {
  const res = await next();
  const out = new Response(res.body, res);
  // The same URL answers differently with and without the cookie.
  out.headers.append("Vary", "Cookie");
  if (/(?:^|;\s*)edit=1(?:;|$)/.test(request.headers.get("Cookie") || "")) {
    out.headers.set("Cross-Origin-Opener-Policy", "same-origin");
    out.headers.set("Cross-Origin-Embedder-Policy", "require-corp");
  }
  return out;
}
