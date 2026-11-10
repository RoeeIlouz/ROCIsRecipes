import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from commons import Candidate, clean_author, is_allowed_license, parse_candidates, pick  # noqa: E402

FIXTURE = Path(__file__).parent / "fixtures" / "commons_search.json"


def _c(title="File:Dish.jpg", width=1200, height=800, license="CC BY-SA 4.0", author="X") -> Candidate:
    return Candidate(
        title=title,
        thumb_url="https://upload.wikimedia.org/x.jpg",
        width=width,
        height=height,
        license=license,
        author=author,
        source_url="https://commons.wikimedia.org/wiki/" + title,
    )


class ParseCandidatesTest(unittest.TestCase):
    def setUp(self):
        self.candidates = parse_candidates(FIXTURE.read_text(encoding="utf-8"))

    def test_reads_every_page_in_search_rank_order(self):
        self.assertEqual(len(self.candidates), 8)
        self.assertEqual(self.candidates[0].title, "File:Shakshuka by Calliopejen1.jpg")

    def test_reads_license_size_and_urls(self):
        first = self.candidates[0]
        self.assertEqual(first.license, "CC BY-SA 3.0")
        self.assertEqual((first.width, first.height), (3984, 2988))
        self.assertTrue(first.thumb_url.startswith("https://"))
        self.assertIn("wikimedia.org", first.thumb_url)
        self.assertEqual(first.source_url, "https://commons.wikimedia.org/wiki/File:Shakshuka_by_Calliopejen1.jpg")

    def test_author_html_is_cleaned(self):
        for candidate in self.candidates:
            self.assertNotIn("<", candidate.author)
            self.assertNotIn("&amp;", candidate.author)
            self.assertTrue(candidate.author)

    def test_empty_or_invalid_response_gives_no_candidates(self):
        self.assertEqual(parse_candidates('{"batchcomplete":""}'), [])
        self.assertEqual(parse_candidates("<html>rate limited</html>"), [])


class LicenseTest(unittest.TestCase):
    def test_allowed_licenses(self):
        for name in ["CC0", "CC0 1.0", "Public domain", "CC BY 2.0", "CC BY 4.0", "CC BY-SA 3.0", "CC BY-SA 4.0", "cc by-sa 2.5"]:
            self.assertTrue(is_allowed_license(name), name)

    def test_rejected_licenses(self):
        for name in ["CC BY-NC 2.0", "CC BY-ND 4.0", "CC BY-NC-SA 3.0", "GFDL", "All rights reserved", "", "Fair use"]:
            self.assertFalse(is_allowed_license(name), name)


class CleanAuthorTest(unittest.TestCase):
    def test_strips_links_and_entities(self):
        html = '<a href="//commons.wikimedia.org/wiki/User:X" title="User:X">Calliopejen1</a> &amp; friends'
        self.assertEqual(clean_author(html), "Calliopejen1 & friends")

    def test_collapses_whitespace_and_keeps_hebrew(self):
        self.assertEqual(clean_author("  שמרי\n\n הנסיך   "), "שמרי הנסיך")

    def test_empty_becomes_unknown(self):
        self.assertEqual(clean_author(""), "Unknown")
        self.assertEqual(clean_author("<span></span>"), "Unknown")

    def test_very_long_author_is_truncated(self):
        self.assertLessEqual(len(clean_author("a" * 500)), 80)


class PickTest(unittest.TestCase):
    def test_picks_the_first_acceptable_candidate(self):
        chosen = pick([_c("File:A.jpg"), _c("File:B.jpg")])
        self.assertEqual(chosen.title, "File:A.jpg")

    def test_skips_small_photos(self):
        self.assertEqual(pick([_c("File:Small.jpg", width=640, height=480), _c("File:Big.jpg")]).title, "File:Big.jpg")

    def test_skips_disallowed_licenses(self):
        self.assertEqual(pick([_c("File:NC.jpg", license="CC BY-NC 2.0"), _c("File:Ok.jpg")]).title, "File:Ok.jpg")

    def test_skips_extreme_aspect_ratios(self):
        tall = _c("File:Tall.jpg", width=800, height=2000)
        wide = _c("File:Wide.jpg", width=4000, height=1000)
        self.assertEqual(pick([tall, wide, _c("File:Ok.jpg")]).title, "File:Ok.jpg")

    def test_skips_non_jpeg_files(self):
        self.assertEqual(pick([_c("File:Drawing.svg"), _c("File:Photo.png"), _c("File:Ok.jpeg")]).title, "File:Ok.jpeg")

    def test_returns_none_when_nothing_is_acceptable(self):
        self.assertIsNone(pick([_c(width=100, height=100), _c(license="GFDL")]))
        self.assertIsNone(pick([]))


if __name__ == "__main__":
    unittest.main()
