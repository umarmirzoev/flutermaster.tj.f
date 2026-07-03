#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class SpaHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, web_root: str, **kwargs):
        self.web_root = Path(web_root)
        super().__init__(*args, directory=web_root, **kwargs)

    def do_GET(self) -> None:
        clean = self.path.split("?", 1)[0]
        rel = clean.lstrip("/")
        file_path = self.web_root / rel if rel else self.web_root / "index.html"

        if not rel or not file_path.is_file():
            self.path = "/index.html"

        return super().do_GET()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=8082)
    parser.add_argument(
        "--dir",
        default=str(Path(__file__).resolve().parents[1] / "build" / "web"),
    )
    args = parser.parse_args()

    web_root = str(Path(args.dir).resolve())
    if not (Path(web_root) / "index.html").is_file():
        raise SystemExit(f"index.html not found in {web_root}")

    handler = lambda *a, **k: SpaHandler(*a, web_root=web_root, **k)
    server = ThreadingHTTPServer((args.host, args.port), handler)
    print(f"Serving {web_root} at http://{args.host}:{args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
