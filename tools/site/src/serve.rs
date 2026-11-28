//! `cargo site serve [PORT] [--host ADDR] [--dir DIR]`: serve dist/ locally
//! with the isolation headers Cloudflare sends: always on /edit/, and on pages
//! while the edit=1 cookie is set (functions/_middleware.js).

use std::fs;
use std::path::{Component, Path, PathBuf};
use std::sync::Arc;

use anyhow::{anyhow, Result};
use tiny_http::{Header, Request, Response, Server};

const WORKERS: usize = 8;

fn content_type(path: &Path) -> &'static str {
    match path.extension().and_then(|e| e.to_str()).unwrap_or("") {
        "html" => "text/html; charset=utf-8",
        "css" => "text/css; charset=utf-8",
        "js" | "mjs" => "text/javascript; charset=utf-8",
        "json" => "application/json",
        "xml" => "application/xml",
        "txt" => "text/plain; charset=utf-8",
        "wasm" => "application/wasm",
        "svg" => "image/svg+xml",
        "png" => "image/png",
        "jpg" | "jpeg" => "image/jpeg",
        "webp" => "image/webp",
        "gif" => "image/gif",
        "ico" => "image/x-icon",
        "woff2" => "font/woff2",
        "woff" => "font/woff",
        "ttf" => "font/ttf",
        "otf" => "font/otf",
        "pdf" => "application/pdf",
        "gz" => "application/gzip",
        "bib" | "typ" | "csv" => "text/plain; charset=utf-8",
        _ => "application/octet-stream",
    }
}

/// A response header, or None if HTTP can't carry the value (not ASCII).
fn header(k: &str, v: &str) -> Option<Header> {
    Header::from_bytes(k.as_bytes(), v.as_bytes()).ok()
}

/// Where a directory requested without its trailing slash redirects: the path
/// as the client sent it (still percent-encoded) with a "/" added, then the
/// query. Leading slashes collapse to one, so `//blog` can't turn into a link
/// to the host "blog", and anything else unsafe in a header is encoded.
fn redirect_target(raw_path: &str, query: Option<&str>) -> String {
    let to = format!("/{}/{}", raw_path.trim_start_matches('/'), query.map(|q| format!("?{q}")).unwrap_or_default());
    let mut out = String::with_capacity(to.len());
    for b in to.bytes() {
        if b.is_ascii_alphanumeric() || b"-._~!$&'()*+,;=:@/?%".contains(&b) {
            out.push(b as char);
        } else {
            out.push_str(&format!("%{b:02X}"));
        }
    }
    out
}

/// Percent-decode a URL path.
fn decode(path: &str) -> String {
    let hex = |b: u8| (b as char).to_digit(16).map(|d| d as u8);
    let bytes = path.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            if let (Some(h), Some(l)) = (hex(bytes[i + 1]), hex(bytes[i + 2])) {
                out.push(h * 16 + l);
                i += 3;
                continue;
            }
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// The file a URL path names under `dir`, refusing anything outside it.
fn resolve(dir: &Path, url_path: &str) -> Option<PathBuf> {
    let rel = Path::new(url_path.trim_start_matches('/'));
    if rel.components().any(|c| !matches!(c, Component::Normal(_))) {
        return None;
    }
    Some(dir.join(rel))
}

/// The headers every response gets: isolation where the editor needs it, and
/// Vary, since the same URL answers differently with and without the cookie.
fn with_headers<R: std::io::Read>(mut r: Response<R>, isolate: bool) -> Response<R> {
    let mut hs = Vec::new();
    if isolate {
        hs.extend([("Cross-Origin-Opener-Policy", "same-origin"), ("Cross-Origin-Embedder-Policy", "require-corp")]);
    }
    hs.push(("Vary", "Cookie"));
    for h in hs.into_iter().filter_map(|(k, v)| header(k, v)) {
        r.add_header(h);
    }
    r
}

fn handle(dir: &Path, req: Request) -> std::io::Result<()> {
    let url = req.url().to_string();
    let url = url.split('#').next().unwrap_or_default();
    let (raw_path, query) = match url.split_once('?') {
        Some((p, q)) => (p, Some(q)),
        None => (url, None),
    };
    let path = decode(raw_path);
    let cookie_edit = req
        .headers()
        .iter()
        .any(|h| h.field.equiv("Cookie") && h.value.as_str().replace(' ', "").split(';').any(|c| c == "edit=1"));
    let isolate = path.starts_with("/edit/") || cookie_edit;
    let status = |code: u16, text: &str| Response::from_string(format!("{text}\n")).with_status_code(code);
    let not_found = || status(404, "404 Not Found");

    let Some(mut file) = resolve(dir, &path) else { return req.respond(with_headers(not_found(), isolate)) };
    if file.is_dir() {
        if !path.ends_with('/') {
            let r = match header("Location", &redirect_target(raw_path, query)) {
                Some(h) => Response::empty(301).with_header(h).boxed(),
                None => status(400, "400 Bad Request").boxed(),
            };
            return req.respond(with_headers(r, isolate));
        }
        file = file.join("index.html");
    }
    match fs::File::open(&file) {
        Ok(f) if file.is_file() => {
            let mut r = Response::from_file(f);
            if let Some(h) = header("Content-Type", content_type(&file)) {
                r.add_header(h);
            }
            req.respond(with_headers(r, isolate))
        }
        _ => req.respond(with_headers(not_found(), isolate)),
    }
}

/// Serve `dir` on `host:port` until killed.
pub fn run(dir: &Path, host: &str, port: u16) -> Result<()> {
    if !dir.is_dir() {
        return Err(anyhow!("{} does not exist: run `cargo site build` first", dir.display()));
    }
    let server = Arc::new(Server::http((host, port)).map_err(|e| anyhow!("listening on {host} port {port}: {e}"))?);
    // An address for the browser: localhost when listening on all interfaces.
    let shown = match host.parse::<std::net::IpAddr>() {
        Ok(ip) if ip.is_unspecified() => "localhost".to_string(),
        Ok(std::net::IpAddr::V6(ip)) => format!("[{ip}]"),
        _ => host.to_string(),
    };
    println!("serving {} on http://{shown}:{port}/  (editor: http://{shown}:{port}/edit/)", dir.display());
    let workers: Vec<_> = (0..WORKERS)
        .map(|_| {
            let (server, dir) = (server.clone(), dir.to_path_buf());
            std::thread::spawn(move || {
                for req in server.incoming_requests() {
                    if let Err(e) = handle(&dir, req) {
                        eprintln!("serve: {e}");
                    }
                }
            })
        })
        .collect();
    for w in workers {
        let _ = w.join();
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn redirects() {
        assert_eq!(redirect_target("/blog", None), "/blog/");
        assert_eq!(redirect_target("/blog", Some("a=1&b=%20")), "/blog/?a=1&b=%20");
        // Still encoded as sent: decoding first broke the header (and the thread).
        assert_eq!(redirect_target("/caf%C3%A9", None), "/caf%C3%A9/");
        assert_eq!(redirect_target("/café", None), "/caf%C3%A9/");
        // Not protocol-relative URLs.
        assert_eq!(redirect_target("//blog", None), "/blog/");
        assert_eq!(redirect_target("///evil.example/x", None), "/evil.example/x/");
        assert_eq!(redirect_target("/\\evil.example", None), "/%5Cevil.example/");
        assert_eq!(redirect_target("/a\r\nSet-Cookie: x", None), "/a%0D%0ASet-Cookie:%20x/");
        assert!(header("Location", &redirect_target("/日本", Some("q=ü"))).is_some());
    }

    #[test]
    fn paths() {
        let d = Path::new("/srv");
        assert_eq!(resolve(d, "/blog/x/"), Some(PathBuf::from("/srv/blog/x")));
        assert_eq!(resolve(d, "//blog"), Some(PathBuf::from("/srv/blog")));
        assert_eq!(resolve(d, "/../etc/passwd"), None);
        assert_eq!(decode("/caf%C3%A9%2"), "/café%2");
    }
}
