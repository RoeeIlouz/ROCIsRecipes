"""Build the downloadable recipe packs the app updates itself from.

Usage (from the repository root):
  python tools/recipes/make_pack.py out

Writes two packs of the recipes in assets/recipes/starter_he.json, each with a manifest
{version, count, sha256, bytes, generatedAt}:

  out/recipes_v2.json.gz + out/recipes_v2_manifest.json   every recipe. Read by current app builds,
      which skip a recipe that uses an ingredient they do not know yet (it arrives with the next app
      release) and install the rest.
  out/recipes.json.gz + out/recipes_manifest.json          only recipes whose ingredients are all in
      tools/recipes/pack_v1_ingredients.json. Read by older app builds, which reject a whole pack when
      any recipe uses an unknown ingredient, so they keep getting updates.

The version is the app's kStarterVersion, so bumping it for a recipe change is what makes installed
apps pick a pack up. The app only applies a pack that is newer than the one it has, matches the
checksum, and passes the same strict validation as the bundled recipes. The gzip output is
deterministic, so unchanged recipes publish unchanged bytes.
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
V1_INGREDIENTS = ROOT / "tools" / "recipes" / "pack_v1_ingredients.json"


def read_version(dart_path: str) -> int:
    match = re.search(r"kStarterVersion\s*=\s*(\d+)", Path(dart_path).read_text(encoding="utf-8"))
    if not match:
        raise ValueError(f"no kStarterVersion found in {dart_path}")
    return int(match.group(1))


def _write(out: Path, name: str, recipes: list[dict], version: int) -> dict:
    # Compact JSON, mtime 0: the same recipes always compress to the same bytes.
    raw = json.dumps(recipes, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    packed = gzip.compress(raw, compresslevel=9, mtime=0)
    (out / f"{name}.json.gz").write_bytes(packed)
    manifest = {
        "version": version,
        "count": len(recipes),
        "sha256": hashlib.sha256(packed).hexdigest(),
        "bytes": len(packed),
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    (out / f"{name}_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def build_pack(recipes_path: str, dart_path: str, out_dir: str, v1_ingredients_path: str | None = None) -> dict:
    """Write both packs; returns {"recipes": v1 manifest, "recipes_v2": full manifest}."""
    recipes = json.loads(Path(recipes_path).read_text(encoding="utf-8"))
    if not isinstance(recipes, list) or not recipes:
        raise ValueError("the recipe file must hold a non-empty list")
    ids = [r["id"] for r in recipes]
    if len(ids) != len(set(ids)):
        raise ValueError("duplicate recipe ids")
    v1 = recipes
    if v1_ingredients_path is not None:
        known = set(json.loads(Path(v1_ingredients_path).read_text(encoding="utf-8")))
        v1 = [r for r in recipes if all(i["ingredientId"] in known for i in r["ingredients"])]
        if not v1:
            raise ValueError("no recipe fits the v1 ingredient list")
    version = read_version(dart_path)
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    return {"recipes": _write(out, "recipes", v1, version), "recipes_v2": _write(out, "recipes_v2", recipes, version)}


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    manifests = build_pack(str(RECIPES), str(LOADER), args[0], str(V1_INGREDIENTS))
    print(json.dumps(manifests, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
