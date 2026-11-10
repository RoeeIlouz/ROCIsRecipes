---
ontology: true
type: plan
domain: rocis-recipes
summary: Plan for a rebuilt recipe collection, about 120 real meal recipes with quantities, detailed steps and licensed photos
tags: [recipes, content, photos, wikimedia-commons, hebrew]
status: draft
discovered: 2026-11-10
workspace: ROCIsSideProjects
related: [2026-11-09-rocis-recipes-design, 2026-11-09-rocis-recipes-core-app]
---

# Recipes v2 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (or subagent-driven-development) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Replace the 52 quick-snack starter recipes with about 120 real meal recipes (breakfast, lunch, dinner, meal prep) that have quantities, 6 to 10 detailed steps, and a licensed photo with credit.

**Why:** Device feedback: "steps too basic, no photos, not enough recipes, they're not meal recipes".

**Architecture:** Recipe model v2 (backward compatible) with servings, difficulty, meal type and a photo with credit. Content lives in `assets/recipes/` JSON, written in batches and checked by a stricter validator. Photos come from Wikimedia Commons through a pipeline script with a review step, and are bundled as small JPEGs. The UI shows photos, quantities and credits.

**Tech Stack:** Flutter (existing), Python 3 standard library for the photo pipeline, Wikimedia Commons API (no account), `ffmpeg` (already installed) for contact sheets.

## Decisions (my calls, for the user to check)

- **Photo source:** Wikimedia Commons. Pexels paused new API keys. Commons needs no account and gives license and author per photo. Only photos licensed CC0, public domain, CC BY or CC BY-SA are used. Every photo shows "Photo: AUTHOR, LICENSE" and opens its Commons page when tapped, and a credits screen lists them all.
- **Photo size:** 600 px wide JPEG as served by Commons, about 50 to 100 KB each, bundled in the app (roughly 8 MB for 120). No network needed to show them.
- **Photo choice:** the script picks the best-ranked licensed candidates; a contact sheet is reviewed (by me, and by the user in the app) and wrong ones are replaced through `photo_overrides.json`. A recipe with no acceptable photo shows a clean placeholder, never a wrong photo.
- **Count and mix:** about 120. Roughly 25 Israeli and Middle Eastern staples, 20 pasta and rice dishes, 20 chicken and meat, 10 fish, 15 vegetarian mains, 10 soups, 10 breakfasts and brunch, 10 sheet-pan and meal-prep dishes. Student-realistic: few appliances, cheap ingredients, 15 to 60 minutes.
- **Language:** Hebrew titles and steps. English titles added where natural, not required.
- **Old recipes:** the 52 old starter recipes are retired (removed from existing installs) except any recipe the user created.

## Global Constraints

- Every recipe: title, servings (1 to 8), difficulty (easy, medium), meal type, total minutes, appliances, at least 6 steps, quantities and units for every non-staple ingredient, a photo or an explicit "no photo" flag.
- Photo credit data is stored per recipe and always shown with the photo.
- Ingredient ids must exist in `assets/data/ingredients.json`; new ingredients get a category and an icon.
- No copied recipe text: all recipe text is original.
- Zero hardcoded UI strings; Hebrew first, English supported.
- Quality gate per task: `flutter analyze` clean, `flutter test` passes, Python tests pass.

## Review Focus

1. A recipe whose photo file is missing at runtime: placeholder, no crash.
2. Retiring old starter recipes must never delete a user-created recipe.
3. Recipes needing quantities in different units (grams, cups, spoons, units) must display correctly in Hebrew and English.
4. A photo credit with HTML or odd characters from Commons (author names are HTML) must be shown as clean text.
5. The suggestions list with 120 recipes and photos must stay smooth (lazy list, small cached images).

---

### Task 1: Recipe model v2

**Files:** Modify `lib/features/recipes/recipe.dart`; Test `test/features/models_test.dart` (extend), `test/features/recipe_v2_test.dart`.

**Interfaces:** Adds to `Recipe`: `int servings` (default 2), `String difficulty` (`easy` or `medium`, default `easy`), `String mealType` (`breakfast`, `lunch`, `dinner`, `snack`, `dessert`; default `dinner`), `RecipePhoto? photo`. New `class RecipePhoto { final String asset; final String author; final String license; final String sourceUrl; }` with `fromJson`/`toJson`. Old JSON (no new fields) still parses with defaults.

- [ ] **Step 1: Failing tests:** `Recipe v2 round-trips through JSON with photo`, `old recipes without the new fields parse with defaults`, `unknown difficulty or mealType falls back to defaults`, `RecipePhoto equality`.
- [ ] **Step 2:** Run `flutter test test/features/recipe_v2_test.dart`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run tests and analyze. Expected: PASS.
- [ ] **Step 5:** Commit `feat(recipes): recipe model v2`.

### Task 2: Stricter validator and retiring old recipes

**Files:** Modify `lib/features/recipes/starter_recipe_loader.dart`, `recipe_repository.dart`, `app_initializer.dart`; Test `test/features/starter_recipes_test.dart`, `test/features/starter_sync_test.dart`.

**Interfaces:** `StarterRecipeLoader.validate` additionally reports: fewer than 6 steps, servings outside 1 to 8, a non-staple ingredient without quantity or unit, a missing photo (unless `photo` is null and the recipe has `"noPhoto": true`), and a photo asset that does not exist when an `assetExists` callback is given. `RecipeRepository.retireStarter(Set<String> keepIds)` deletes non-user recipes not in `keepIds` and never touches `isUserCreated` ones. `kStarterVersion` becomes 2 and the initializer calls `retireStarter` after `syncStarter`.

- [ ] **Step 1: Failing tests** for each new rule, and `retireStarter removes old starter recipes and keeps user recipes` (Review Focus 2).
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run tests and analyze. Expected: PASS (the existing 52-recipe test is updated to the new rules in Task 4).
- [ ] **Step 5:** Commit `feat(recipes): stricter validation and retiring old starter recipes`.

### Task 3: Ingredient catalog extension

**Files:** Modify `assets/data/ingredients.json`, `lib/features/catalog/ingredient_icons.dart`, `tools/price_pipeline/ingredient_products.json` (price mappings for new common items); Test existing catalog and icon tests.

- [ ] **Step 1:** Compile the list of ingredients the new recipes need that the catalog lacks (target about 40 more: for example leeks, kohlrabi, feta, tortilla variants, fish types, legumes, nuts, sauces, dairy alternatives), with category and emoji for each.
- [ ] **Step 2:** Add them; existing tests (`every catalog ingredient has a known category`, `non-empty icon`, unique ids) must pass. Add `test/features/catalog_size_test.dart` asserting at least 160 ingredients.
- [ ] **Step 3:** Run all tests. Expected: PASS.
- [ ] **Step 4:** Commit `feat(catalog): about 40 more ingredients`.

### Task 4 to 8: Recipe content batches

One task per batch of about 25 recipes, in this order: (4) Israeli and Middle Eastern staples, (5) pasta, rice and grains, (6) chicken and meat, (7) fish, vegetarian and soups, (8) breakfasts, sheet-pan and meal prep. Files: `assets/recipes/starter_he.json` (replaced progressively), `assets/recipes/SOURCES.md`.

- [ ] **Step 1:** Write the batch: Hebrew title, servings, difficulty, meal type, minutes, appliances, ingredients with quantity and unit, 6 to 10 detailed steps with times and doneness cues, ids `rv2_<slug>`. All original text.
- [ ] **Step 2:** `flutter test test/features/starter_recipes_test.dart`. Expected: validation passes for the batch (photo rule excluded until Task 9 via the `noPhoto` flag).
- [ ] **Step 3:** Commit `content(recipes): batch N`.

### Task 9: Photo pipeline

**Files:** Create `tools/recipes/fetch_photos.py`, `tools/recipes/commons.py`, `tools/recipes/photo_overrides.json`, `tools/recipes/tests/test_commons.py`, `assets/recipes/photos/*.jpg`, `assets/recipes/photo_credits.json`; modify `.gitignore` if needed.

**Interfaces:** `parse_candidates(json_text: str) -> list[Candidate]` with `Candidate(title, thumb_url, width, height, license, author, source_url)`; `is_allowed_license(short_name: str) -> bool` (CC0, public domain, CC BY, CC BY-SA, any version); `clean_author(html: str) -> str` (strips tags and entities, Review Focus 4); `pick(candidates) -> Candidate | None` (allowed license, width at least 800, aspect ratio between 0.7 and 2.0, first by search rank); CLI `python tools/recipes/fetch_photos.py` reads each recipe's `photoQuery` (English dish name), honors `photo_overrides.json` (recipe id to exact Commons file title), downloads the 600 px thumbnail, and writes `assets/recipes/photos/<recipe id>.jpg` and the credit entry. Requests use a descriptive `User-Agent` and a pause between calls.

- [ ] **Step 1: Failing tests** on saved sample API JSON: `parse_candidates reads license, author and size`, `is_allowed_license accepts CC BY-SA 4.0 and rejects CC BY-NC and all rights reserved`, `clean_author strips links and entities`, `pick skips small and non-allowed photos and extreme aspect ratios`.
- [ ] **Step 2:** Run `python -m unittest discover -s tools/recipes/tests`. Expected: FAIL.
- [ ] **Step 3:** Implement; run it for real; build a contact sheet with `ffmpeg` of the chosen photos; review it image by image; list wrong or missing ones and fix them through overrides or `noPhoto`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat(recipes): photo pipeline and photos`.

### Task 10: Photos, quantities and credits in the UI

**Files:** Modify `lib/features/recipes/ui/recipe_card.dart`, `recipe_detail_screen.dart`, `suggestions_screen.dart`; Create `lib/features/recipes/ui/recipe_photo.dart`, `lib/features/settings/ui/credits_screen.dart`; modify `router.dart`, ARB files; Test `test/features/recipe_photo_ui_test.dart`.

**Interfaces:** `RecipePhotoView({required RecipePhoto? photo, double? height})` shows the bundled image with a rounded crop, a placeholder when null or when the asset fails to load (Review Focus 1), and an optional credit line "Photo: AUTHOR, LICENSE" that opens `sourceUrl` through the existing `LaunchUrl`. Recipe detail shows a hero photo, servings, difficulty, meal type, and each ingredient with its quantity and unit. The suggestions screen gets meal-type filter chips. `/credits` lists every photo credit and the Pexels-style notice for Commons.

- [ ] **Step 1: Failing widget tests:** `card shows the photo and a placeholder when none`, `broken asset falls back to the placeholder`, `detail shows quantities with units`, `credit line opens the source url`, `meal type chip filters the list`, `credits screen lists every credited photo`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement with `Image.asset(errorBuilder:)` and `cacheWidth` so 120 photos stay light (Review Focus 5).
- [ ] **Step 4:** Run `flutter test`, `flutter analyze`. Expected: PASS.
- [ ] **Step 5:** Commit `feat(recipes): photos, quantities and credits in the UI`.

### Task 11: Verify on the emulator

- [ ] **Step 1:** Build the release APK, install it on the emulator, and screenshot: suggestions list, a recipe detail, cooking mode, the credits screen.
- [ ] **Step 2:** Fix anything visibly wrong (cropped photos, overflow, unreadable credit) with a test where practical, then repeat.
- [ ] **Step 3:** Report the app size and any remaining gaps honestly. Commit and merge to `main`.

## Self-Review

- Spec coverage: the four complaints map to Tasks 4 to 8 (real meals, more recipes, detailed steps) and Tasks 9 and 10 (photos).
- Types are consistent: `RecipePhoto`, `Candidate`, `Recipe` v2 fields.
- Open risks: Commons photo relevance (contact-sheet review), app size (about 8 MB of photos), and the effort of about 120 well-written recipes (done in five reviewed batches).
