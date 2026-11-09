"""Download Shufersal's published price files (https://prices.shufersal.co.il/)."""

from __future__ import annotations

import gzip
import html
import re
import sys
import time
import urllib.request
from dataclasses import dataclass

from price_items import PriceItem, parse_price_full
from stores import Store, normalize_store_id, parse_stores

BASE_URL = "https://prices.shufersal.co.il"
USER_AGENT = "ROCIsRecipes price pipeline (github.com/RoeeIlouz/ROCIsRecipes)"
CAT_PRICE_FULL = 2
CAT_STORES = 5
CHAIN_ID = "shufersal"

_LINK_RE = re.compile(r'href="(https://pricesprodpublic[^"]+)"')
_NAME_RE = re.compile(r"^[A-Za-z]+\d{13}-\d+-(\d+)-\d{8}-\d{6}")


@dataclass(frozen=True)
class FileLink:
    name: str
    url: str
    store_id: str


def parse_listing(html_text: str) -> list[FileLink]:
    links: list[FileLink] = []
    for raw in _LINK_RE.findall(html_text):
        url = html.unescape(raw)
        name = url.split("?")[0].rsplit("/", 1)[-1]
        match = _NAME_RE.match(name)
        links.append(FileLink(name=name, url=url, store_id=normalize_store_id(match.group(1)) if match else ""))
    return links


def _get(url: str, timeout: int = 60) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read()


def list_files(cat_id: int, page: int, store_id: int = 0) -> list[FileLink]:
    url = (
        f"{BASE_URL}/FileObject/UpdateCategory?catID={cat_id}&storeId={store_id}"
        f"&sort=Size&sortdir=DESC&page={page}"
    )
    return parse_listing(_get(url).decode("utf-8", errors="replace"))


def _download(link: FileLink) -> bytes:
    raw = _get(link.url, timeout=120)
    try:
        return gzip.decompress(raw)
    except (OSError, EOFError):
        return raw


def download_items(link: FileLink) -> list[PriceItem]:
    return parse_price_full(_download(link))


def fetch_stores() -> list[Store]:
    links = list_files(CAT_STORES, 1)
    if not links:
        raise RuntimeError("Shufersal Stores file not found in listing")
    return parse_stores(_download(links[0]), CHAIN_ID)


def fetch_chain_items(store_ids: list[str], pause_seconds: float = 0.5) -> dict[str, list[PriceItem]]:
    """Latest PriceFull items per store id. Stores that fail are skipped with a note on stderr."""
    result: dict[str, list[PriceItem]] = {}
    for store_id in store_ids:
        try:
            candidates = [l for l in list_files(CAT_PRICE_FULL, 1, int(store_id)) if l.store_id == store_id]
            if not candidates:
                print(f"no PriceFull file for store {store_id}", file=sys.stderr)
                continue
            latest = max(candidates, key=lambda l: l.name.rsplit("-", 2)[-2:])
            result[store_id] = download_items(latest)
        except Exception as exc:  # network or parse failure for one store must not stop the run
            print(f"store {store_id} failed: {exc}", file=sys.stderr)
        time.sleep(pause_seconds)
    return result
