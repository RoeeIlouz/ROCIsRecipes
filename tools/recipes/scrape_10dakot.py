"""Collect recipe facts from 10dakot.co.il as a reference list for writing new dishes.

Usage (from the repository root):
  python tools/recipes/scrape_10dakot.py            # fetch recipes not fetched yet (resumable)
  python tools/recipes/scrape_10dakot.py --limit 50

Reads the site's recipe sitemaps (recipe pages are allowed by its robots.txt), fetches each page
politely (one request every PAUSE_SECONDS) and keeps only the schema.org Recipe facts: name, yield,
times, categories, kosher type, ingredient lines and step texts. Reviews and photos are skipped.

The output, tools/recipes/sources/10dakot.jsonl, is reference material and is not committed: the
site's wording and photos belong to its author, so dishes added to the app are written in our own
words with our own ingredient ids (and Wikimedia photos), the same as every other batch.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "sources" / "10dakot.jsonl"
SITE = "https://www.10dakot.co.il"
PAUSE_SECONDS = 1.5
HEADERS = {"User-Agent": "Mozilla/5.0 (recipe-reference-fetcher)"}

LD_JSON = re.compile(r'<script[^>]*application/ld\+json[^>]*>(.*?)</script>', re.S)
LOC = re.compile(r"<loc>([^<]+)</loc>")


def get(url: str) -> str:
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", errors="replace")


def recipe_urls() -> list[str]:
    index = get(f"{SITE}/sitemap_index.xml")
    urls: list[str] = []
    for sitemap in LOC.findall(index):
        if "/recipe-sitemap" not in sitemap:
            continue
        time.sleep(PAUSE_SECONDS)
        for url in LOC.findall(get(sitemap)):
            path = urllib.parse.urlparse(url).path
            if path.startswith("/recipe/") and path.strip("/") != "recipe":
                urls.append(url)
    return list(dict.fromkeys(urls))


def _nodes(data):
    if isinstance(data, list):
        for item in data:
            yield from _nodes(item)
    elif isinstance(data, dict):
        if "@graph" in data:
            yield from _nodes(data["@graph"])
        else:
            yield data


def _steps(instructions) -> list[str]:
    steps: list[str] = []
    for item in instructions or []:
        if isinstance(item, str):
            steps.append(item.strip())
        elif item.get("@type") == "HowToSection":
            steps.extend(_steps(item.get("itemListElement")))
        elif item.get("text"):
            steps.append(item["text"].strip())
    return steps


def parse_recipe(html: str, url: str) -> dict | None:
    for block in LD_JSON.findall(html):
        try:
            data = json.loads(block)
        except json.JSONDecodeError:
            continue
        for node in _nodes(data):
            kind = node.get("@type")
            if kind == "Recipe" or (isinstance(kind, list) and "Recipe" in kind):
                return {
                    "url": url,
                    "name": (node.get("name") or "").strip(),
                    "yield": node.get("recipeYield"),
                    "prepTime": node.get("prepTime"),
                    "cookTime": node.get("cookTime"),
                    "totalTime": node.get("totalTime"),
                    "categories": [c.strip() for c in (node.get("recipeCategory") or "").split(",") if c.strip()],
                    "kosher": node.get("recipeCuisine"),
                    "ingredients": [i.strip() for i in node.get("recipeIngredient") or []],
                    "steps": _steps(node.get("recipeInstructions")),
                    "rating": (node.get("aggregateRating") or {}).get("ratingValue"),
                    "ratingCount": (node.get("aggregateRating") or {}).get("ratingCount"),
                }
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    done: set[str] = set()
    if OUT.exists():
        for line in OUT.read_text(encoding="utf-8").splitlines():
            if line.strip():
                done.add(json.loads(line)["url"])

    urls = [u for u in recipe_urls() if u not in done]
    if args.limit:
        urls = urls[: args.limit]
    print(f"{len(done)} already fetched, {len(urls)} to fetch", flush=True)

    failed = 0
    with OUT.open("a", encoding="utf-8", newline="\n") as out:
        for n, url in enumerate(urls, 1):
            time.sleep(PAUSE_SECONDS)
            try:
                recipe = parse_recipe(get(url), url)
            except Exception as error:  # network hiccups: skip, a later run retries
                failed += 1
                print(f"failed {urllib.parse.unquote(url)}: {error}", flush=True)
                continue
            if recipe is None:
                recipe = {"url": url, "name": None}
            out.write(json.dumps(recipe, ensure_ascii=False) + "\n")
            out.flush()
            if n % 50 == 0:
                print(f"{n}/{len(urls)}", flush=True)
    print(f"done, {failed} failed", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
