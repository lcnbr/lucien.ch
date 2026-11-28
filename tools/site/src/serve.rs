//! `cargo site serve [PORT]`: serve dist/ locally with the isolation headers
//! Cloudflare sends: always on /edit/, and on pages while the edit=1 cookie is
//! set (functions/_middleware.js).

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

fn header(k: &str, v: &str) -> Header {
    Header::from_bytes(k.as_bytes(), v.as_bytes()).expect("valid header")
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
    if isolate {
        r.add_header(header("Cross-Origin-Opener-Policy", "same-origin"));
        r.add_header(header("Cross-Origin-Embedder-Policy", "require-corp"));
    }
    r.add_header(header("Vary", "Cookie"));
    r
}

fn handle(dir: &Path, req: Request) -> std::io::Result<()> {
    let url = req.url().to_string();
    let (path_part, query) = match url.split_once('?') {
        Some((p, q)) => (p, Some(q)),
        None => (url.as_str(), None),
    };
    let path = decode(path_part.split('#').next().unwrap_or("/"));
    let cookie_edit = req
        .headers()
        .iter()
        .any(|h| h.field.equiv("Cookie") && h.value.as_str().replace(' ', "").split(';').any(|c| c == "edit=1"));
    let isolate = path.starts_with("/edit/") || cookie_edit;
    let not_found = || Response::from_string("404 Not Found\n").with_status_code(404);

    let Some(mut file) = resolve(dir, &path) else { return req.respond(with_headers(not_found(), isolate)) };
    if file.is_dir() {
        if !path.ends_with('/') {
            let to = format!("{path}/{}", query.map(|q| format!("?{q}")).unwrap_or_default());
            let r = Response::empty(301).with_header(header("Location", &to));
            return req.respond(with_headers(r, isolate));
        }
        file = file.join("index.html");
    }
    match fs::File::open(&file) {
        Ok(f) if file.is_file() => {
            let r = Response::from_file(f).with_header(header("Content-Type", content_type(&file)));
            req.respond(with_headers(r, isolate))
        }
        _ => req.respond(with_headers(not_found(), isolate)),
    }
}

pub fn run(dir: &Path, port: u16) -> Result<()> {
    if !dir.is_dir() {
        return Err(anyhow!("{} does not exist: run `cargo site build` first", dir.display()));
    }
    let server = Arc::new(Server::http(("0.0.0.0", port)).map_err(|e| anyhow!("listening on port {port}: {e}"))?);
    println!("http://localhost:{port}/  (editor: http://localhost:{port}/edit/)");
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
