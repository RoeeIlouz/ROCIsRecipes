"""Download Carrefour's published price files (https://prices.carrefour.co.il/).

The portal is public (no login). Its page embeds the day's file list as JavaScript
(`const path = "YYYYMMDD"` and `const files = [...]`) and files live in that day's folder.
"""

from __future__ import annotations

import gzip
import json
import re
import sys
import time
from dataclasses import dataclass
from functools import lru_cache

from price_items import PriceItem, parse_price_full
from shufersal import _get  # shared GET with retries and the project's User-Agent
from stores import Store, normalize_store_id, parse_stores

BASE_URL = "https://prices.carrefour.co.il"
CHAIN_ID = "carrefour"

_PATH_RE = re.compile(r"""(?:const|let|var)\s+path\s*=\s*["']([^"']+)["']""")
_FILES_RE = re.compile(r"(?:const|let|var)\s+files\s*=\s*(\[.*?\])\s*;", re.S)
_PRICE_FULL_RE = re.compile(r"^PriceFull\d{13}-\d+-(\d+)-(\d{8})-(\d{6})")


@dataclass(frozen=True)
class CarrefourFile:
    name: str
    size: int


@dataclass(frozen=True)
class Listing:
    path: str
    files: list[CarrefourFile]


def parse_listing(html: str) -> Listing:
    path = _PATH_RE.search(html)
    files = _FILES_RE.search(html)
    if not path or not files:
        raise ValueError("Carrefour listing page has no file list (layout changed or site down)")
    return Listing(
        path=path.group(1),
        files=[CarrefourFile(name=f["name"], size=int(f.get("size", 0))) for f in json.loads(files.group(1))],
    )


def file_url(path: str, name: str) -> str:
    return f"{BASE_URL}/{path}/{name}"


def find_stores_file(files: list[CarrefourFile]) -> CarrefourFile | None:
    return next((f for f in files if f.name.startswith("Stores")), None)


def latest_price_full(files: list[CarrefourFile]) -> dict[str, CarrefourFile]:
    """Newest PriceFull file per store id (delta `Price` files are ignored)."""
    best: dict[str, tuple[str, CarrefourFile]] = {}
    for f in files:
        match = _PRICE_FULL_RE.match(f.name)
        if not match:
            continue
        store_id = normalize_store_id(match.group(1))
        stamp = match.group(2) + match.group(3)
        if store_id not in best or stamp > best[store_id][0]:
            best[store_id] = (stamp, f)
    return {k: v[1] for k, v in best.items()}


@lru_cache(maxsize=1)
def _listing() -> Listing:
    return parse_listing(_get(BASE_URL + "/").decode("utf-8", errors="replace"))


def _download(name: str) -> bytes:
    raw = _get(file_url(_listing().path, name), timeout=120)
    try:
        return gzip.decompress(raw)
    except (OSError, EOFError):
        return raw


def fetch_stores() -> list[Store]:
    stores_file = find_stores_file(_listing().files)
    if stores_file is None:
        raise RuntimeError("Carrefour Stores file not found in listing")
    return parse_stores(_download(stores_file.name), CHAIN_ID)


def fetch_chain_items(store_ids: list[str], pause_seconds: float = 0.5) -> dict[str, list[PriceItem]]:
    """Latest PriceFull items per store id. Stores that fail are skipped with a note on stderr."""
    latest = latest_price_full(_listing().files)
    result: dict[str, list[PriceItem]] = {}
    for store_id in store_ids:
        file = latest.get(store_id)
        if file is None:
            print(f"no PriceFull file for carrefour store {store_id}", file=sys.stderr)
            continue
        try:
            result[store_id] = parse_price_full(_download(file.name))
        except Exception as exc:  # one broken file must not stop the run
            print(f"carrefour store {store_id} failed: {exc}", file=sys.stderr)
        time.sleep(pause_seconds)
    return result
