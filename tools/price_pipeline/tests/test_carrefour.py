import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from carrefour import (  # noqa: E402
    CarrefourFile,
    file_url,
    find_stores_file,
    latest_price_full,
    parse_listing,
)

FIXTURE = Path(__file__).parent / "fixtures" / "carrefour_listing.html"


class ParseListingTest(unittest.TestCase):
    def setUp(self):
        self.listing = parse_listing(FIXTURE.read_text(encoding="utf-8"))

    def test_reads_the_day_folder_and_files(self):
        self.assertEqual(self.listing.path, "20261110")
        self.assertEqual(len(self.listing.files), 7)
        self.assertTrue(all(isinstance(f, CarrefourFile) for f in self.listing.files))
        self.assertEqual(self.listing.files[0].name, "Stores7290055700007-000-20261110-000100.xml")
        self.assertGreater(self.listing.files[0].size, 0)

    def test_page_without_a_file_list_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_listing("<html><body>maintenance</body></html>")

    def test_page_without_a_day_folder_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_listing('<script>const files = [];</script>')


class SelectionTest(unittest.TestCase):
    def setUp(self):
        self.listing = parse_listing(FIXTURE.read_text(encoding="utf-8"))

    def test_latest_price_full_picks_the_newest_file_per_store(self):
        latest = latest_price_full(self.listing.files)
        self.assertEqual(set(latest), {"30", "2"})
        self.assertEqual(latest["30"].name, "PriceFull7290055700007-001-030-20261110-061001.gz")
        self.assertEqual(latest["2"].name, "PriceFull7290055700007-001-002-20261110-051007.gz")

    def test_delta_price_files_are_ignored(self):
        names = {f.name for f in latest_price_full(self.listing.files).values()}
        self.assertFalse(any(n.startswith("Price7") for n in names))

    def test_find_stores_file(self):
        self.assertEqual(find_stores_file(self.listing.files).name, "Stores7290055700007-000-20261110-000100.xml")

    def test_find_stores_file_missing_gives_none(self):
        self.assertIsNone(find_stores_file([CarrefourFile("PriceFull7290055700007-001-002-20261110-051007.gz", 1)]))

    def test_file_url(self):
        self.assertEqual(
            file_url("20261110", "x.gz"),
            "https://prices.carrefour.co.il/20261110/x.gz",
        )


if __name__ == "__main__":
    unittest.main()
