"""Parse the published Stores file of a retail chain."""

from __future__ import annotations

import xml.etree.ElementTree as ET
from dataclasses import dataclass

from price_items import decode_xml


@dataclass(frozen=True)
class Store:
    chain: str
    store_id: str
    name: str
    address: str
    city_code: str
    zip_code: str


def normalize_store_id(raw: str) -> str:
    """Store ids are published zero-padded in file names and plain in Stores files."""
    raw = raw.strip()
    return str(int(raw)) if raw.isdigit() else raw


def _child_text(node: ET.Element, tag: str) -> str:
    for child in node:
        if child.tag.lower() == tag.lower():
            return (child.text or "").strip()
    return ""


def parse_stores(xml_bytes: bytes, chain: str) -> list[Store]:
    text = decode_xml(xml_bytes)
    if text.lstrip().startswith("<?xml"):
        text = text[text.index("?>") + 2 :]
    root = ET.fromstring(text)
    stores: list[Store] = []
    for node in root.iter():
        if node.tag.lower() != "store":
            continue
        store_id = _child_text(node, "StoreID")
        if not store_id:
            continue
        stores.append(
            Store(
                chain=chain,
                store_id=normalize_store_id(store_id),
                name=_child_text(node, "StoreName"),
                address=_child_text(node, "Address"),
                city_code=_child_text(node, "City"),
                zip_code=_child_text(node, "ZIPCode"),
            )
        )
    return stores
