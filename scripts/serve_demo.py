#!/usr/bin/env python3
"""Serve the HTML5 demo build with optional HTTPS.

Godot's Web export requires a secure context (HTTPS or localhost) for some
features, so public demos should set DEMO_HTTPS=true.
"""
import argparse
import http.server
import os
import socketserver
import ssl
import subprocess
import sys
from pathlib import Path


def generate_self_signed_cert(cert_path: Path, key_path: Path, host: str) -> None:
    """Generate a self-signed certificate with OpenSSL."""
    cert_path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "openssl", "req", "-x509", "-newkey", "rsa:2048",
            "-keyout", str(key_path),
            "-out", str(cert_path),
            "-days", "30",
            "-nodes",
            "-subj", f"/CN={host}",
            "-addext", f"subjectAltName=DNS:{host},IP:{host}",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Serve the One Arcade HTML5 demo")
    parser.add_argument("--host", default=os.environ.get("DEMO_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("DEMO_PORT", "8765")))
    parser.add_argument("--directory", default=os.environ.get("BUILD_DIR", "build/html5"))
    parser.add_argument("--https", type=lambda x: x.lower() in ("1", "true", "yes"),
                        default=os.environ.get("DEMO_HTTPS", "").lower() in ("1", "true", "yes"),
                        help="Enable HTTPS (values: true/1/yes or false/0/no)")
    parser.add_argument("--cert", default=os.environ.get("DEMO_CERT", "build/certs/demo.crt"))
    parser.add_argument("--key", default=os.environ.get("DEMO_KEY", "build/certs/demo.key"))
    args = parser.parse_args()

    directory = Path(args.directory).resolve()
    if not directory.is_dir():
        print(f"ERROR: Build directory not found: {directory}", file=sys.stderr)
        return 1

    os.chdir(directory)

    Handler = http.server.SimpleHTTPRequestHandler

    with socketserver.TCPServer((args.host, args.port), Handler) as httpd:
        protocol = "http"
        if args.https:
            cert_path = Path(args.cert)
            key_path = Path(args.key)
            if not cert_path.exists() or not key_path.exists():
                print(f"==> Generating self-signed cert in {cert_path.parent} ...")
                generate_self_signed_cert(cert_path, key_path, args.host)
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.load_cert_chain(str(cert_path), str(key_path))
            httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
            protocol = "https"

        access_host = args.host if args.host != "0.0.0.0" else os.popen("hostname -I | awk '{print $1}'").read().strip()
        print(f"==> Serving HTML5 demo at {protocol}://{access_host}:{args.port}/")
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
