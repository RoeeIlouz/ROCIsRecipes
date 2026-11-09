import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from shufersal import FileLink, parse_listing  # noqa: E402

FIXTURE = Path(__file__).parent / "fixtures" / "shufersal_pricefull_list.html"


class ParseListingTest(unittest.TestCase):
    def test_parse_listing_extracts_links(self):
        links = parse_listing(FIXTURE.read_text(encoding="utf-8"))
        self.assertEqual(len(links), 20)
        self.assertTrue(all(isinstance(link, FileLink) for link in links))
        self.assertTrue(all(link.name.startswith("PriceFull") for link in links))
        self.assertTrue(all("&amp;" not in link.url for link in links))
        self.assertTrue(all(link.url.startswith("https://") for link in links))

    def test_store_id_is_parsed_without_padding(self):
        links = parse_listing(FIXTURE.read_text(encoding="utf-8"))
        first = links[0]
        self.assertEqual(first.name, "PriceFull7290027600007-005-688-20261109-185129.gz")
        self.assertEqual(first.store_id, "688")

    def test_parse_listing_empty_html_returns_empty(self):
        self.assertEqual(parse_listing("<html><body>nothing</body></html>"), [])

    def test_link_without_store_pattern_has_empty_store_id(self):
        html = '<a href="https://pricesprodpublic.blob.core.windows.net/x/Stores7290027600007-000-20261109-020.gz?sv=1&amp;sig=a">d</a>'
        (link,) = parse_listing(html)
        self.assertEqual(link.store_id, "")
        self.assertIn("sv=1&sig=a", link.url)


if __name__ == "__main__":
    unittest.main()
