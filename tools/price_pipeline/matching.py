"""Map catalog ingredients to supermarket products and aggregate prices per branch."""

from __future__ import annotations

import json
import re
import statistics
from dataclasses import dataclass
from pathlib import Path

from price_items import PriceItem

_NIQQUD = re.compile("[֑-ׇ]")
_PUNCTUATION = re.compile("[\"'`´’“”׳״.,;:!?()]")
_SEPARATORS = re.compile(r"[-_\s]+")
_FINAL_LETTERS = str.maketrans({"ך": "כ", "ם": "מ", "ן": "נ", "ף": "פ", "ץ": "צ"})
_BASES = ("unit", "kg")


def normalize_he(text: str) -> str:
    """Same rules as the app's normalizeText (lib/core/text/hebrew_normalizer.dart)."""
    s = _NIQQUD.sub("", text)
    s = _PUNCTUATION.sub("", s)
    s = _SEPARATORS.sub(" ", s).strip().lower()
    return s.translate(_FINAL_LETTERS)


@dataclass(frozen=True)
class Mapping:
    include: list[str]
    exclude: list[str]
    basis: str


def load_mapping(path: str) -> dict[str, Mapping]:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    mapping: dict[str, Mapping] = {}
    for ingredient_id, entry in raw.items():
        basis = entry.get("basis", "unit")
        if basis not in _BASES:
            raise ValueError(f"{ingredient_id}: basis must be one of {_BASES}, got {basis!r}")
        mapping[ingredient_id] = Mapping(
            include=list(entry["include"]), exclude=list(entry.get("exclude", [])), basis=basis
        )
    return mapping


def aggregate_store(items: list[PriceItem], mapping: dict[str, Mapping]) -> dict[str, float]:
    """Median price per ingredient at one branch. Ingredients with no match are omitted.

    `kg` basis uses the per-kilogram price of weighted items; `unit` basis uses the
    shelf price of non-weighted items.
    """
    normalized = [(normalize_he(i.name), i) for i in items]
    result: dict[str, float] = {}
    for ingredient_id, rule in mapping.items():
        include = [normalize_he(k) for k in rule.include]
        exclude = [normalize_he(k) for k in rule.exclude]
        prices: list[float] = []
        for name, item in normalized:
            if not any(k in name for k in include) or any(k in name for k in exclude):
                continue
            if rule.basis == "kg":
                if item.is_weighted:
                    prices.append(item.unit_price if item.unit_price else item.price)
            elif not item.is_weighted:
                prices.append(item.price)
        if prices:
            result[ingredient_id] = round(statistics.median(prices), 2)
    return result
