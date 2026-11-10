"""Build the per-branch price snapshot read by the app.

Usage:
  python tools/price_pipeline/build_snapshot.py --chains shufersal --out assets/prices/snapshot.json.gz
"""

from __future__ import annotations

import argparse
import gzip
import json
import statistics
import sys
from dataclasses import dataclass, replace
from datetime import date
from pathlib import Path

from geocode import GeoPoint, display_address, fetch_city_names, geocode_stores
from matching import aggregate_store, load_mapping

HERE = Path(__file__).resolve().parent

CHAIN_NAMES = {
    "shufersal": {"id": "shufersal", "nameHe": "שופרסל", "nameEn": "Shufersal"},
}


@dataclass(frozen=True)
class StoreEntry:
    chain: str
    store_id: str
    name: str
    address: str
    point: GeoPoint | None
    prices: dict[str, float]


def drop_price_outliers(stores: list[StoreEntry], factor: float = 4.0, min_branches: int = 5) -> list[StoreEntry]:
    """Remove a branch's price for an ingredient when it is more than `factor` times
    above or below the median across branches (a stray wrong product match).
    Ingredients seen at fewer than `min_branches` branches are left alone."""
    by_ingredient: dict[str, list[float]] = {}
    for store in stores:
        for ingredient_id, price in store.prices.items():
            by_ingredient.setdefault(ingredient_id, []).append(price)
    medians = {k: statistics.median(v) for k, v in by_ingredient.items() if len(v) >= min_branches}
    cleaned: list[StoreEntry] = []
    for store in stores:
        prices = {
            k: v
            for k, v in store.prices.items()
            if k not in medians or medians[k] / factor <= v <= medians[k] * factor
        }
        cleaned.append(replace(store, prices=prices))
    return cleaned


def build_snapshot(stores: list[StoreEntry], generated_at: str) -> dict:
    """Snapshot dict. Branches without coordinates or without any price are left out."""
    usable = sorted(
        (s for s in stores if s.point is not None and s.prices),
        key=lambda s: (s.chain, int(s.store_id) if s.store_id.isdigit() else 0, s.store_id),
    )
    chain_ids = sorted({s.chain for s in usable})
    return {
        "version": 1,
        "generatedAt": generated_at,
        "currency": "ILS",
        "chains": [CHAIN_NAMES[c] for c in chain_ids],
        "stores": [
            {
                "id": f"{s.chain}:{s.store_id}",
                "chain": s.chain,
                "name": s.name,
                "address": s.address,
                "lat": round(s.point.lat, 5),
                "lng": round(s.point.lng, 5),
                "prices": {k: round(v, 2) for k, v in sorted(s.prices.items())},
            }
            for s in usable
        ],
    }


def write_snapshot(snapshot: dict, path: str) -> None:
    """Write compact gzip JSON; mtime is pinned so identical input gives identical bytes."""
    payload = json.dumps(snapshot, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    with open(path, "wb") as raw, gzip.GzipFile(filename="", fileobj=raw, mode="wb", mtime=0, compresslevel=9) as gz:
        gz.write(payload)


def _chain_module(chain: str):
    if chain == "shufersal":
        import shufersal

        return shufersal
    raise SystemExit(f"unsupported chain: {chain}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chains", default="shufersal", help="comma separated chain ids")
    parser.add_argument("--out", required=True)
    parser.add_argument("--max-stores", type=int, default=0, help="limit branches per chain (0 = all)")
    parser.add_argument("--cache", default=str(HERE / "geocode_cache.json"))
    parser.add_argument("--mapping", default=str(HERE / "ingredient_products.json"))
    parser.add_argument("--pause", type=float, default=0.5, help="seconds between price file downloads")
    args = parser.parse_args(argv)

    mapping = load_mapping(args.mapping)
    city_names = fetch_city_names()
    entries: list[StoreEntry] = []
    for chain in [c.strip() for c in args.chains.split(",") if c.strip()]:
        module = _chain_module(chain)
        stores = module.fetch_stores()
        points = geocode_stores(stores, args.cache, city_names)
        located = [s for s in stores if f"{s.chain}:{s.store_id}" in points]
        print(f"{chain}: {len(stores)} branches, {len(located)} geocoded", file=sys.stderr)
        if args.max_stores:
            located = located[: args.max_stores]
        items_by_store = module.fetch_chain_items([s.store_id for s in located], pause_seconds=args.pause)
        for store in located:
            items = items_by_store.get(store.store_id)
            if items is None:
                continue
            entries.append(
                StoreEntry(chain, store.store_id, store.name, display_address(store, city_names),
                           points[f"{store.chain}:{store.store_id}"], aggregate_store(items, mapping))
            )

    snapshot = build_snapshot(drop_price_outliers(entries), date.today().isoformat())
    write_snapshot(snapshot, args.out)
    priced = {k for s in snapshot["stores"] for k in s["prices"]}
    print(
        f"wrote {args.out}: {len(snapshot['stores'])} branches, "
        f"{len(priced)}/{len(mapping)} mapped ingredients priced, {Path(args.out).stat().st_size // 1024} KB",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
