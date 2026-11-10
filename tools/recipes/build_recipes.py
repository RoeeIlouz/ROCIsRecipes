"""Build assets/recipes/starter_he.json from the content batches.

Usage (from the repository root):
  python tools/recipes/build_recipes.py

Reads tools/recipes/content/batch*.json (sorted by file name), attaches photo credits from
tools/recipes/photos.json (recipe id to photo object) when that file exists, and writes the
app asset with one recipe per line, in a stable order.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def merge_batches(content_dir: str) -> list[dict]:
    files = sorted(Path(content_dir).glob("batch*.json"))
    if not files:
        raise ValueError(f"no batch*.json files in {content_dir}")
    recipes: list[dict] = []
    seen: dict[str, str] = {}
    for file in files:
        for recipe in json.loads(file.read_text(encoding="utf-8")):
            if recipe["id"] in seen:
                raise ValueError(f"duplicate recipe id {recipe['id']!r} in {file.name} and {seen[recipe['id']]}")
            seen[recipe["id"]] = file.name
            recipes.append(recipe)
    return recipes


def build(content_dir: str, photos_path: str, out_path: str) -> int:
    recipes = merge_batches(content_dir)
    photos_file = Path(photos_path)
    photos = json.loads(photos_file.read_text(encoding="utf-8")) if photos_file.exists() else {}
    for recipe in recipes:
        photo = photos.get(recipe["id"])
        if photo:
            recipe["photo"] = photo
    lines = [json.dumps(r, ensure_ascii=False, separators=(",", ":")) for r in recipes]
    Path(out_path).write_text("[\n" + ",\n".join(lines) + "\n]\n", encoding="utf-8", newline="\n")
    return len(recipes)


def main() -> int:
    count = build(
        str(HERE / "content"),
        str(HERE / "photos.json"),
        str(ROOT / "assets" / "recipes" / "starter_he.json"),
    )
    print(f"wrote {count} recipes", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
