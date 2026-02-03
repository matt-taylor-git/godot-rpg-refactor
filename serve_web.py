"""HTTP server for Godot web exports with correct WASM headers.

Serves files from the webexport/ directory with the Cross-Origin headers
required by SharedArrayBuffer (COOP/COEP) and correct MIME types for
.wasm and .pck files (Windows registry can override Python's defaults).

Usage:
    python serve_web.py [--port PORT] [--dir DIR]

Prints SERVER_READY http://localhost:<port>/rpg.html when bound and listening.
"""

import argparse
import os
import sys
from functools import partial
from http.server import HTTPServer, SimpleHTTPRequestHandler


MIME_OVERRIDES = {
    ".wasm": "application/wasm",
    ".pck": "application/octet-stream",
    ".js": "application/javascript",
    ".html": "text/html",
    ".png": "image/png",
    ".svg": "image/svg+xml",
}


class GodotWebHandler(SimpleHTTPRequestHandler):
    """HTTP handler that adds COOP/COEP headers and overrides MIME types."""

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def guess_type(self, path):
        _, ext = os.path.splitext(path)
        ext = ext.lower()
        if ext in MIME_OVERRIDES:
            return MIME_OVERRIDES[ext]
        return super().guess_type(path)


def main():
    parser = argparse.ArgumentParser(description="Serve Godot web export")
    parser.add_argument("--port", type=int, default=8060, help="Port to listen on (default: 8060)")
    parser.add_argument("--dir", type=str, default="webexport", help="Directory to serve (default: webexport)")
    args = parser.parse_args()

    serve_dir = os.path.abspath(args.dir)
    if not os.path.isdir(serve_dir):
        print(f"Error: directory not found: {serve_dir}", file=sys.stderr)
        sys.exit(1)

    handler = partial(GodotWebHandler, directory=serve_dir)
    server = HTTPServer(("127.0.0.1", args.port), handler)

    print(f"Serving {serve_dir} on http://127.0.0.1:{args.port}")
    print(f"SERVER_READY http://localhost:{args.port}/rpg.html")
    sys.stdout.flush()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.shutdown()


if __name__ == "__main__":
    main()
