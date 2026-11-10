"""Find licensed dish photos on Wikimedia Commons (no account or API key needed)."""

from __future__ import annotations

import html
import json
import re
import time
import urllib.parse
import urllib.request
from dataclasses import dataclass

API = "https://commons.wikimedia.org/w/api.php"
USER_AGENT = "ROCIsRecipes recipe photo pipeline (github.com/RoeeIlouz/ROCIsRecipes)"
THUMB_WIDTH = 960  # Commons serves fixed thumbnail steps (500, 960, 1280, ...)
MIN_WIDTH = 800
MAX_AUTHOR = 80


@dataclass(frozen=True)
class Candidate:
    title: str
    thumb_url: str
    width: int
    height: int
    license: str
    author: str
    source_url: str


def clean_author(raw: str) -> str:
    """Commons author fields are HTML (links, entities); reduce them to plain text."""
    text = html.unescape(re.sub(r"<[^>]+>", "", raw or ""))
    text = re.sub(r"\s+", " ", text).strip()
    return text[:MAX_AUTHOR].strip() or "Unknown"


_ALLOWED = re.compile(r"^(cc0.*|public domain.*|pd.*|cc by(-sa)? \d+(\.\d+)?)$")


def is_allowed_license(short_name: str) -> bool:
    """CC0, public domain, CC BY and CC BY-SA only: never NonCommercial or NoDerivatives."""
    name = (short_name or "").strip().lower()
    if not name or {"nc", "nd"} & set(re.split(r"[-\s]+", name)):
        return False
    return bool(_ALLOWED.match(name))


def _source_url(title: str) -> str:
    return "https://commons.wikimedia.org/wiki/" + title.replace(" ", "_")


def parse_candidates(json_text: str) -> list[Candidate]:
    """Candidates from a Commons API response, in search rank order."""
    try:
        pages = json.loads(json_text)["query"]["pages"].values()
    except (ValueError, KeyError, TypeError):
        return []
    found: list[tuple[int, Candidate]] = []
    for page in pages:
        infos = page.get("imageinfo") or []
        if not infos:
            continue
        info = infos[0]
        meta = info.get("extmetadata", {})
        found.append(
            (
                page.get("index", 0),
                Candidate(
                    title=page["title"],
                    thumb_url=info.get("thumburl") or info.get("url", ""),
                    width=int(info.get("width", 0)),
                    height=int(info.get("height", 0)),
                    license=meta.get("LicenseShortName", {}).get("value", ""),
                    author=clean_author(meta.get("Artist", {}).get("value", "")),
                    source_url=_source_url(page["title"]),
                ),
            )
        )
    return [c for _, c in sorted(found, key=lambda t: t[0])]


def pick(candidates: list[Candidate]) -> Candidate | None:
    """First candidate that is a large enough JPEG with an allowed license and sane proportions."""
    for c in candidates:
        if not c.title.lower().endswith((".jpg", ".jpeg")):
            continue
        if c.width < MIN_WIDTH or c.height <= 0:
            continue
        if not 0.7 <= c.width / c.height <= 2.0:
            continue
        if not is_allowed_license(c.license):
            continue
        return c
    return None


def _get(url: str, timeout: int = 60) -> bytes:
    last: Exception | None = None
    for attempt in range(3):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return response.read()
        except Exception as exc:  # network hiccup: wait and retry
            last = exc
            time.sleep(5 * (attempt + 1))
    raise RuntimeError(f"request failed: {last}")


def _query(extra: dict[str, str]) -> list[Candidate]:
    params = {
        "action": "query",
        "format": "json",
        "prop": "imageinfo",
        "iiprop": "url|extmetadata|size|mime",
        "iiurlwidth": str(THUMB_WIDTH),
        **extra,
    }
    return parse_candidates(_get(f"{API}?{urllib.parse.urlencode(params)}").decode("utf-8", errors="replace"))


def search(query: str, limit: int = 15) -> list[Candidate]:
    return _query(
        {"generator": "search", "gsrsearch": f"{query} filetype:bitmap", "gsrnamespace": "6", "gsrlimit": str(limit)}
    )


def lookup(title: str) -> list[Candidate]:
    return _query({"titles": title})


def download(url: str) -> bytes:
    return _get(url, timeout=120)
