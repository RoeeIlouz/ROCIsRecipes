"""Geocode branch addresses with OpenStreetMap Nominatim (cached, 1 request per second).

Nominatim usage policy: identify the application with a User-Agent, send at most
one request per second, and cache results. Data is (c) OpenStreetMap contributors (ODbL).
"""

from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path
from typing import Callable

from retry import with_retries
from stores import Store

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
CITIES_URL = (
    "https://data.gov.il/api/3/action/datastore_search"
    "?resource_id=d4901968-dad3-4845-a9b0-a57d027f11ab&limit=5000"
)
USER_AGENT = "ROCIsRecipes price pipeline (github.com/RoeeIlouz/ROCIsRecipes)"
RETRY_AFTER_DAYS = 30

# Rough bounding box of Israel and the West Bank; anything outside is a bad geocode.
_LAT_RANGE = (29.4, 33.4)
_LNG_RANGE = (34.2, 35.9)


@dataclass(frozen=True)
class GeoPoint:
    lat: float
    lng: float


def _http_get(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read().decode("utf-8", errors="replace")


def parse_city_names(json_text: str) -> dict[str, str]:
    """Map the numeric city code used in Stores files to the settlement name."""
    records = json.loads(json_text)["result"]["records"]
    return {str(r["סמל_ישוב"]): str(r["שם_ישוב"]).strip() for r in records if r.get("שם_ישוב")}


def fetch_city_names(fetch: Callable[[str], str] = _http_get) -> dict[str, str]:
    return parse_city_names(with_retries(lambda: fetch(CITIES_URL)))


_CORNER_TAIL = re.compile(r"\s*פינת\s.*$")
_STREET_PREFIX = re.compile(r"^רח['׳.]\s*|^רח\s+|^רחוב\s+")
_LEADING_NUMBER = re.compile(r"^(\d+)\s+(\D.*)$")
_AVENUE_PREFIX = re.compile(r"^שד['׳.]\s*|^שד\s+")
_GLUED_NUMBER = re.compile(r"(?<=[֐-׿])(?=\d)")
CACHE_VERSION = 2  # bump when the query strategy changes so earlier misses are retried


def clean_address(address: str) -> str:
    """Expand or drop the abbreviations the chains use, which Nominatim does not parse."""
    s = address.replace('"', "").replace("״", "")
    s = _CORNER_TAIL.sub("", s.strip())
    leading = _LEADING_NUMBER.match(s)
    if leading:  # "14 רחוב הבנים" -> "רחוב הבנים 14"
        s = f"{leading.group(2)} {leading.group(1)}"
    s = _STREET_PREFIX.sub("", s)
    s = _AVENUE_PREFIX.sub("שדרות ", s)
    s = _GLUED_NUMBER.sub(" ", s)  # "ורדיה10" -> "ורדיה 10"
    return re.sub(r"\s+", " ", s).strip()


def _compose(address: str, store: Store, city_names: dict[str, str]) -> str:
    parts = [address]
    city = city_names.get(store.city_code)
    if city:
        parts.append(city.replace(" - ", "-"))
    parts.append("ישראל")
    return ", ".join(p for p in parts if p)


def build_query(store: Store, city_names: dict[str, str]) -> str:
    return _compose(clean_address(store.address), store, city_names)


def display_address(store: Store, city_names: dict[str, str]) -> str:
    """Street and city for showing to users (and for a maps link), without the country."""
    parts = [clean_address(store.address)]
    city = city_names.get(store.city_code)
    if city:
        parts.append(city.replace(" - ", "-"))
    return ", ".join(p for p in parts if p)


def fallback_queries(store: Store, city_names: dict[str, str]) -> list[str]:
    """Full address first; then the street alone, because OpenStreetMap often lacks house numbers."""
    address = clean_address(store.address)
    queries = [_compose(address, store, city_names)]
    street = re.split(r"\d", address, maxsplit=1)[0].strip(" ,")
    if street and street != address:
        queries.append(_compose(street, store, city_names))
    return queries


def parse_nominatim(json_text: str) -> GeoPoint | None:
    try:
        results = json.loads(json_text)
        first = results[0]
        lat, lng = float(first["lat"]), float(first["lon"])
    except (ValueError, KeyError, IndexError, TypeError):
        return None
    if not (_LAT_RANGE[0] <= lat <= _LAT_RANGE[1] and _LNG_RANGE[0] <= lng <= _LNG_RANGE[1]):
        return None
    return GeoPoint(lat, lng)


def _load_cache(path: str) -> dict:
    file = Path(path)
    if not file.exists():
        return {}
    return json.loads(file.read_text(encoding="utf-8"))


def _save_cache(path: str, cache: dict) -> None:
    Path(path).write_text(
        json.dumps(cache, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8"
    )


def geocode_stores(
    stores: list[Store],
    cache_path: str,
    city_names: dict[str, str],
    pause_seconds: float = 1.1,
    fetch: Callable[[str], str] = _http_get,
    sleep: Callable[[float], None] = time.sleep,
    today: date | None = None,
) -> dict[str, GeoPoint]:
    """Coordinates per "chain:store_id". Cached results (hits, and misses for 30 days) are reused."""
    today = today or date.today()
    cache = _load_cache(cache_path)
    result: dict[str, GeoPoint] = {}
    for store in stores:
        key = f"{store.chain}:{store.store_id}"
        queries = fallback_queries(store, city_names)
        query = queries[0]
        entry = cache.get(key)
        if entry and entry.get("q") == query:
            if entry.get("lat") is not None:
                result[key] = GeoPoint(entry["lat"], entry["lng"])
                continue
            recent = date.fromisoformat(entry["at"]) + timedelta(days=RETRY_AFTER_DAYS) >= today
            if entry.get("v") == CACHE_VERSION and recent:
                continue
        point: GeoPoint | None = None
        try:
            for attempt in queries:
                url = f"{NOMINATIM_URL}?{urllib.parse.urlencode({'q': attempt, 'format': 'json', 'limit': 1, 'countrycodes': 'il'})}"
                point = parse_nominatim(fetch(url))
                if point:
                    break
                sleep(pause_seconds)
        except Exception:  # a network failure is not a verdict on the address; try again next run
            sleep(pause_seconds)
            continue
        cache[key] = {
            "q": query,
            "v": CACHE_VERSION,
            "at": today.isoformat(),
            "lat": point.lat if point else None,
            "lng": point.lng if point else None,
        }
        if point:
            result[key] = point
        _save_cache(cache_path, cache)
        sleep(pause_seconds)
    return result
