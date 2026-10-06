"""Tiny calculator web API (standard library only).

GET /                      -> HTML page
GET /health                -> {"status": "ok"}
GET /api/<op>?a=10&b=5     -> {"operation": "add", "a": 10.0, "b": 5.0, "result": 15.0}
"""
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from app.calculator import OPERATIONS

VERSION = os.environ.get("APP_VERSION", "dev")


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, body, content_type="application/json"):
        data = body.encode() if isinstance(body, str) else json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        url = urlparse(self.path)
        if url.path == "/":
            self._send(200, f"<h1>Session 16 Calculator</h1><p>version: {VERSION}</p>", "text/html")
        elif url.path == "/health":
            self._send(200, {"status": "ok", "version": VERSION})
        elif url.path.startswith("/api/"):
            op = url.path[len("/api/"):]
            if op not in OPERATIONS:
                return self._send(404, {"error": f"unknown operation '{op}'"})
            q = parse_qs(url.query)
            try:
                a, b = float(q["a"][0]), float(q["b"][0])
                result = OPERATIONS[op](a, b)
            except (KeyError, ValueError) as e:
                return self._send(400, {"error": str(e)})
            self._send(200, {"operation": op, "a": a, "b": b, "result": result})
        else:
            self._send(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} - {fmt % args}", flush=True)


def make_server(port=8080):
    return ThreadingHTTPServer(("0.0.0.0", port), Handler)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    print(f"Calculator API {VERSION} listening on :{port}", flush=True)
    make_server(port).serve_forever()
