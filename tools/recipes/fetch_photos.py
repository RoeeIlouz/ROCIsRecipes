"""Fetch a licensed photo for every recipe from Wikimedia Commons.

Usage (from the repository root):
  python tools/recipes/fetch_photos.py              # fetch photos that are missing
  python tools/recipes/fetch_photos.py --refresh    # redo all of them
  python tools/recipes/fetch_photos.py --only rv2_shakshuka

Each recipe's `photoQuery` (English dish name, in tools/recipes/content/batch*.json) is searched on
Commons. `tools/recipes/photo_overrides.json` maps a recipe id to an exact Commons file title
(for example "File:Shakshuka1.jpg") and wins over the search. Photos are saved as
assets/recipes/photos/<recipe id>.jpg (recompressed to 720 px wide with ffmpeg when available) and
their credit is written to tools/recipes/photos.json, which build_recipes.py attaches to the recipes.
Recipes that end up without a photo are listed at the end; they show a placeholder in the app.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import commons
from build_recipes import merge_batches

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PHOTO_DIR = ROOT / "assets" / "recipes" / "photos"
PAUSE_SECONDS = 2.5


def _load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}


def recompress(data: bytes, dest: Path, width: int = 720) -> None:
    """Scale to `width` px (never upscale) as a smaller JPEG; keep the original bytes if ffmpeg is missing."""
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        dest.write_bytes(data)
        return
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "in.jpg"
        src.write_bytes(data)
        result = subprocess.run(
            [ffmpeg, "-y", "-loglevel", "error", "-i", str(src), "-vf", f"scale='min({width},iw)':-2", "-q:v", "4", str(dest)],
            capture_output=True,
        )
        if result.returncode != 0 or not dest.exists() or dest.stat().st_size == 0:
            dest.write_bytes(data)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--refresh", action="store_true")
    parser.add_argument("--only")
    parser.add_argument("--prefix", help="only recipes whose id starts with one of these comma-separated prefixes")
    parser.add_argument("--retry-nomatch", action="store_true", help="search again for recipes that found nothing before")
    args = parser.parse_args(argv)

    recipes = merge_batches(str(HERE / "content"))
    overrides = _load(HERE / "photo_overrides.json")
    rejected = set(_load(HERE / "photo_rejected.json").get("rejected", []))  # reviewed by eye: wrong picture
    nomatch_path = HERE / "photo_nomatch.json"
    nomatch = set(_load(nomatch_path).get("nomatch", []))  # searched before, nothing acceptable on Commons
    photos_path = HERE / "photos.json"
    photos = _load(photos_path)
    PHOTO_DIR.mkdir(parents=True, exist_ok=True)

    missing: list[str] = []
    for recipe in recipes:
        rid = recipe["id"]
        if args.only and rid != args.only:
            continue
        if args.prefix and not rid.startswith(tuple(args.prefix.split(","))):
            continue
        if (rid in rejected or (rid in nomatch and not args.retry_nomatch)) and rid not in overrides:
            missing.append(rid)
            continue
        dest = PHOTO_DIR / f"{rid}.jpg"
        if not args.refresh and rid in photos and dest.exists():
            continue
        query = recipe.get("photoQuery", "")
        try:
            if rid in overrides:
                candidates = commons.lookup(overrides[rid])
                chosen = candidates[0] if candidates and commons.is_allowed_license(candidates[0].license) else None
            else:
                chosen = commons.pick(commons.search(query))
            time.sleep(PAUSE_SECONDS)
            if chosen is None:
                print(f"no acceptable photo for {rid} ({query})", file=sys.stderr)
                missing.append(rid)
                nomatch.add(rid)
                nomatch_path.write_text(json.dumps({"nomatch": sorted(nomatch)}, indent=1) + chr(10), encoding="utf-8")
                continue
            recompress(commons.download(chosen.thumb_url), dest)
            time.sleep(PAUSE_SECONDS)
        except Exception as exc:  # one failure must not lose the others
            print(f"{rid} failed: {exc}", file=sys.stderr)
            missing.append(rid)
            continue
        photos[rid] = {
            "asset": f"assets/recipes/photos/{rid}.jpg",
            "author": chosen.author,
            "license": chosen.license,
            "sourceUrl": chosen.source_url,
        }
        photos_path.write_text(json.dumps(photos, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8")
        print(f"{rid}: {chosen.title} ({chosen.license}, {dest.stat().st_size // 1024} KB)", file=sys.stderr)

    have = len([r for r in recipes if r["id"] in photos])
    print(f"{have}/{len(recipes)} recipes have a photo; missing: {', '.join(missing) or 'none'}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
