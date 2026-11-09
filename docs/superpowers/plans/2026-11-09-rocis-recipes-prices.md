---
ontology: true
type: plan
domain: rocis-recipes
summary: Plan 2 of 3 for ROCIsRecipes, per-branch price snapshot refreshed by GitHub Actions, GPS nearest store, NIS totals per chain
tags: [prices, shufersal, python, github-actions, gps, openstreetmap, flutter, ils]
status: draft
discovered: 2026-11-09
workspace: ROCIsSideProjects
related: [2026-11-09-rocis-recipes-design, 2026-11-09-rocis-recipes-core-app]
---

# ROCIsRecipes Prices Implementation Plan (v2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The shopping list shows an estimated NIS total for the nearest branch of each grocery chain (found with the phone's GPS), using prices that are never more than 7 days old.

**Architecture:** A dependency-free Python pipeline (`tools/price_pipeline/`) downloads each chain's published files, geocodes branch addresses with OpenStreetMap Nominatim (cached), maps catalog ingredients to products by Hebrew keywords, and writes a compact per-branch snapshot. A GitHub Actions workflow runs it twice a week and publishes the snapshot to the `data` branch. The app fetches that file when its copy is older than 3 days, keeps a bundled copy as fallback, finds the nearest branch on the device, and sums the list at that branch.

**Tech Stack:** Python 3 standard library (`urllib`, `gzip`, `xml.etree`, `unittest`), GitHub Actions, Flutter packages `http`, `geolocator`, `url_launcher`, `path_provider` (verify current versions on pub.dev when adding), existing `intl`.

**Spec:** `docs/superpowers/specs/2026-11-09-rocis-recipes-design.md`. Builds on `docs/superpowers/plans/2026-11-09-rocis-recipes-core-app.md` (merged).

## Spike findings this plan relies on (measured 2026-11-09)

- Shufersal portal `https://prices.shufersal.co.il/` is public, no login. Files are gzip, UTF-8 with BOM, XML `<Root>` with `<Item>` entries. Download links are signed Azure blob URLs that expire within about an hour, so links are scraped and used immediately.
- Category filter URL that worked: `/FileObject/UpdateCategory?catID={n}&storeId=0&sort=Size&sortdir=DESC&page={p}`. `catID=2` returned `PriceFull` files, `catID=5` returned the `Stores` file.
- One branch `PriceFull` file: 94 KB gzipped, 1.6 MB XML, 1,940 items. Item fields: `ItemCode` (barcode), `ItemName`, `ManufactureName`, `Quantity`, `UnitOfMeasure`, `bIsWeighted`, `ItemPrice`, `UnitOfMeasurePrice`, `PriceUpdateTime`.
- The Shufersal `Stores` file lists 417 branches with `StoreID`, `StoreName`, `Address`, `City` (a numeric code, not a name) and `ZIPCode`. It has no coordinates.
- Carrefour portal `https://prices.carrefour.co.il/` looks public (73 pages, category and store filters), download not yet tried.
- `url.publishedprices.co.il` (reportedly Rami Levy, Yochananof and others) needs a username and password. Out of scope.
- Google Maps data was rejected: as understood from Google's terms (not verified against the live page), coordinates may be cached for only about 30 days, it needs a billing account, and an API key in an app is a leak risk.

## Global Constraints

- Prices are NIS (ILS), shown with the shekel sign; Hebrew default, English supported.
- Free only: GitHub Actions and raw file hosting on a public repo, OpenStreetMap Nominatim (identifying `User-Agent`, at most 1 request per second, results cached), device GPS. No paid service, no billing account.
- No secrets anywhere in the repo. The snapshot contains only public price and address data. Commits use the GitHub noreply identity.
- No credential-gated sources and no account sign-ups.
- Location: request coarse location only, use it only on the device, never send it anywhere.
- The only network calls the app makes for prices go to `raw.githubusercontent.com` for the snapshot. Navigation opens Google Maps via a link the user taps.
- Freshness: the snapshot is rebuilt at least twice a week. The app refreshes when its copy is older than 3 days and warns when the snapshot it is using is older than 7 days.
- Every price is an estimate and is labelled so. Unpriced items are shown as unpriced, never as zero.
- Attribution "Map data from OpenStreetMap contributors" is shown in the app (ODbL).
- Zero hardcoded UI strings; all strings in `app_he.arb` and `app_en.arb`.
- Quality gate per task: `flutter analyze` clean and `flutter test` passes for Dart tasks; `python -m unittest discover -s tools/price_pipeline/tests` passes for pipeline tasks.

## Review Focus

1. Location permission denied, location services off, or no GPS fix: the user picks a branch manually; no crash (Task 9).
2. The user is far from every branch of a chain (more than 50 km): say so instead of showing a distant branch as nearest (Tasks 8 and 9).
3. A branch whose address could not be geocoded is excluded from nearest-branch search, never placed at 0,0 (Tasks 3 and 5).
4. Snapshot download fails, is truncated or is corrupt: keep the cached or bundled snapshot and show the stale warning if it is over 7 days old (Task 7).
5. An ingredient with no price at the chosen branch: unpriced, total flagged partial; a chain with no priced items shows "no data" (Task 9).
6. Price entries of 0, negative or missing, and weighted items needing the per-kilogram price (Tasks 1 and 4).

## Decisions made (my calls, for the user to check)

- Snapshot is published to a `data` branch of the public repo `RoeeIlouz/ROCIsRecipes` and fetched from raw.githubusercontent.com.
- The workflow runs Sunday and Wednesday, so one failed run still leaves the data at most 7 days old. GitHub may disable scheduled workflows after 60 days without repository activity; the stale warning covers that and the README documents the fix.
- Prices are per branch (median of matching products within the branch). One list item counts as one typical purchase; list quantities are not multiplied.
- Only ingredients with a keyword mapping get prices (about 60 at first).
- Chains: Shufersal first. Carrefour is added only if its files download without login and parse the same way.
- Navigation uses a Google Maps URL (`https://www.google.com/maps/search/?api=1&query=<address>`), no API key.

---

## File Structure

```
tools/price_pipeline/
  README.md  price_items.py  shufersal.py  stores.py  geocode.py
  matching.py  ingredient_products.json  geocode_cache.json  build_snapshot.py
  tests/{fixtures/, test_*.py}
.github/workflows/prices.yml
assets/prices/snapshot.json.gz            # bundled fallback, generated
lib/features/prices/{price_snapshot.dart, price_repository.dart, nearest_store.dart,
                     location_provider.dart, price_service.dart, ui/price_summary.dart}
```

---

### Task 1: PriceFull parser

**Files:** Create `tools/price_pipeline/price_items.py`, `tests/test_price_items.py`, `tests/fixtures/price_sample.xml` (trimmed copy of the real 19-item Shufersal file from the spike).

**Interfaces:** Produces `@dataclass(frozen=True) class PriceItem: code: str; name: str; price: float; unit_price: float | None; unit_of_measure: str; is_weighted: bool` and `def parse_price_full(xml_bytes: bytes) -> list[PriceItem]`.

- [ ] **Step 1: Write failing tests** (`unittest`): `test_parses_utf8_bom_xml` (fixture gives 19 items with non-empty code and name), `test_weighted_item_uses_unit_price` (inline XML, `bIsWeighted` 1, `UnitOfMeasurePrice` 12.5 gives `is_weighted=True`, `unit_price=12.5`), `test_skips_zero_negative_and_missing_prices`, `test_handles_utf16_xml`.
- [ ] **Step 2:** Run `python -m unittest discover -s tools/price_pipeline/tests`. Expected: FAIL.
- [ ] **Step 3:** Implement with `xml.etree.ElementTree`, decoding BOM or UTF-16 first.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat(prices): PriceFull parser`.

---

### Task 2: Shufersal listing, download and Stores file

**Files:** Create `shufersal.py`, `stores.py`, `tests/test_shufersal.py`, `tests/test_stores.py`, fixtures `shufersal_pricefull_list.html` and `shufersal_stores_sample.xml` (about 5 stores trimmed from the real Stores file).

**Interfaces:**
- `@dataclass(frozen=True) class FileLink: name: str; url: str; store_id: str`
- `def parse_listing(html: str) -> list[FileLink]` (unescapes `&amp;`)
- `def list_files(cat_id: int, page: int) -> list[FileLink]` (network)
- `def download_items(link: FileLink) -> list[PriceItem]` (network: download, gunzip, `parse_price_full`)
- `@dataclass(frozen=True) class Store: chain: str; store_id: str; name: str; address: str; city_code: str; zip_code: str`
- `def parse_stores(xml_bytes: bytes, chain: str) -> list[Store]`
- `def fetch_stores() -> list[Store]` and `def fetch_chain_items(store_ids: list[str], pause_seconds: float = 0.5) -> dict[str, list[PriceItem]]` (network)

- [ ] **Step 1: Write failing tests:** `test_parse_listing_extracts_links` (20 links, names start with `PriceFull`, no `&amp;` in urls, `store_id` parsed from the file name), `test_parse_listing_empty_html_returns_empty`, `test_parse_stores_reads_fields` (fixture gives the expected store ids, Hebrew name, address, city code, zip).
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement with `urllib.request` and a descriptive `User-Agent`; `fetch_chain_items` pauses between downloads. Network functions are exercised in Task 5.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat(prices): Shufersal listing, download and stores`.

---

### Task 3: Geocode branches with OpenStreetMap

**Files:** Create `tools/price_pipeline/geocode.py`, `tests/test_geocode.py`, `geocode_cache.json` (generated).

**Interfaces:** `@dataclass(frozen=True) class GeoPoint: lat: float; lng: float`; `def build_query(store: Store, city_names: dict[str, str]) -> str`; `def parse_nominatim(json_text: str) -> GeoPoint | None` (takes the first result, rejects points outside Israel's bounding box, roughly lat 29.4 to 33.4 and lng 34.2 to 35.9); `def geocode_stores(stores: list[Store], cache_path: str, city_names: dict[str, str], pause_seconds: float = 1.1) -> dict[str, GeoPoint]` keyed by `"{chain}:{store_id}"`; cached entries are never re-requested; failures are cached as null for 30 days and not retried before then.

- [ ] **Step 1: Write failing tests:** `test_parse_nominatim_returns_first_result`, `test_parse_nominatim_empty_list_is_none`, `test_point_outside_israel_is_rejected` (Review Focus 3: for example 0,0), `test_cached_store_is_not_requested_again` (inject a fake fetch function), `test_failed_geocode_is_cached_as_none`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement. City codes are numeric; find an authoritative open list of Israeli settlement codes and names (for example a data.gov.il settlements dataset; verify it exists and check its license) and load it into `city_names`. If none is usable, geocode with street plus zip code instead and record that choice in the README. Requests send `User-Agent: ROCIsRecipes price pipeline (github.com/RoeeIlouz/ROCIsRecipes)` and wait at least 1 second between requests.
- [ ] **Step 4:** Run the tests. Expected: PASS. Then run it for real on all Shufersal branches and report the hit rate. If under 80 percent, stop and report before continuing.
- [ ] **Step 5:** Commit `feat(prices): branch geocoding with cache`.

---

### Task 4: Ingredient matching and per-branch aggregation

**Files:** Create `matching.py`, `ingredient_products.json`, `tests/test_matching.py`.

**Interfaces:** `normalize_he(text: str) -> str` (same rules as the app's `normalizeText`); `@dataclass(frozen=True) class Mapping: include: list[str]; exclude: list[str]; basis: str` (`"unit"` or `"kg"`); `load_mapping(path: str) -> dict[str, Mapping]`; `def aggregate_store(items: list[PriceItem], mapping: dict[str, Mapping]) -> dict[str, float]` returning ingredient id to median price at that branch (`kg` basis uses the `unit_price` of weighted items, `unit` basis uses `price` of non-weighted items; no match omits the ingredient).

- [ ] **Step 1: Write failing tests** with synthetic items: `test_median_within_branch`, `test_include_and_exclude_keywords` (chocolate milk is not milk), `test_kg_basis_ignores_non_weighted_items`, `test_unit_basis_ignores_weighted_items` (Review Focus 6), `test_no_match_omits_ingredient`, `test_matching_ignores_niqqud_and_final_letters`, `test_normalize_he_matches_app_rules` (`'  עַגְבָנִיּוֹת  '` gives `'עגבניות'`, `'לחם '` gives `'לחמ'`).
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement. Author `ingredient_products.json` for about 60 of the most used ingredient ids in `assets/data/ingredients.json`, with Hebrew `include` and `exclude` keywords and the right `basis`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat(prices): ingredient matching and aggregation`.

---

### Task 5: Snapshot builder and first real snapshot

**Files:** Create `build_snapshot.py`, `tests/test_build_snapshot.py`, `tools/price_pipeline/README.md`, `assets/prices/snapshot.json.gz` (generated).

**Interfaces:** `def build_snapshot(stores: list[StoreEntry], generated_at: str) -> dict` where `StoreEntry` is `chain`, `store_id`, `name`, `address`, `point: GeoPoint | None`, `prices: dict[str, float]`. Snapshot JSON: `{"version":1,"generatedAt":"YYYY-MM-DD","currency":"ILS","chains":[{"id":"shufersal","nameHe":"שופרסל","nameEn":"Shufersal"}],"stores":[{"id":"shufersal:756","chain":"shufersal","name":"...","address":"...","lat":32.1,"lng":34.8,"prices":{"egg":12.9}}]}`. Stores without a geocoded point are left out. CLI: `python tools/price_pipeline/build_snapshot.py --chains shufersal --out assets/prices/snapshot.json.gz`.

- [ ] **Step 1: Write failing tests:** `test_snapshot_shape`, `test_stores_without_coordinates_are_omitted` (Review Focus 3), `test_prices_rounded_to_two_decimals`, `test_deterministic_for_same_input`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the builder and CLI, run it against the live Shufersal portal, and report: number of stores with coordinates, mapped ingredients that got a price at a typical branch, and the gzipped file size. If the gzipped file exceeds 1 MB, reduce it (fewer branches per city or shorter keys) before committing.
- [ ] **Step 4:** Run the tests. Expected: PASS; the generated file parses.
- [ ] **Step 5:** Commit `feat(prices): snapshot builder and first snapshot`.

---

### Task 6: Weekly GitHub Actions workflow

**Files:** Create `.github/workflows/prices.yml`; modify `tools/price_pipeline/README.md`.

- [ ] **Step 1:** Write the workflow: triggers `schedule` (cron Sunday and Wednesday at 03:00 UTC) and `workflow_dispatch`; sets up Python; runs the pipeline unit tests, then `build_snapshot.py`; publishes `snapshot.json.gz` plus `manifest.json` (`generatedAt`, `sha256`, `bytes`) to the `data` branch with the built-in `GITHUB_TOKEN` (`permissions: contents: write`), committing as the GitHub Actions bot; commits `geocode_cache.json` updates to `main` only when changed. No secrets are used.
- [ ] **Step 2:** Run it once via `gh workflow run prices.yml` and watch it with `gh run watch`. Expected: success, `data` branch contains both files. If the portal blocks GitHub's runners (HTTP 403 or timeouts), stop and report; do not work around it.
- [ ] **Step 3:** Verify `https://raw.githubusercontent.com/RoeeIlouz/ROCIsRecipes/data/manifest.json` returns the manifest.
- [ ] **Step 4:** Document in the README how to re-enable scheduled workflows and how to run the pipeline by hand.
- [ ] **Step 5:** Commit `ci(prices): weekly snapshot workflow`.

---

### Task 7: Snapshot model, repository and refresh (Dart)

**Files:** Create `lib/features/prices/price_snapshot.dart`, `price_repository.dart`; modify `pubspec.yaml`, `lib/core/services/app_initializer.dart`, `test/helpers/test_env.dart`; Test `test/features/prices/price_repository_test.dart`.

**Interfaces:**
- `class PriceChain { final String id; final String nameHe; final String nameEn; }`
- `class PriceStore { final String id; final String chainId; final String name; final String address; final double lat; final double lng; final Map<String, double> prices; }`
- `class PriceSnapshot { final DateTime generatedAt; final List<PriceChain> chains; final List<PriceStore> stores; factory PriceSnapshot.fromJson(Map<String, dynamic>); factory PriceSnapshot.fromGzipBytes(List<int> bytes); bool isOlderThan(Duration age, DateTime now); }`
- `abstract class SnapshotSource { Future<List<int>?> fetch(); }` with `HttpSnapshotSource(Uri url, http.Client client)`.
- `class PriceRepository extends ChangeNotifier { PriceRepository({required this.bundled, required this.source, required this.cacheDir}); PriceSnapshot get snapshot; bool get isStale; Future<void> init(); Future<void> refreshIfNeeded(DateTime now); }`. `init` loads the cached file if present and newer than the bundled one, else the bundled one. `refreshIfNeeded` fetches only when the current snapshot is older than 3 days; it replaces the cache only if the download parses and is newer; any error keeps the current snapshot. `isStale` is true when the current snapshot is older than 7 days.

- [ ] **Step 1: Write failing tests** with a fake `SnapshotSource`: `uses the bundled snapshot when no cache exists`, `refresh replaces the snapshot when the download is newer`, `corrupt download keeps the current snapshot` (Review Focus 4), `network failure keeps the current snapshot and reports stale when over 7 days`, `no download is attempted when the snapshot is under 3 days old`, `fromGzipBytes round-trips the builder output shape`.
- [ ] **Step 2:** Run `flutter test test/features/prices`. Expected: FAIL.
- [ ] **Step 3:** Implement; add `http` and `path_provider` after checking their current versions; the fetch has a 10 second timeout and runs in the background after startup, never blocking launch.
- [ ] **Step 4:** Run the tests and `flutter analyze`. Expected: PASS, no issues.
- [ ] **Step 5:** Commit `feat(prices): snapshot model, cache and refresh`.

---

### Task 8: GPS and nearest branch (Dart)

**Files:** Create `lib/features/prices/nearest_store.dart`, `location_provider.dart`; modify `android/app/src/main/AndroidManifest.xml` (add `ACCESS_COARSE_LOCATION` only), `pubspec.yaml`; Test `test/features/prices/nearest_store_test.dart`.

**Interfaces:**
- `double haversineKm(double lat1, double lng1, double lat2, double lng2)`
- `class NearestResult { final PriceStore store; final double distanceKm; }`
- `NearestResult? nearestStore(List<PriceStore> stores, String chainId, double lat, double lng, {double maxKm = 50})` returns null when no branch of the chain is within `maxKm`.
- `enum LocationStatus { granted, denied, deniedForever, serviceOff, unavailable }`; `class UserLocation { final double lat; final double lng; }`; `abstract class LocationProvider { Future<LocationStatus> requestPermission(); Future<UserLocation?> currentLocation(); }` with `GeolocatorLocationProvider` using coarse accuracy.

- [ ] **Step 1: Write failing tests:** `haversine between Tel Aviv and Jerusalem is about 54 km` (use real coordinates, tolerance 2 km), `nearest picks the closest branch of the requested chain only`, `returns null when every branch is farther than 50 km` (Review Focus 2), `ignores stores of other chains`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement. Add `geolocator` after checking its current version and Android setup notes.
- [ ] **Step 4:** Run the tests and `flutter analyze`. Expected: PASS, no issues.
- [ ] **Step 5:** Commit `feat(prices): GPS and nearest branch`.

---

### Task 9: Price service and shopping list UI

**Files:** Create `lib/features/prices/price_service.dart`, `ui/price_summary.dart`; modify `lib/features/pantry/settings_repository.dart`, `lib/features/shopping/ui/shopping_screen.dart`, `test/helpers/test_env.dart`, ARB files, `pubspec.yaml` (`url_launcher`); Tests `test/features/prices/price_service_test.dart`, `test/features/prices/price_ui_test.dart`.

**Interfaces:**
- `class ChainTotal { final String chainId; final PriceStore? store; final double? distanceKm; final double total; final int pricedCount; final int unpricedCount; bool get hasData; bool get isPartial; }`
- `class PriceService { ChainTotal totalFor(List<ShoppingItem> items, PriceStore? store); }` counts unchecked items only; items without an `ingredientId` are unpriced.
- `SettingsRepository.manualStoreIds -> Map<String, String>` (chain id to chosen branch id) with `setManualStore(String chainId, String storeId)`.
- `class PriceSummary extends StatefulWidget`: asks for location once with a short rationale, then shows per chain: branch name, distance, total in NIS with shekel sign, "estimate" label, partial flag with unpriced count, "no data" message, a Navigate button, a stale warning when `PriceRepository.isStale`, the OpenStreetMap attribution; when location is not available it shows a branch picker per chain.

- [ ] **Step 1: Write failing tests:** service: `totals sum unchecked priced items at the given branch`, `checked items are ignored`, `unpriced item is excluded and total is partial`, `no priced items means no data` (Review Focus 5), `custom items count as unpriced`. UI (with a fake `LocationProvider` and in-memory snapshot): `shows a total per chain in NIS for the nearest branch`, `denied location shows the branch picker and persists the choice` (Review Focus 1), `far from all branches shows a too far message` (Review Focus 2), `stale snapshot shows a warning`, `navigate opens a Google Maps search link for the branch address` (inject a fake launcher), `price line appears under priced items`.
- [ ] **Step 2:** Run `flutter test test/features/prices`. Expected: FAIL.
- [ ] **Step 3:** Implement with `NumberFormat.currency(locale: ..., symbol: '₪')`; add Hebrew and English strings; wire `PriceRepository.refreshIfNeeded` once after the first frame.
- [ ] **Step 4:** Run `flutter test` and `flutter analyze`. Expected: PASS, no issues.
- [ ] **Step 5:** Commit `feat(prices): nearest branch totals on the shopping list`.

---

### Task 10: Add Carrefour if its files match

**Files:** Modify `tools/price_pipeline/` (add `carrefour.py` mirroring `shufersal.py`), `build_snapshot.py`, the workflow if needed.

- [ ] **Step 1:** Fetch the Carrefour listing and download one `PriceFull` and its `Stores` file. Report: no login needed, format, encoding, whether `parse_price_full` and `parse_stores` handle them.
- [ ] **Step 2:** Decision rule: if no login is needed and both parsers work, add `carrefour.py` with a listing fixture test like Task 2, add the chain to the builder, rebuild, and check the size limit. Otherwise stop, record the finding in the README, and do not add the chain.
- [ ] **Step 3:** Run all pipeline tests and `flutter test`. Expected: PASS.
- [ ] **Step 4:** Commit `feat(prices): add Carrefour` or `docs(prices): Carrefour not usable, findings`.

---

## Self-Review

- Spec coverage: goal 4 (NIS totals at nearby chains) is covered by Tasks 1 to 9, with GPS nearest branch (Tasks 3, 8, 9) and the 7-day freshness limit (Tasks 6, 7, 9). Chains needing a login are out by the design rule. Photo input, user recipes and ROCIsTasks sync stay in Plan 3.
- Types are used consistently: `PriceItem`, `Store`, `GeoPoint`, `Mapping`, `PriceSnapshot`, `PriceStore`, `PriceRepository`, `NearestResult`, `LocationProvider`, `ChainTotal`, `PriceService`.
- Open risks: the portal may block GitHub's runners (Task 6 stops and reports), geocode hit rate (Task 3 stops under 80 percent), keyword matching quality (Task 5 reports real coverage), and scheduled workflows pausing after 60 idle days (stale warning plus README).
