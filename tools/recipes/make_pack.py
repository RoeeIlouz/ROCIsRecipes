"""Build the downloadable recipe pack the app updates itself from.

Usage (from the repository root):
  python tools/recipes/make_pack.py out

Writes out/recipes.json.gz (the recipes of assets/recipes/starter_he.json) and
out/recipes_manifest.json {version, count, sha256, bytes, generatedAt}. The version is the app's
kStarterVersion, so bumping it for a recipe change is what makes installed apps pick the pack up.
The app only applies a pack that is newer than the one it has, matches the checksum, and passes the
same strict validation as the bundled recipes. The gzip output is deterministic, so unchanged
recipes publish unchanged bytes.
"""

from __future__ import annotations

import gzip
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECIPES = ROOT / "assets" / "recipes" / "starter_he.json"
LOADER = ROOT / "lib" / "features" / "recipes" / "starter_recipe_loader.dart"


def read_version(dart_path: str) -> int:
    match = re.search(r"kStarterVersion\s*=\s*(\d+)", Path(dart_path).read_text(encoding="utf-8"))
    if not match:
        raise ValueError(f"no kStarterVersion found in {dart_path}")
    return int(match.group(1))


def build_pack(recipes_path: str, dart_path: str, out_dir: str) -> dict:
    text = Path(recipes_path).read_text(encoding="utf-8")
    recipes = json.loads(text)
    if not isinstance(recipes, list) or not recipes:
        raise ValueError("the recipe file must hold a non-empty list")
    ids = [r["id"] for r in recipes]
    if len(ids) != len(set(ids)):
        raise ValueError("duplicate recipe ids")
    # Compact JSON, mtime 0: the same recipes always compress to the same bytes.
    raw = json.dumps(recipes, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    packed = gzip.compress(raw, compresslevel=9, mtime=0)
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    (out / "recipes.json.gz").write_bytes(packed)
    manifest = {
        "version": read_version(dart_path),
        "count": len(recipes),
        "sha256": hashlib.sha256(packed).hexdigest(),
        "bytes": len(packed),
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    (out / "recipes_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    manifest = build_pack(str(RECIPES), str(LOADER), args[0])
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
