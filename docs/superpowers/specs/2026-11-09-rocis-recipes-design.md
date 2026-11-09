---
ontology: true
type: workflow-spec
domain: rocis-recipes
summary: Design for ROCIsRecipes, a Flutter Android app that suggests dishes from what you have and prices the shopping list at Israeli grocery chains
tags: [flutter, android, recipes, shopping-list, israel, price-transparency]
status: draft
discovered: 2026-11-09
workspace: ROCIsSideProjects
related: []
---

# ROCIsRecipes: Design

Status: draft, awaiting approval. Items marked "(my call)" are decisions I made, not ones the user made.

## Intent and why

The user is a university student who finds it hard to cook for themself. They wish they knew (1) what they can cook with what they have and how, and (2) what to buy and roughly what it should cost. The app answers both: it turns "what I have, what appliances I own, how much time I've got" into dishes with step-by-step guidance, and turns missing ingredients into a shopping list priced in NIS at nearby Israeli grocery chains.

Audience for now: the user and friends. Scaling to public release is a possible later step and must not be blocked by early choices, but it is not a goal of v1.

## Goals

1. Suggest dishes from available ingredients, owned appliances, and available time.
2. Guide the user through cooking a chosen dish, step by step.
3. Show which ingredients are missing and let the user add them to a shopping list.
4. Maintain shopping lists, and show each list's total price in NIS at nearby chains (Shufersal, Rami Levy, Zol Stock, Yochananof, Carrefour and similar).
5. Let the user enter what they have in three ways: type it, pick from a list, photo (photo comes last, see Phasing).
6. Let the user add their own recipes and attach their own photos to recipes.
7. English and Hebrew (RTL and LTR) from day one.
8. Optional sync of the shopping list to ROCIsTasks.

## Non-goals (v1)

- AI-generated recipes and AI analysis of uploaded recipes (photo, screenshot, link). Dropped because the user does not want to pay for an AI service now. The design must leave room to add it later (my call: keep recipe import and recipe generation behind interfaces).
- Public Play Store release, accounts for strangers, monetisation.
- Ordering groceries or delivery.
- Non-Israeli stores or currencies.
- A large recipe catalog. v1 ships a modest starter collection.

## Anti-goals (failure even if it technically works)

- Prices presented as exact when they are estimates. Weighted or unbarcoded items (produce) must be visibly marked as estimates.
- Any recurring cost the user has not agreed to. Stay within free tiers; the user's standing rule is to never exceed Cloudflare free-tier limits (R2: 10 GB storage, 1M Class A, 10M Class B per month) and to check usage and stop before approaching them.
- Suggestions that need ingredients or appliances the user said they do not have.

## Constraints and decisions made by the user

- Platform: Android, built with Flutter, following the ROCIsApps conventions (feature-first layout, Hive for offline-first local storage, Provider, go_router, Firebase, glass and AMOLED design system, Outfit font, zero hardcoded strings, ARB files for en and he, version sync between pubspec and app config). The rocis-app-builder skill is the reference.
- Input methods: typing, picking from a list, and photos are all wanted.
- Price accuracy: the user would like prices to match the shelf ("perfect"), but approximate is acceptable if exact is too hard. Estimates must be labelled.
- Recipes: start with a modest starter collection from a free source plus user-added recipes. AI features may come later.
- User photos on recipes are wanted.
- ROCIsTasks sync is optional and last.
- Audience: user and friends first.
- Price freshness: a snapshot of chain prices refreshed about weekly and bundled with the app is acceptable for v1 (the user chose this over a live daily service). Build it so a live service can replace it later.
- Recipe language: starter recipes should be mainly in Hebrew. A minority in English is acceptable (my reading of "mainly in Hebrew").

## What the research found (partly unverified)

From web search; most sources were vendor or aggregator pages, so details need confirming before relying on them:

- Israeli grocery chains must publish price, promotion and store files publicly. Shufersal and Carrefour run their own portals. Rami Levy and Yochananof reportedly publish through a shared portal that needs a login. Files are XML, sometimes zipped (including zips with a .gz name) and sometimes UTF-16 encoded. File names reportedly encode chain ID, store ID and timestamp.
- Update frequency of the files is uncertain.
- A Python library, `israeli-prices`, claims to cover 31 of 32 chains behind one interface, with GTIN (barcode) normalisation. Not verified. Zol Stock and Super-Pharm coverage is not confirmed.
- Barcoded items can be matched across chains by GTIN. Loose or weighted items use per-chain codes and free-text Hebrew names, and the government schema has no category field. Matching those needs keyword or fuzzy logic.
- ROCIs-tasks (in ROCIsApps) uses hive_ce, Firestore, Firebase Auth, Provider, go_router and home_widget, and has a schedule_bridge_service.dart that may show an existing cross-app pattern. Not yet read in detail.

## Architecture direction (my call)

Three parts:

1. **Flutter app.** Offline-first. Local Hive storage for pantry, appliances, recipes, shopping lists. Reads prices from the backend only; never parses chain files itself.
2. **Price pipeline.** For v1 (user's choice): an offline pipeline, run about weekly, that downloads the chains' published files, normalises them, trims them to what the app needs (relevant items and branches), and produces a compact price snapshot the app bundles or downloads. The app only ever reads the snapshot. The pipeline is separate from the app so it can later become a live service behind the same data shape. Any hosting uses free tiers only, preferring Cloudflare (cf CLI unless a Wrangler config exists) and checking usage first. A measuring spike comes before committing to the snapshot size and chain list.
3. **Recipe data.** Bundled starter collection from a free, permissively licensed source (to be chosen after checking licences and whether Hebrew recipes exist), plus user-added recipes stored locally. Photos stored on the device; syncing photos between friends is out of v1 unless it fits free-tier storage.

Nearest store: use device location (with permission) to pick nearby branches. Branch lists come from the chains' store files. Fallback: user picks a chain and city manually.

## Phasing (my call)

1. Foundation: project scaffold in ROCIsApps style, theme, i18n, local storage.
2. Pantry and appliances entry (typed and list-pick), recipe model, starter collection, "what can I cook" matching by ingredients, appliances, time, and guided cooking steps.
3. Shopping list from missing ingredients, manual list editing.
4. Price backend spike (feasibility and free-tier measurement), then price display per chain and nearest-store selection.
5. User recipes with own photos.
6. Photo input for pantry (on-device or free option only; revisit if it needs paid AI).
7. Optional ROCIsTasks sync.
8. Later: AI recipe import and generation.

## Left to the builder

- Exact data models, state management details within Provider, screen layouts.
- Choice of free recipe source after checking licence and Hebrew support.
- Backend hosting details and data format, subject to the free-tier constraint.
- Ingredient normalisation and matching approach (synonyms, Hebrew and English names, quantities and units).
- Appliance list and time-bucket UX.
- Testing approach.

## Calls I made (not yet checked by the user)

- Price fallback: if the spike shows full data does not fit or some chains need a login, v1 shrinks first to the chains that publish openly, then to barcoded items plus a curated list of common ingredients. A shrunken price feature still counts as v1. No paid or credential-gated access in v1.
- Comparison: show per-chain totals side by side for the list. Items a chain does not carry or that cannot be matched give a partial total with a visible flag. A cheapest-basket-across-stores view is later.
- Ingredient to product matching: a curated mapping for common ingredients, Hebrew and English synonyms, and the user may pick a different product. Unbarcoded or weighted items are labelled as estimates; estimate = median matched price scaled to the needed quantity.
- Accounts: no login in v1. Data is local. Firebase is added only when ROCIsTasks sync or cross-device sync is built. The snapshot is static, so there is no price API to protect.
- Pantry: items are present or absent, with optional quantity. Staples (salt, pepper, oil, water) are assumed available and the user can edit that list.
- Suggestions: two modes. "Cook now" is strict. "Almost there" shows dishes missing a few items and lets the user add them to the shopping list. This reconciles the anti-goal with goal 3.
- Starter collection: about 50 to 100 recipes, each hand-tagged with appliances and total time. If no free source has enough Hebrew recipes, I write or translate them, subject to licence.
- Photo input (phase 6) is optional for v1 sign-off and is dropped if no free option is good enough.

## Open items

- Price data feasibility and size versus free tiers (spike in phase 4).
- Which chains actually expose usable, unauthenticated or easily authenticated feeds.
- Licence and Hebrew coverage of the starter recipe source.
- Photo-to-ingredients without paid AI: whether a free on-device approach is good enough.
