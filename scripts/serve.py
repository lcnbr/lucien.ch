#!/usr/bin/env python3
"""Serve dist/ locally with the same isolation headers Cloudflare sends (dist/_headers).

    python3 scripts/serve.py [port]
"""
import functools
import http.server
import sys
from pathlib import Path

DIST = Path(__file__).resolve().parent.parent / "dist"


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()


port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
handler = functools.partial(Handler, directory=str(DIST))
print(f"http://localhost:{port}/  (editor: http://localhost:{port}/edit/)")
http.server.ThreadingHTTPServer(("", port), handler).serve_forever()
