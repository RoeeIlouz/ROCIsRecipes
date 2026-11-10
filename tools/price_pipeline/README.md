---
ontology: true
type: reference
domain: rocis-recipes
summary: How the grocery price snapshot pipeline works, how to run it by hand, and its known limits
tags: [prices, pipeline, python, github-actions, shufersal, openstreetmap]
status: active
discovered: 2026-11-10
workspace: ROCIsSideProjects
related: [2026-11-09-rocis-recipes-prices]
---

# Price snapshot pipeline

Builds `assets/prices/snapshot.json.gz`, the per-branch price file the app reads.
Python 3 standard library only, no installs.

## What it does

1. Downloads a chain's published `Stores` file and the latest `PriceFull` file per branch
   (Shufersal: https://prices.shufersal.co.il/, public, no login).
2. Geocodes branch addresses with OpenStreetMap Nominatim (at most 1 request per second,
   results cached in `geocode_cache.json`). Map data from OpenStreetMap contributors (ODbL).
   City codes are turned into names with the open settlements list on data.gov.il.
3. Maps catalog ingredients to products by Hebrew keywords (`ingredient_products.json`) and
   takes the median price at each branch. Weighted items use the per-kilogram price.
4. Drops prices more than 4 times away from the cross-branch median (stray wrong matches).
5. Writes compact gzip JSON. Branches without coordinates or prices are left out.

## Run by hand

```
python -m unittest discover -s tools/price_pipeline/tests
python tools/price_pipeline/build_snapshot.py --chains shufersal --out assets/prices/snapshot.json.gz
```

Add `--max-stores 20` for a quick trial run. The first run geocodes every branch and takes
about 30 minutes; later runs only geocode new or changed addresses.

## Automatic refresh

`.github/workflows/prices.yml` runs on Sunday and Wednesday at 03:00 UTC (and on demand with
`gh workflow run prices.yml`). It runs the tests, builds the snapshot, and publishes
`snapshot.json.gz` and `manifest.json` to the `data` branch. The app downloads
`https://raw.githubusercontent.com/RoeeIlouz/ROCIsRecipes/data/snapshot.json.gz` when its copy is
older than 3 days and warns when the copy in use is older than 7 days.

GitHub can switch off scheduled workflows after 60 days without repository activity. If prices
stop updating, open the repository's Actions tab and re-enable the workflow, or run it manually.

## Known limits

- All prices are estimates. A list item is one typical purchase (the median matching product),
  not a specific product, and list quantities are not multiplied.
- About 76 percent of Shufersal branches (316 of 417) could be located; the rest are left out of
  nearest-branch search. Misses are mostly addresses with missing spaces, malls and junctions.
- Broccoli and chili flakes currently match no products; celery, green beans, frozen vegetables,
  garlic powder and onion powder are priced at only a few branches.
- Chains: Shufersal and Carrefour. Carrefour's portal (https://prices.carrefour.co.il/) is public;
  its page embeds the day's file list as JavaScript and the files sit in a per-day folder, so
  `carrefour.py` reads that list instead of scraping links. Its item names are truncated to about
  20 characters, so matching quality there may be lower than for Shufersal.
- Carrefour works from an Israeli connection (`--chains shufersal,carrefour`) but its server drops
  connections from GitHub's runners (a probe on 2026-11-10: DNS resolves, the TCP connection never
  completes within 134 s, while Shufersal connects in 0.13 s). A longer timeout does not help, so the
  weekly job builds Shufersal only. Carrefour data in the bundled snapshot is from 2026-11-10 and
  can only be refreshed by running the pipeline from an Israeli connection.
- Other chains: `url.publishedprices.co.il` (Rami Levy, Yochananof and others) needs an account and
  is not used.
