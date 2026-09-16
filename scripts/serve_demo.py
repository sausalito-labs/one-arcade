#!/usr/bin/env python3
"""Serve the HTML5 demo build over the tailnet/funnel.

Tailscale Funnel terminates HTTPS with a real Let's Encrypt cert, so this
server only needs to speak plain HTTP on localhost. The COOP/COEP headers
provide the cross-origin isolation the threaded Godot build needs for
SharedArrayBuffer.
"""
import argparse
import http.server
import os
import socketserver
import sys
from pathlib import Path


class DemoRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with cache-busting and COOP/COEP headers."""

    def end_headers(self) -> None:
        # Never cache the demo files so browsers always load the latest build.
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        # Cross-Origin Isolation headers required for Godot threaded Web builds
        # (SharedArrayBuffer). Sending them unconditionally is harmless for
        # single-threaded builds.
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, format: str, *args) -> None:
        # Log to stdout so tmux/terminal shows access traffic.
        sys.stdout.write("%s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), format % args))


def main() -> int:
    parser = argparse.ArgumentParser(description="Serve the One Arcade HTML5 demo")
    parser.add_argument("--host", default=os.environ.get("DEMO_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("DEMO_PORT", "8765")))
    parser.add_argument("--directory", default=os.environ.get("BUILD_DIR", "build/html5"))
    args = parser.parse_args()

    directory = Path(args.directory).resolve()
    if not directory.is_dir():
        print(f"ERROR: Build directory not found: {directory}", file=sys.stderr)
        return 1

    os.chdir(directory)

    with socketserver.TCPServer((args.host, args.port), DemoRequestHandler) as httpd:
        print(f"==> Serving HTML5 demo at http://{args.host}:{args.port}/")
        print(f"    Bind: {args.host}:{args.port}")
        print(f"    Directory: {directory}")
        print(f"    Press Ctrl+C to stop")
        print()

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n==> Server stopped")

    return 0


if __name__ == "__main__":
    sys.exit(main())
