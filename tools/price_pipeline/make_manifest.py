"""Write manifest.json (generatedAt, sha256, bytes) for a snapshot.json.gz.

Usage: python tools/price_pipeline/make_manifest.py out/snapshot.json.gz out/manifest.json
Fails if the snapshot is not valid gzip JSON with a generatedAt date, so a broken
build is never published.
"""

from __future__ import annotations

import gzip
import hashlib
import json
import sys
from pathlib import Path


def build_manifest(snapshot_path: str) -> dict:
    data = Path(snapshot_path).read_bytes()
    snapshot = json.loads(gzip.decompress(data).decode("utf-8"))
    return {
        "generatedAt": snapshot["generatedAt"],
        "sha256": hashlib.sha256(data).hexdigest(),
        "bytes": len(data),
    }


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    manifest = build_manifest(args[0])
    Path(args[1]).write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
