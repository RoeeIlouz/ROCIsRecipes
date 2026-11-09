---
ontology: true
type: plan
domain: rocis-recipes
summary: Plan 2 of 3 for ROCIsRecipes, price snapshot pipeline and per-chain shopping list totals in NIS
tags: [prices, shufersal, python, flutter, ils, price-transparency]
status: draft
discovered: 2026-11-09
workspace: ROCIsSideProjects
related: [2026-11-09-rocis-recipes-design, 2026-11-09-rocis-recipes-core-app]
---

# ROCIsRecipes Prices Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The shopping list shows an estimated total in NIS per grocery chain, from a weekly price snapshot bundled with the app.

**Architecture:** A dependency-free Python pipeline (`tools/price_pipeline/`) downloads the chains' published price files, maps catalog ingredients to products by Hebrew keywords, takes the median price across stores, and writes `assets/prices/snapshot.json`. The Flutter app only reads that snapshot (`PriceService`) and never touches chain portals. All prices are estimates and are labelled as such.

**Tech Stack:** Python 3 standard library (`urllib`, `gzip`, `xml.etree`, `unittest`), Flutter `intl` (already a dependency) for NIS formatting.

**Spec:** `docs/superpowers/specs/2026-11-09-rocis-recipes-design.md`. Builds on `docs/superpowers/plans/2026-11-09-rocis-recipes-core-app.md` (merged).

## Spike findings this plan relies on (measured 2026-11-09)

- Shufersal portal `https://prices.shufersal.co.il/` is public, no login. Files are gzip, UTF-8 with BOM, XML `<Root>` containing `<Item>` entries. Download links are signed Azure blob URLs that expire within about an hour, so links must be scraped and used immediately.
- The listing is paginated (`/?page=N`, 86 pages in the default view). Category filter URL that worked: `/FileObject/UpdateCategory?catID=2&storeId=0&sort=Size&sortdir=DESC&page=1` (catID 2 returned `PriceFull` files).
- One branch `PriceFull` file: 94 KB gzipped, 1.6 MB XML, 1,940 items. Item fields seen: `ItemCode` (barcode), `ItemName`, `ManufactureName`, `Quantity`, `UnitOfMeasure`, `bIsWeighted`, `ItemPrice`, `UnitOfMeasurePrice`, `PriceUpdateTime`.
- Carrefour portal `https://prices.carrefour.co.il/` looks public (73 pages, category and store filters) but a download has not been tried.
- `url.publishedprices.co.il` (reportedly used by Rami Levy, Yochananof and others) requires a username and password. Not used in this plan.
- Not found: any coordinates for stores. Nearest-store by GPS is therefore deferred.

## Global Constraints

- Prices are in NIS (ILS), shown with the shekel sign, Hebrew default, English also supported.
- Free tiers only. This plan uses no Cloudflare, Firebase or other hosted service: the snapshot ships inside the app.
- No credential-gated sources and no account sign-ups (design rule). Chains that need a login stay out.
- Every price is labelled as an estimate. Items with no price are shown as unpriced, never as zero.
- The app never parses chain files and never makes network calls for prices.
- Snapshot file stays under 500 KB.
- Zero hardcoded UI strings; all strings in `app_he.arb` and `app_en.arb`.
- Quality gate per task: `flutter analyze` clean and `flutter test` passes for Dart tasks; `python -m unittest discover -s tools/price_pipeline/tests` passes for pipeline tasks.

## Review Focus

1. An ingredient with no price at a chain: shown as unpriced, excluded from the total, and the total is flagged partial (Task 6).
2. A chain where no list item has a price: no total is shown, only a "no data" message (Task 6).
3. Price entries of 0 or negative, or `ItemPrice` missing in the XML: ignored by the pipeline (Task 2).
4. Weighted items (`bIsWeighted=1`) must use the per-kilogram price, not a per-piece price (Task 2).
5. Stale snapshot (older than 14 days): a visible warning, totals still shown (Task 5).

## Decisions made (my calls, for the user to check)

- Pipeline language is Python (already installed here, and good for one-off file wrangling). It lives in `tools/` and is not part of the app build.
- One list item counts as one typical purchase: the median price of matching products, per kg for weighted items. List quantities are not multiplied in v1.
- "Nearest store" is replaced in this plan by choosing which chains to compare (stored in settings). One representative price per chain, the median over its stores. GPS and branch lookup come later, once store coordinates or a geocoding source are available.
- Only ingredients with a mapping get prices. A mapping file covers the roughly 60 ingredients most used by the starter recipes first.
- Chains: Shufersal first (verified). Carrefour is added in Task 8 only if its files download and match the same format. Other chains are out until a no-login source is verified.

---

## File Structure

```
tools/price_pipeline/
  README.md                      # how to refresh weekly
  price_items.py                 # PriceItem dataclass, parse_price_full(xml_bytes)
  shufersal.py                   # list_files(), fetch_price_full()
  matching.py                    # normalize_he(), load_mapping(), aggregate()
  ingredient_products.json       # ingredientId -> include/exclude keywords, basis
  build_snapshot.py              # CLI
  tests/{fixtures/, test_*.py}
assets/prices/snapshot.json      # generated, bundled
lib/features/prices/{price_snapshot.dart, price_service.dart, ui/price_summary.dart}
```

---

### Task 1: PriceFull parser

**Files:**
- Create: `tools/price_pipeline/price_items.py`, `tools/price_pipeline/tests/test_price_items.py`, `tools/price_pipeline/tests/fixtures/price_sample.xml` (a trimmed copy of the real 19-item Shufersal `Price` file from the spike, saved from `https://prices.shufersal.co.il/`)

**Interfaces:**
- Produces: `@dataclass(frozen=True) class PriceItem: code: str; name: str; price: float; unit_price: float | None; unit_of_measure: str; is_weighted: bool`; `def parse_price_full(xml_bytes: bytes) -> list[PriceItem]`.

- [ ] **Step 1: Write failing tests** (`unittest`): `test_parses_utf8_bom_xml` (fixture yields 19 items, first has non-empty `code` and `name`), `test_weighted_item_uses_unit_price` (inline XML with `bIsWeighted` 1 and `UnitOfMeasurePrice` 12.5 yields `is_weighted=True`, `unit_price=12.5`), `test_skips_zero_negative_and_missing_prices` (Review Focus 3: items with `ItemPrice` 0, -1 and absent are dropped), `test_handles_utf16_xml` (the same document encoded UTF-16 parses).
- [ ] **Step 2:** Run `python -m unittest discover -s tools/price_pipeline/tests`. Expected: FAIL (module missing).
- [ ] **Step 3:** Implement `parse_price_full` with `xml.etree.ElementTree`, decoding BOM or UTF-16 first.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat(prices): PriceFull parser`.

---

### Task 2: Shufersal listing and download

**Files:**
- Create: `tools/price_pipeline/shufersal.py`, `tools/price_pipeline/tests/test_shufersal.py`, `tools/price_pipeline/tests/fixtures/shufersal_pricefull_list.html` (saved listing page from the verified category URL)

**Interfaces:**
- Produces: `@dataclass(frozen=True) class FileLink: name: str; url: str; store_id: str`; `def parse_listing(html: str) -> list[FileLink]` (unescapes `&amp;`); `def list_price_full(page: int) -> list[FileLink]` (network: fetches `.../FileObject/UpdateCategory?catID=2&storeId=0&sort=Size&sortdir=DESC&page={page}`); `def download_items(link: FileLink) -> list[PriceItem]` (network: downloads, gunzips, calls `parse_price_full`); `def fetch_chain_items(max_stores: int, pause_seconds: float = 0.5) -> dict[str, list[PriceItem]]` keyed by store id.

- [ ] **Step 1: Write failing tests** against the saved listing: `test_parse_listing_extracts_links` (20 links, all names start with `PriceFull`, urls contain no `&amp;`, `store_id` parsed from the name's second number group), `test_parse_listing_empty_html_returns_empty`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the functions with `urllib.request` and a descriptive `User-Agent`. `fetch_chain_items` pauses between downloads and stops at `max_stores` distinct stores. Network functions are not unit tested; they are exercised in Task 4.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat(prices): Shufersal listing and download`.

---

### Task 3: Ingredient matching and aggregation

**Files:**
- Create: `tools/price_pipeline/matching.py`, `tools/price_pipeline/ingredient_products.json`, `tools/price_pipeline/tests/test_matching.py`

**Interfaces:**
- Consumes: `PriceItem` (Task 1).
- Produces:
  - `def normalize_he(text: str) -> str` (same rules as the app's `normalizeText`: strip niqqud and punctuation, map final letters, collapse whitespace, lowercase).
  - `@dataclass(frozen=True) class Mapping: include: list[str]; exclude: list[str]; basis: str` where `basis` is `"unit"` or `"kg"`.
  - `def load_mapping(path: str) -> dict[str, Mapping]`.
  - `@dataclass(frozen=True) class Aggregate: price: float; unit: str; sample: int`.
  - `def aggregate(stores: dict[str, list[PriceItem]], mapping: dict[str, Mapping]) -> dict[str, Aggregate]`: per ingredient id, the median price over all matching items across all stores; `kg` basis uses `unit_price` of weighted items; `unit` basis uses `price` of non-weighted items; no matches means the ingredient is omitted.

- [ ] **Step 1: Write failing tests** with synthetic items: `test_median_across_stores`, `test_include_and_exclude_keywords` (for example include "חלב", exclude "שוקולד" so chocolate milk is not milk), `test_kg_basis_ignores_non_weighted_items` (Review Focus 4), `test_unit_basis_ignores_weighted_items`, `test_no_match_omits_ingredient`, `test_matching_ignores_niqqud_and_final_letters`, `test_normalize_he_matches_app_rules` (same expectations as the Dart normalizer tests: `'  עַגְבָנִיּוֹת  '` gives `'עגבניות'`, `'לחם '` gives `'לחמ'`).
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement. Author `ingredient_products.json` for about 60 ingredients taken from the starter recipes' most used ids in `assets/data/ingredients.json` (eggs, milk, tomato, cucumber, onion, potato, rice, pasta, bread, flour, oil, sugar, tuna, chicken breast and so on), each with Hebrew `include` keywords and any `exclude` words, and the right `basis`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat(prices): ingredient matching and aggregation`.

---

### Task 4: Snapshot builder and first real snapshot

**Files:**
- Create: `tools/price_pipeline/build_snapshot.py`, `tools/price_pipeline/tests/test_build_snapshot.py`, `tools/price_pipeline/README.md`, `assets/prices/snapshot.json` (generated)

**Interfaces:**
- Consumes: `fetch_chain_items`, `aggregate`, `load_mapping`.
- Produces: `def build_snapshot(chain_aggregates: dict[str, dict[str, Aggregate]], generated_at: str) -> dict`, with the JSON shape the app reads:
  `{"version":1,"generatedAt":"YYYY-MM-DD","currency":"ILS","chains":[{"id":"shufersal","nameHe":"שופרסל","nameEn":"Shufersal"}],"prices":{"<ingredientId>":{"<chainId>":{"price":12.9,"unit":"unit|kg","sample":14}}}}`. CLI: `python tools/price_pipeline/build_snapshot.py --chains shufersal --max-stores 20 --out assets/prices/snapshot.json`.

- [ ] **Step 1: Write failing tests:** `test_snapshot_shape` (keys, `currency == "ILS"`, prices rounded to 2 decimals), `test_snapshot_omits_ingredients_without_prices`, `test_snapshot_is_deterministic_for_same_input` (stable key order).
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the builder and CLI. Then run the CLI against the live Shufersal portal with `--max-stores 20`, inspect the output, and report how many of the mapped ingredients got a price and the file size. If the file is over 500 KB, reduce it before committing.
- [ ] **Step 4:** Run the tests. Expected: PASS. Confirm `assets/prices/snapshot.json` parses and is under 500 KB.
- [ ] **Step 5:** Commit `feat(prices): snapshot builder and first Shufersal snapshot`.

---

### Task 5: Snapshot model and price service (Dart)

**Files:**
- Create: `lib/features/prices/price_snapshot.dart`, `lib/features/prices/price_service.dart`; modify `pubspec.yaml` (register `assets/prices/`), `lib/core/services/app_initializer.dart`
- Test: `test/features/prices/price_service_test.dart`

**Interfaces:**
- Produces:
  - `class PriceChain { final String id; final String nameHe; final String nameEn; }`
  - `class ItemPrice { final double price; final String unit; final int sample; }`
  - `class PriceSnapshot { final DateTime generatedAt; final List<PriceChain> chains; final Map<String, Map<String, ItemPrice>> prices; factory PriceSnapshot.fromJson(Map<String, dynamic>); ItemPrice? priceFor(String ingredientId, String chainId); bool isStale(DateTime now) }` (stale when older than 14 days).
  - `class ChainTotal { final String chainId; final double total; final int pricedCount; final int unpricedCount; bool get hasData; bool get isPartial; }`
  - `class PriceService { PriceService(this.snapshot); ChainTotal totalFor(List<ShoppingItem> items, String chainId); }` counting only unchecked items; items without an `ingredientId` count as unpriced.

- [ ] **Step 1: Write failing tests:** `totals sum the price of unchecked priced items`, `checked items are ignored`, `unpriced item is excluded and total is partial` (Review Focus 1), `chain with no priced items has no data` (Review Focus 2), `custom items without an ingredient id count as unpriced`, `snapshot older than 14 days is stale and 14 days exactly is not` (Review Focus 5), `fromJson parses the builder output shape`.
- [ ] **Step 2:** Run `flutter test test/features/prices`. Expected: FAIL.
- [ ] **Step 3:** Implement. The initializer loads `assets/prices/snapshot.json` and provides a `Provider<PriceService>`; the test environment gets an in-memory snapshot.
- [ ] **Step 4:** Run the tests and `flutter analyze`. Expected: PASS, no issues.
- [ ] **Step 5:** Commit `feat(prices): price snapshot model and service`.

---

### Task 6: Chain selection and shopping list price UI

**Files:**
- Create: `lib/features/prices/ui/price_summary.dart`; modify `lib/features/pantry/settings_repository.dart`, `lib/features/shopping/ui/shopping_screen.dart`, `test/helpers/test_env.dart`, ARB files
- Test: `test/features/prices/price_ui_test.dart`

**Interfaces:**
- Consumes: `PriceService.totalFor`, `ShoppingItemTile.priceLabel` (exists, unused so far).
- Produces: `SettingsRepository.selectedChainIds -> Set<String>` and `setSelectedChainIds(Set<String>)` (default: all chains in the snapshot); `class PriceSummary extends StatelessWidget { const PriceSummary({super.key}); }` showing one row per selected chain with `₪` total, an "estimate" label, a "partial" flag with the unpriced count, a "no data" message when `!hasData`, and a stale-snapshot warning.

- [ ] **Step 1: Write failing widget tests:** `shows a total per selected chain in NIS with the shekel sign`, `partial total shows how many items have no price` (Review Focus 1), `chain with no priced items shows no data and no total` (Review Focus 2), `stale snapshot shows a warning` (Review Focus 5), `deselecting a chain hides its row and persists`, `price line appears under items that have a price`.
- [ ] **Step 2:** Run `flutter test test/features/prices`. Expected: FAIL.
- [ ] **Step 3:** Implement with `NumberFormat.currency(locale: ..., symbol: '₪')`; add Hebrew and English strings.
- [ ] **Step 4:** Run `flutter test` and `flutter analyze`. Expected: PASS, no issues.
- [ ] **Step 5:** Commit `feat(prices): chain totals on the shopping list`.

---

### Task 7: Add Carrefour if its files match

**Files:**
- Modify: `tools/price_pipeline/` (a `carrefour.py` mirroring `shufersal.py` if the format matches), `build_snapshot.py`, regenerate `assets/prices/snapshot.json`

- [ ] **Step 1:** Fetch the Carrefour listing and download one `PriceFull` file. Report: download works without login, format, encoding, and whether `parse_price_full` parses it.
- [ ] **Step 2:** Decision rule: if download needs no login and `parse_price_full` parses it, add `carrefour.py` with a listing fixture test like Task 2, add the chain to the builder, rebuild the snapshot, and check the size limit. If either condition fails, stop here, record the finding in `tools/price_pipeline/README.md`, and do not add the chain.
- [ ] **Step 3:** Run all pipeline tests and `flutter test`. Expected: PASS.
- [ ] **Step 4:** Commit `feat(prices): add Carrefour` or `docs(prices): Carrefour not usable, findings`.

---

## Self-Review

- Spec coverage: goal 4 (prices in NIS per chain) is covered by Tasks 1 to 7. "Nearest store" is replaced by chain selection (decision above) and GPS is deferred. Chains needing a login are out by the design rule. Photo input, user recipes and ROCIsTasks sync remain in Plan 3.
- Types: `PriceItem`, `Mapping`, `Aggregate`, `FileLink`, `PriceSnapshot`, `ItemPrice`, `ChainTotal`, `PriceService` are used consistently across tasks.
- Open risk: ingredient-to-product keyword matching decides price quality. Task 4 reports the real coverage so the user can judge before Task 6 ships.
