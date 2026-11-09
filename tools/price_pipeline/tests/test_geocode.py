import json
import sys
import tempfile
import unittest
import urllib.parse
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from geocode import (  # noqa: E402
    GeoPoint,
    build_query,
    display_address,
    fallback_queries,
    geocode_stores,
    parse_city_names,
    parse_nominatim,
    with_retries,
)
from stores import Store  # noqa: E402


def _store(store_id="1", address="הרצל 5", city="5000") -> Store:
    return Store("shufersal", store_id, "שלי", address, city, "123")


class _FakeFetch:
    def __init__(self, response: str):
        self.response = response
        self.urls: list[str] = []

    def __call__(self, url: str) -> str:
        self.urls.append(url)
        return self.response


class ParseNominatimTest(unittest.TestCase):
    def test_parse_nominatim_returns_first_result(self):
        point = parse_nominatim('[{"lat":"32.0853","lon":"34.7818"},{"lat":"31.0","lon":"35.0"}]')
        self.assertEqual(point, GeoPoint(32.0853, 34.7818))

    def test_parse_nominatim_empty_list_is_none(self):
        self.assertIsNone(parse_nominatim("[]"))

    def test_parse_nominatim_invalid_json_is_none(self):
        self.assertIsNone(parse_nominatim("<html>rate limited</html>"))

    def test_point_outside_israel_is_rejected(self):
        self.assertIsNone(parse_nominatim('[{"lat":"0","lon":"0"}]'))
        self.assertIsNone(parse_nominatim('[{"lat":"51.5","lon":"-0.12"}]'))


class BuildQueryTest(unittest.TestCase):
    def test_query_uses_address_and_city_name(self):
        self.assertEqual(build_query(_store(), {"5000": "תל אביב"}), "הרצל 5, תל אביב, ישראל")

    def test_street_abbreviations_are_expanded_or_dropped(self):
        names = {"5000": "חיפה"}
        cases = {
            "רח' גוט לוין 48": "גוט לוין 48, חיפה, ישראל",
            "רח.משה שפירא 28": "משה שפירא 28, חיפה, ישראל",
            "שד' מנחם בגין 2": "שדרות מנחם בגין 2, חיפה, ישראל",
            "שד.אח\"י אילת 20": "שדרות אחי אילת 20, חיפה, ישראל",
            "רח. שדרות התמרים 37": "שדרות התמרים 37, חיפה, ישראל",
        }
        for raw, expected in cases.items():
            self.assertEqual(build_query(_store(address=raw, city="5000"), names), expected, raw)

    def test_display_address_has_street_and_city_but_no_country(self):
        names = {"5000": "תל אביב - יפו"}
        self.assertEqual(display_address(_store(address="רח' הרצל 5"), names), "הרצל 5, תל אביב-יפו")
        self.assertEqual(display_address(_store(city="9999"), names), "הרצל 5")

    def test_missing_space_before_house_number_is_inserted(self):
        names = {"5000": "חיפה"}
        self.assertEqual(build_query(_store(address="אבן גבירול157", city="5000"), names), "אבן גבירול 157, חיפה, ישראל")

    def test_dashed_city_names_are_tightened(self):
        names = {"5000": "תל אביב - יפו"}
        self.assertEqual(build_query(_store(), names), "הרצל 5, תל אביב-יפו, ישראל")

    def test_fallback_queries_drop_the_house_number(self):
        names = {"5000": "חיפה"}
        self.assertEqual(
            fallback_queries(_store(address="הרצל 5"), names),
            ["הרצל 5, חיפה, ישראל", "הרצל, חיפה, ישראל"],
        )

    def test_fallback_queries_without_a_number_has_one_query(self):
        names = {"5000": "חיפה"}
        self.assertEqual(fallback_queries(_store(address="קניון הצפון"), names), ["קניון הצפון, חיפה, ישראל"])

    def test_corner_of_tail_is_dropped(self):
        names = {"5000": "ראש העין"}
        self.assertEqual(build_query(_store(address="בזק 1 פינת ברקן"), names), "בזק 1, ראש העין, ישראל")

    def test_unknown_city_code_falls_back_to_address_only(self):
        self.assertEqual(build_query(_store(city="9999"), {"5000": "תל אביב"}), "הרצל 5, ישראל")


class WithRetriesTest(unittest.TestCase):
    def test_succeeds_after_transient_failures(self):
        calls = []

        def flaky():
            calls.append(1)
            if len(calls) < 3:
                raise TimeoutError("slow")
            return "ok"

        self.assertEqual(with_retries(flaky, attempts=3, sleep=lambda _s: None), "ok")
        self.assertEqual(len(calls), 3)

    def test_raises_after_last_attempt(self):
        def always():
            raise TimeoutError("slow")

        with self.assertRaises(TimeoutError):
            with_retries(always, attempts=2, sleep=lambda _s: None)


class ParseCityNamesTest(unittest.TestCase):
    def test_parse_city_names_strips_padding(self):
        data = {"result": {"records": [{"סמל_ישוב": 2530, "שם_ישוב": "באר יעקב                 "}]}}
        self.assertEqual(parse_city_names(json.dumps(data, ensure_ascii=False)), {"2530": "באר יעקב"})


class GeocodeStoresTest(unittest.TestCase):
    RESPONSE = '[{"lat":"32.0853","lon":"34.7818"}]'

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.cache = str(Path(self.tmp.name) / "cache.json")

    def tearDown(self):
        self.tmp.cleanup()

    def _run(self, stores, fetch, today=date(2026, 11, 9)):
        return geocode_stores(stores, self.cache, {"5000": "תל אביב"}, pause_seconds=0, fetch=fetch,
                              sleep=lambda _s: None, today=today)

    def test_geocodes_and_keys_by_chain_and_store(self):
        result = self._run([_store("7")], _FakeFetch(self.RESPONSE))
        self.assertEqual(result, {"shufersal:7": GeoPoint(32.0853, 34.7818)})

    def test_cached_store_is_not_requested_again(self):
        fetch = _FakeFetch(self.RESPONSE)
        self._run([_store("7")], fetch)
        self._run([_store("7")], fetch)
        self.assertEqual(len(fetch.urls), 1)

    def test_changed_address_is_requested_again(self):
        fetch = _FakeFetch(self.RESPONSE)
        self._run([_store("7", address="הרצל 5")], fetch)
        self._run([_store("7", address="ויצמן 9")], fetch)
        self.assertEqual(len(fetch.urls), 2)

    def test_failed_geocode_is_cached_as_none_for_30_days(self):
        fetch = _FakeFetch("[]")
        self.assertEqual(self._run([_store("8")], fetch), {})
        self.assertEqual(len(fetch.urls), 2)  # full address, then street only
        self._run([_store("8")], fetch, today=date(2026, 12, 8))
        self.assertEqual(len(fetch.urls), 2)
        self._run([_store("8")], fetch, today=date(2026, 12, 10))
        self.assertEqual(len(fetch.urls), 4)

    def test_request_failure_is_skipped_not_cached(self):
        def boom(_url):
            raise OSError("network down")

        self.assertEqual(self._run([_store("9")], boom), {})
        fetch = _FakeFetch(self.RESPONSE)
        self.assertEqual(len(self._run([_store("9")], fetch)), 1)

    def test_falls_back_to_street_when_the_house_number_is_unknown(self):
        urls: list[str] = []

        def fetch(url: str) -> str:
            urls.append(url)
            # Only the street-level query (no digit in q) is known to the geocoder.
            q = urllib.parse.parse_qs(urllib.parse.urlparse(url).query)["q"][0]
            return self.RESPONSE if not any(c.isdigit() for c in q) else "[]"

        result = self._run([_store("7")], fetch)
        self.assertEqual(result, {"shufersal:7": GeoPoint(32.0853, 34.7818)})
        self.assertEqual(len(urls), 2)

    def test_old_cached_miss_is_retried_but_old_hit_is_kept(self):
        query = build_query(_store("3"), {"5000": "תל אביב"})
        Path(self.cache).write_text(json.dumps({
            "shufersal:3": {"q": query, "at": "2026-11-08", "lat": None, "lng": None},
            "shufersal:4": {"q": build_query(_store("4"), {"5000": "תל אביב"}), "at": "2026-11-08",
                            "lat": 32.1, "lng": 34.8},
        }), encoding="utf-8")
        fetch = _FakeFetch(self.RESPONSE)
        result = self._run([_store("3"), _store("4")], fetch)
        self.assertEqual(len(fetch.urls), 1)
        self.assertEqual(set(result), {"shufersal:3", "shufersal:4"})

    def test_url_is_restricted_to_israel(self):
        fetch = _FakeFetch(self.RESPONSE)
        self._run([_store("7")], fetch)
        self.assertIn("countrycodes=il", fetch.urls[0])
        self.assertIn("format=json", fetch.urls[0])


if __name__ == "__main__":
    unittest.main()
