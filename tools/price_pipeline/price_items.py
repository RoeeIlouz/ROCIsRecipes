"""Parse Israeli retail price transparency files (PriceFull / Price XML)."""

from __future__ import annotations

import xml.etree.ElementTree as ET
from dataclasses import dataclass


@dataclass(frozen=True)
class PriceItem:
    code: str
    name: str
    price: float
    unit_price: float | None
    unit_of_measure: str
    is_weighted: bool


def decode_xml(data: bytes) -> str:
    """Decode a published XML file: UTF-8 (with or without BOM) or UTF-16."""
    if data[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return data.decode("utf-16")
    return data.decode("utf-8-sig", errors="replace")


def _text(item: ET.Element, tag: str) -> str:
    node = item.find(tag)
    return (node.text or "").strip() if node is not None else ""


def _number(value: str) -> float | None:
    try:
        return float(value)
    except ValueError:
        return None


def parse_price_full(xml_bytes: bytes) -> list[PriceItem]:
    """Return priced items; entries with a missing, zero or negative price are skipped."""
    text = decode_xml(xml_bytes)
    # ElementTree rejects an encoding declaration on a str, so drop it if present.
    if text.lstrip().startswith("<?xml"):
        text = text[text.index("?>") + 2 :]
    root = ET.fromstring(text)
    items: list[PriceItem] = []
    for node in root.iter("Item"):
        price = _number(_text(node, "ItemPrice"))
        if price is None or price <= 0:
            continue
        items.append(
            PriceItem(
                code=_text(node, "ItemCode"),
                name=_text(node, "ItemName"),
                price=price,
                unit_price=_number(_text(node, "UnitOfMeasurePrice")),
                unit_of_measure=_text(node, "UnitOfMeasure"),
                is_weighted=_text(node, "bIsWeighted") == "1",
            )
        )
    return items
