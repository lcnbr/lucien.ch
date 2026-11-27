#!/usr/bin/env python3
"""Serve dist/ locally with the isolation headers Cloudflare sends: always on
/edit/, and on pages while the edit=1 cookie is set (functions/_middleware.js).

    python3 scripts/serve.py [port]
"""
import functools
import http.server
import sys
from pathlib import Path

DIST = Path(__file__).resolve().parent.parent / "dist"


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        cookie = self.headers.get("Cookie", "")
        if self.path.startswith("/edit/") or "edit=1" in cookie.replace(" ", "").split(";"):
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Vary", "Cookie")
        super().end_headers()


port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
handler = functools.partial(Handler, directory=str(DIST))
print(f"http://localhost:{port}/  (editor: http://localhost:{port}/edit/)")
http.server.ThreadingHTTPServer(("", port), handler).serve_forever()
