import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from matching import Mapping, aggregate_store, load_mapping, normalize_he  # noqa: E402
from price_items import PriceItem  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]


def _item(name, price, weighted=False, unit_price=None) -> PriceItem:
    return PriceItem(code=name, name=name, price=price, unit_price=unit_price,
                     unit_of_measure="kg" if weighted else "unit", is_weighted=weighted)


MILK = {"milk": Mapping(include=["חלב"], exclude=["שוקולד"], basis="unit")}


class NormalizeTest(unittest.TestCase):
    def test_normalize_he_matches_app_rules(self):
        self.assertEqual(normalize_he("  עַגְבָנִיּוֹת  "), "עגבניות")
        self.assertEqual(normalize_he("לחם "), "לחמ")
        self.assertEqual(normalize_he("Olive  OIL"), "olive oil")
        self.assertEqual(normalize_he("ג'ינג'ר"), "גינגר")
        self.assertEqual(normalize_he("פלפל-שחור"), "פלפל שחור")


class AggregateStoreTest(unittest.TestCase):
    def test_median_within_branch(self):
        items = [_item("חלב טרי 1", 5.0), _item("חלב טרי 2", 7.0), _item("חלב עיזים", 9.0)]
        self.assertEqual(aggregate_store(items, MILK), {"milk": 7.0})

    def test_include_and_exclude_keywords(self):
        items = [_item("חלב טרי", 6.0), _item("חלב שוקולד", 3.0)]
        self.assertEqual(aggregate_store(items, MILK), {"milk": 6.0})

    def test_kg_basis_ignores_non_weighted_items(self):
        mapping = {"tomato": Mapping(include=["עגבניות"], exclude=[], basis="kg")}
        items = [
            _item("עגבניות", 8.0, weighted=True, unit_price=8.0),
            _item("עגבניות שרי מארז", 12.0, weighted=False),
        ]
        self.assertEqual(aggregate_store(items, mapping), {"tomato": 8.0})

    def test_kg_basis_uses_unit_price_not_item_price(self):
        mapping = {"tomato": Mapping(include=["עגבניות"], exclude=[], basis="kg")}
        items = [_item("עגבניות", 3.0, weighted=True, unit_price=9.9)]
        self.assertEqual(aggregate_store(items, mapping), {"tomato": 9.9})

    def test_unit_basis_ignores_weighted_items(self):
        items = [_item("חלב טרי", 6.0), _item("חלב מהחבית", 20.0, weighted=True, unit_price=20.0)]
        self.assertEqual(aggregate_store(items, MILK), {"milk": 6.0})

    def test_no_match_omits_ingredient(self):
        self.assertEqual(aggregate_store([_item("לחם", 10.0)], MILK), {})

    def test_matching_ignores_niqqud_and_final_letters(self):
        mapping = {"bread": Mapping(include=["לחם"], exclude=[], basis="unit")}
        self.assertEqual(aggregate_store([_item("לֶחֶם פרוס", 9.0)], mapping), {"bread": 9.0})

    def test_prices_are_rounded_to_two_decimals(self):
        items = [_item("חלב א", 5.0), _item("חלב ב", 5.333)]
        self.assertEqual(aggregate_store(items, MILK), {"milk": 5.17})


class LoadMappingTest(unittest.TestCase):
    def test_load_mapping_reads_json(self):
        data = {"milk": {"include": ["חלב"], "exclude": ["שוקולד"], "basis": "unit"}}
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            self.assertEqual(load_mapping(str(path)), MILK)

    def test_invalid_basis_is_rejected(self):
        data = {"milk": {"include": ["חלב"], "exclude": [], "basis": "litre"}}
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            with self.assertRaises(ValueError):
                load_mapping(str(path))

    def test_real_mapping_prices_eggs_and_milk_from_typical_shufersal_names(self):
        mapping = load_mapping(str(ROOT / "tools" / "price_pipeline" / "ingredient_products.json"))
        items = [
            _item("ביצים L 12 יחידות", 14.9),
            _item("ביצים M 18 יחידות", 21.9),
            _item("ביצי שוקולד קינדר", 9.9),
            _item("חלב טרי 3% 1 ליטר", 7.5),
            _item("חלב שוקולד", 5.0),
        ]
        prices = aggregate_store(items, mapping)
        self.assertEqual(prices["egg"], 18.4)
        self.assertEqual(prices["milk"], 7.5)

    def test_real_mapping_only_uses_catalog_ingredient_ids(self):
        catalog = json.loads((ROOT / "assets" / "data" / "ingredients.json").read_text(encoding="utf-8"))
        catalog_ids = {i["id"] for i in catalog}
        mapping = load_mapping(str(ROOT / "tools" / "price_pipeline" / "ingredient_products.json"))
        self.assertGreaterEqual(len(mapping), 50)
        self.assertEqual(set(mapping) - catalog_ids, set())
        self.assertTrue(all(m.include for m in mapping.values()))


if __name__ == "__main__":
    unittest.main()
