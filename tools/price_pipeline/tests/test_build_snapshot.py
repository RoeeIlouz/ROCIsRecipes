import gzip
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from build_snapshot import StoreEntry, build_snapshot, drop_price_outliers, write_snapshot  # noqa: E402
from geocode import GeoPoint  # noqa: E402


def _entry(store_id="1", point=GeoPoint(32.0853, 34.7818), prices=None, chain="shufersal") -> StoreEntry:
    return StoreEntry(chain=chain, store_id=store_id, name="שלי " + store_id, address="הרצל 5, תל אביב",
                      point=point, prices={"egg": 12.9} if prices is None else prices)


class DropOutliersTest(unittest.TestCase):
    def _entries(self, egg_prices):
        return [_entry(str(i), prices={"egg": p}) for i, p in enumerate(egg_prices)]

    def test_drops_prices_far_from_the_cross_branch_median(self):
        entries = self._entries([10, 11, 10, 12, 11, 100, 1])
        cleaned = drop_price_outliers(entries)
        self.assertEqual([e.prices.get("egg") for e in cleaned], [10, 11, 10, 12, 11, None, None])

    def test_keeps_everything_when_there_are_too_few_branches_to_judge(self):
        entries = self._entries([10, 100])
        self.assertEqual([e.prices for e in drop_price_outliers(entries)], [{"egg": 10}, {"egg": 100}])

    def test_other_ingredients_are_untouched(self):
        entries = [_entry(str(i), prices={"egg": 10, "milk": 7}) for i in range(5)]
        entries.append(_entry("9", prices={"egg": 500, "milk": 7}))
        cleaned = drop_price_outliers(entries)
        self.assertEqual(cleaned[-1].prices, {"milk": 7})
        self.assertEqual(cleaned[0].prices, {"egg": 10, "milk": 7})


class BuildSnapshotTest(unittest.TestCase):
    def test_snapshot_shape(self):
        snap = build_snapshot([_entry("7")], "2026-11-09")
        self.assertEqual(snap["version"], 1)
        self.assertEqual(snap["generatedAt"], "2026-11-09")
        self.assertEqual(snap["currency"], "ILS")
        self.assertEqual(snap["chains"], [{"id": "shufersal", "nameHe": "שופרסל", "nameEn": "Shufersal"}])
        self.assertEqual(
            snap["stores"],
            [{"id": "shufersal:7", "chain": "shufersal", "name": "שלי 7", "address": "הרצל 5, תל אביב",
              "lat": 32.0853, "lng": 34.7818, "prices": {"egg": 12.9}}],
        )

    def test_carrefour_is_a_declared_chain(self):
        snap = build_snapshot([_entry("1", chain="shufersal"), _entry("2", chain="carrefour")], "2026-11-10")
        self.assertEqual(
            snap["chains"],
            [
                {"id": "carrefour", "nameHe": "קרפור", "nameEn": "Carrefour"},
                {"id": "shufersal", "nameHe": "שופרסל", "nameEn": "Shufersal"},
            ],
        )
        self.assertEqual([s["id"] for s in snap["stores"]], ["carrefour:2", "shufersal:1"])

    def test_stores_without_coordinates_are_omitted(self):
        snap = build_snapshot([_entry("1", point=None), _entry("2")], "2026-11-09")
        self.assertEqual([s["id"] for s in snap["stores"]], ["shufersal:2"])

    def test_stores_without_prices_are_omitted(self):
        snap = build_snapshot([_entry("1", prices={}), _entry("2")], "2026-11-09")
        self.assertEqual([s["id"] for s in snap["stores"]], ["shufersal:2"])

    def test_prices_rounded_to_two_decimals(self):
        snap = build_snapshot([_entry("1", prices={"egg": 12.3456})], "2026-11-09")
        self.assertEqual(snap["stores"][0]["prices"], {"egg": 12.35})

    def test_chains_list_only_includes_chains_with_stores(self):
        snap = build_snapshot([_entry("1", point=None)], "2026-11-09")
        self.assertEqual(snap["chains"], [])

    def test_deterministic_for_same_input(self):
        a = build_snapshot([_entry("2"), _entry("1")], "2026-11-09")
        b = build_snapshot([_entry("1"), _entry("2")], "2026-11-09")
        self.assertEqual(json.dumps(a, sort_keys=True), json.dumps(b, sort_keys=True))
        self.assertEqual([s["id"] for s in a["stores"]], ["shufersal:1", "shufersal:2"])

    def test_write_snapshot_is_gzip_json_and_byte_stable(self):
        snap = build_snapshot([_entry("1")], "2026-11-09")
        with tempfile.TemporaryDirectory() as tmp:
            first, second = Path(tmp) / "a.json.gz", Path(tmp) / "b.json.gz"
            write_snapshot(snap, str(first))
            write_snapshot(snap, str(second))
            self.assertEqual(first.read_bytes(), second.read_bytes())
            self.assertEqual(json.loads(gzip.decompress(first.read_bytes()).decode("utf-8")), snap)


if __name__ == "__main__":
    unittest.main()
