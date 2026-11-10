import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from stores import Store, parse_stores  # noqa: E402

FIXTURE = Path(__file__).parent / "fixtures" / "shufersal_stores_sample.xml"


class ParseStoresTest(unittest.TestCase):
    def test_parse_stores_reads_fields(self):
        stores = parse_stores(FIXTURE.read_bytes(), "shufersal")
        self.assertEqual(len(stores), 5)
        first = stores[0]
        self.assertIsInstance(first, Store)
        self.assertEqual(first.chain, "shufersal")
        self.assertEqual(first.store_id, "756")
        self.assertEqual(first.city_code, "2530")
        self.assertEqual(first.zip_code, "7030336")
        self.assertTrue(first.name)
        self.assertTrue(first.address)

    def test_store_ids_are_unique(self):
        stores = parse_stores(FIXTURE.read_bytes(), "shufersal")
        self.assertEqual(len({s.store_id for s in stores}), len(stores))

    def test_store_without_id_is_skipped(self):
        xml = b"<Root><Store><StoreName>x</StoreName></Store></Root>"
        self.assertEqual(parse_stores(xml, "shufersal"), [])

    def test_unpadded_store_id(self):
        xml = b"<Root><Store><StoreID>007</StoreID><StoreName>x</StoreName><Address>a</Address><City>1</City><ZIPCode>2</ZIPCode></Store></Root>"
        (store,) = parse_stores(xml, "shufersal")
        self.assertEqual(store.store_id, "7")


if __name__ == "__main__":
    unittest.main()
