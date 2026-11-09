---
ontology: true
type: plan
domain: rocis-recipes
summary: Plan 1 of 3 for ROCIsRecipes, covers phases 1 to 3 of the design (foundation, what-can-I-cook, shopping list)
tags: [flutter, hive, hebrew, rtl, recipes, shopping-list]
status: draft
discovered: 2026-11-09
workspace: ROCIsSideProjects
related: [2026-11-09-rocis-recipes-design]
---

# ROCIsRecipes Core App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A working Hebrew-first Flutter Android app where the user enters pantry, appliances and time, sees "cook now" and "almost there" dishes from a starter collection, follows guided cooking steps, and keeps a shopping list.

**Architecture:** Feature-first Flutter app in the ROCIsApps style. All data local in Hive (JSON maps, no codegen), exposed through `ChangeNotifier` repositories with Provider. Pure-Dart domain logic (ingredient resolution, recipe matching) is separated from UI so it is unit tested without widgets. Prices are out of scope here (Plan 2).

**Tech Stack:** Flutter 3.44.9 (installed), `hive_ce ^2.20.0`, `hive_ce_flutter ^2.3.0`, `provider ^6.1.5+1`, `go_router ^17.0.1`, `google_fonts ^8.2.1` (versions copied from ROCIs-tasks), `flutter_localizations`, `intl`.

**Spec:** `docs/superpowers/specs/2026-11-09-rocis-recipes-design.md`

**Later plans (not in this plan):** Plan 2: price pipeline spike, weekly snapshot, per-chain totals, nearest store. Plan 3: user-created recipes with own photos, photo pantry input, ROCIsTasks sync.

## Global Constraints

- Platform: Android only, Flutter, org `com.rocisapps`, project name `rocis_recipes`.
- Offline-first: every user write goes to a local Hive box first. No login, no Firebase in this plan.
- Zero hardcoded UI strings. All strings in `lib/l10n/app_he.arb` and `lib/l10n/app_en.arb`. Default locale is Hebrew (RTL); English (LTR) must also work.
- Theme: Light, Slate Dark, AMOLED (`#000000` background, `Colors.white12` borders), glass cards via `GlassContainer`, font Outfit via `google_fonts`. Reuse the templates in the rocis-app-builder skill's `templates/` folder (`AppConfig`, `AppInitializer`, `AppTheme`, `ThemeService`, `GlassContainer`, `l10n.yaml`, ARB files).
- Staples assumed available by default: salt, pepper, oil, water (user-editable list).
- Starter collection: 50 to 100 recipes, mainly Hebrew, each tagged with appliances and total minutes.
- Pantry items are present or absent with optional quantity.
- Appliance set (my call, from the design's "left to builder"): stovetop, oven, microwave, airFryer, blender, kettle, toaster, riceCooker.
- Quality gate for every task: `flutter analyze` reports zero issues and `flutter test` passes before commit.

## Review Focus

Failure modes the spec implies but does not state, most likely first. Each has a test in the owning task.

1. No appliances selected: only recipes needing no appliance may appear (Task 6).
2. Empty pantry: no crash; "cook now" is empty, "almost there" contains only recipes whose missing count is within the limit (Task 6).
3. Hebrew input variants (niqqud, final letters, extra spaces, quotes) resolve to the same ingredient; unknown text becomes a custom ingredient instead of an error (Task 3).
4. A recipe references an ingredient id missing from the catalog: the loader test fails the build, and the matcher treats it as missing without crashing (Tasks 5 and 6).
5. Very long Hebrew titles and 320 dp width must not overflow in the recipe card (Task 8).

---

## File Structure

```
lib/
  main.dart                      # runApp(RecipesApp) after AppInitializer.initialize()
  app.dart                       # RecipesApp: MaterialApp.router, theme, locale he
  core/config/{app_config.dart, router.dart}
  core/services/app_initializer.dart   # opens Hive boxes, builds providers
  core/text/hebrew_normalizer.dart
  shared/ui/{theme/, widgets/glass_container.dart}      # from templates
  features/catalog/{ingredient.dart, ingredient_catalog.dart}
  features/recipes/{recipe.dart, appliance.dart, recipe_repository.dart, starter_recipe_loader.dart, recipe_matcher.dart, ui/}
  features/pantry/{pantry_item.dart, pantry_repository.dart, settings_repository.dart, ui/}
  features/shopping/{shopping_item.dart, shopping_repository.dart, ui/}
  l10n/{app_he.arb, app_en.arb}
assets/data/{ingredients.json}
assets/recipes/{starter_he.json}
test/ (mirrors lib/)
```

---

### Task 1: Scaffold, theme, localization shell

**Files:**
- Create: project via `flutter create`, `pubspec.yaml` deps, `l10n.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/core/config/app_config.dart`, `lib/core/services/app_initializer.dart`, `lib/shared/ui/**`, `lib/l10n/app_he.arb`, `lib/l10n/app_en.arb`
- Test: `test/app_test.dart`

**Interfaces:**
- Produces: `class RecipesApp extends StatelessWidget { const RecipesApp({super.key, this.providers = const []}); }` where `providers` is `List<SingleChildWidget>`; `AppInitializer.initialize() -> Future<List<SingleChildWidget>>` (extended by Task 4).

- [ ] **Step 1:** In the ROCIsRecipes folder run `git init`, then `flutter create --org com.rocisapps --project-name rocis_recipes --platforms android .`. Expected: project files created, existing `docs/` untouched.
- [ ] **Step 2: Write failing test** `test/app_test.dart`: pump `const RecipesApp()` with `await tester.pumpAndSettle()`; assert `Directionality.of(tester.element(find.byType(Scaffold).first)) == TextDirection.rtl` (test name `defaults to Hebrew RTL`); second test `switches to English LTR` pumps with a locale override and asserts `TextDirection.ltr`. Add optional `locale` parameter to `RecipesApp` for this.
- [ ] **Step 3:** Run `flutter test test/app_test.dart`. Expected: FAIL, `RecipesApp` not defined.
- [ ] **Step 4:** Add the dependencies listed above to `pubspec.yaml`; copy the template files into the paths in File Structure; set `AppConfig` name to "ROCIs Recipes"; write `l10n.yaml` from the template; implement `RecipesApp` as `MaterialApp.router` using `AppTheme`, `ThemeService` and `Locale('he')` default, with a placeholder home `Scaffold`. Run `flutter gen-l10n`.
- [ ] **Step 5:** Run `flutter test test/app_test.dart` and `flutter analyze`. Expected: PASS, no issues.
- [ ] **Step 6:** Commit `chore: scaffold ROCIsRecipes with theme and Hebrew localization`.

---

### Task 2: Domain models

**Files:**
- Create: `lib/features/recipes/appliance.dart`, `lib/features/recipes/recipe.dart`, `lib/features/catalog/ingredient.dart`, `lib/features/pantry/pantry_item.dart`, `lib/features/shopping/shopping_item.dart`
- Test: `test/features/models_test.dart`

**Interfaces:**
- Produces:
  - `enum Appliance { stovetop, oven, microwave, airFryer, blender, kettle, toaster, riceCooker }`
  - `class Ingredient { final String id; final String nameHe; final String nameEn; final List<String> synonyms; final bool isStaple; factory Ingredient.fromJson(Map<String, dynamic>); Map<String, dynamic> toJson(); }`
  - `class RecipeIngredient { final String ingredientId; final double? quantity; final String? unit; final bool optional; }` with `fromJson`/`toJson`
  - `class RecipeStep { final String textHe; final String? textEn; final int? timerSeconds; }`
  - `class Recipe { final String id; final String titleHe; final String? titleEn; final List<RecipeIngredient> ingredients; final List<RecipeStep> steps; final Set<Appliance> appliances; final int totalMinutes; final bool isUserCreated; final String? imagePath; }` with `fromJson`/`toJson`
  - `class PantryItem { final String ingredientId; final double? quantity; final String? unit; }`
  - `class ShoppingItem { final String id; final String? ingredientId; final String label; final double? quantity; final String? unit; final bool checked; ShoppingItem copyWith({...}); }`; all with `fromJson`/`toJson`

- [ ] **Step 1: Write failing tests** `models_test.dart`: `Recipe round-trips through JSON` (build a recipe with two appliances, an optional ingredient, a step with `timerSeconds: 300`; assert `Recipe.fromJson(r.toJson())` equals field by field), `Appliance parses by name and unknown names are dropped` (`fromJson` with appliances `['oven','spaceship']` yields `{Appliance.oven}`), `ShoppingItem.copyWith toggles checked`.
- [ ] **Step 2:** Run `flutter test test/features/models_test.dart`. Expected: FAIL.
- [ ] **Step 3:** Implement the models as immutable classes with `==`/`hashCode` on `Recipe` and `ShoppingItem`.
- [ ] **Step 4:** Run the test and `flutter analyze`. Expected: PASS.
- [ ] **Step 5:** Commit `feat: domain models`.

---

### Task 3: Hebrew normalizer and ingredient catalog

**Files:**
- Create: `lib/core/text/hebrew_normalizer.dart`, `lib/features/catalog/ingredient_catalog.dart`, `assets/data/ingredients.json` (register in `pubspec.yaml`)
- Test: `test/core/hebrew_normalizer_test.dart`, `test/features/catalog_test.dart`

**Interfaces:**
- Consumes: `Ingredient` (Task 2).
- Produces:
  - `String normalizeText(String input)`: strips niqqud (U+0591 to U+05C7), removes geresh/gershayim/quotes/punctuation, trims, collapses whitespace, lowercases Latin, maps final letters to regular forms (ך→כ, ם→מ, ן→נ, ף→פ, ץ→צ).
  - `class IngredientCatalog { IngredientCatalog(List<Ingredient> items); factory IngredientCatalog.fromJson(String json); Ingredient? resolve(String text); Ingredient resolveOrCustom(String text); List<Ingredient> search(String prefix, {int limit = 8}); Ingredient? byId(String id); List<Ingredient> get all; Set<String> get defaultStapleIds; }`

- [ ] **Step 1: Write failing tests.** Normalizer: `strips niqqud and final letters` (`normalizeText('  עַגְבָנִיּוֹת  ') == 'עגבניות'`; `normalizeText('לחם ' ) == 'לחמ'`); `ignores quotes and case` (`normalizeText('Olive  OIL') == 'olive oil'`). Catalog (small inline fixture): `resolves Hebrew plural via synonyms`, `resolves English name`, `resolveOrCustom returns id starting with "custom:" and isStaple false for unknown text` (also for input `'  '` it must not throw; return a custom item with id `custom:`), `search is prefix-based on normalized names`, `defaultStapleIds contains salt, pepper, oil, water ids`.
- [ ] **Step 2:** Run both tests. Expected: FAIL.
- [ ] **Step 3:** Implement. Index every `nameHe`, `nameEn` and synonym by `normalizeText`. Author `assets/data/ingredients.json` with at least 120 common Israeli kitchen ingredients (id slug, nameHe, nameEn, synonyms including plural forms, `isStaple`).
- [ ] **Step 4:** Run tests and `flutter analyze`. Expected: PASS. Add a test `asset catalog has unique ids and at least 120 entries` that loads the real asset.
- [ ] **Step 5:** Commit `feat: Hebrew normalizer and ingredient catalog`.

---

### Task 4: Local repositories and initializer

**Files:**
- Create: `lib/features/pantry/pantry_repository.dart`, `lib/features/pantry/settings_repository.dart`, `lib/features/recipes/recipe_repository.dart`, `lib/features/shopping/shopping_repository.dart`
- Modify: `lib/core/services/app_initializer.dart`
- Test: `test/features/repositories_test.dart`

**Interfaces:**
- Consumes: all Task 2 models.
- Produces (all extend `ChangeNotifier`, constructed with an opened `Box<Map>`/`Box`):
  - `PantryRepository(Box<Map> box)`: `List<PantryItem> get items; Set<String> get ids; Future<void> upsert(PantryItem); Future<void> remove(String ingredientId);`
  - `SettingsRepository(Box box)`: `Set<Appliance> get appliances; Future<void> setAppliances(Set<Appliance>); Set<String> get stapleIds; Future<void> setStapleIds(Set<String>); int get maxMinutes; Future<void> setMaxMinutes(int);` (default `maxMinutes` 45, default `stapleIds` empty until seeded from catalog defaults by the initializer)
  - `RecipeRepository(Box<Map> box)`: `List<Recipe> get all; Future<void> seedIfEmpty(List<Recipe>); Future<void> upsert(Recipe);`
  - `ShoppingRepository(Box<Map> box)`: `List<ShoppingItem> get items; Future<void> add(ShoppingItem); Future<void> addMissing(Iterable<ShoppingItem>)` (skips an item whose `ingredientId` is already unchecked on the list); `Future<void> toggle(String id); Future<void> remove(String id); Future<void> clearChecked();`

- [ ] **Step 1: Write failing tests** using `Hive.init` on a temp dir: `pantry upsert replaces same ingredient and persists across reopen`, `shopping addMissing does not duplicate an unchecked ingredient`, `settings default maxMinutes is 45`, `recipe seedIfEmpty is a no-op when recipes exist`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement repositories storing models as JSON maps; each mutation writes to Hive first, then calls `notifyListeners()`. Extend `AppInitializer.initialize()` to `Hive.initFlutter()`, open boxes, load catalog and starter recipes (Task 5), and return `ChangeNotifierProvider`/`Provider` entries.
- [ ] **Step 4:** Run tests and `flutter analyze`. Expected: PASS.
- [ ] **Step 5:** Commit `feat: local repositories`.

---

### Task 5: Starter recipe collection

**Files:**
- Create: `assets/recipes/starter_he.json` (register in `pubspec.yaml`), `lib/features/recipes/starter_recipe_loader.dart`
- Test: `test/features/starter_recipes_test.dart`

**Interfaces:**
- Consumes: `Recipe`, `IngredientCatalog`.
- Produces: `class StarterRecipeLoader { static List<Recipe> parse(String json); static List<String> validate(List<Recipe> recipes, IngredientCatalog catalog); }` where `validate` returns human-readable problems (empty list means valid).

- [ ] **Step 1: Write failing tests:** `every starter recipe passes validation against the real catalog` (loads both assets; `validate(...)` is empty), `starter collection has between 50 and 100 recipes`, `at least 90 percent have Hebrew titles` (design says mainly Hebrew), `validate reports an unknown ingredient id` (inline fixture with `ingredientId: 'nope'`; expect one problem naming the recipe id and `nope`), `validate rejects totalMinutes <= 0 and recipes with no steps`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement `parse` and `validate`. Author the recipes: 50 to 100 simple student-friendly dishes (eggs, pasta, rice, salads, shakshuka, soups, sandwiches, no-cook dishes included so Review Focus 1 has data), each with Hebrew steps, appliances, `totalMinutes`. Source: write original recipes or take from a free source only after confirming its licence; record the source and licence in `assets/recipes/SOURCES.md`. Any ingredient missing from the catalog is added to `ingredients.json` in the same commit.
- [ ] **Step 4:** Run tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat: starter recipe collection`.

---

### Task 6: Recipe matcher

**Files:**
- Create: `lib/features/recipes/recipe_matcher.dart`
- Test: `test/features/recipe_matcher_test.dart`

**Interfaces:**
- Consumes: `Recipe`, `Appliance`.
- Produces:
  - `enum MatchMode { cookNow, almostThere }`
  - `class RecipeMatch { final Recipe recipe; final List<String> missingIngredientIds; }`
  - `class RecipeMatcher { static List<RecipeMatch> match({required List<Recipe> recipes, required Set<String> pantryIds, required Set<String> stapleIds, required Set<Appliance> appliances, required int maxMinutes, required MatchMode mode, int maxMissing = 3}); }`
  - Rules: a recipe is eligible if `totalMinutes <= maxMinutes` and every appliance it needs is owned. Missing = required (non-optional) ingredients not in `pantryIds` or `stapleIds`. `cookNow` keeps missing == 0. `almostThere` keeps 1 to `maxMissing` missing. Sort by fewest missing, then shortest time.

- [ ] **Step 1: Write failing tests:** `cookNow returns only fully covered recipes`, `staples count as available`, `optional ingredients never count as missing`, `almostThere returns 1 to 3 missing sorted by fewest missing`, `recipe over time limit is excluded`, `recipe needing an unowned appliance is excluded`, `no appliances selected keeps only no-appliance recipes` (Review Focus 1), `empty pantry cookNow is empty and almostThere only has recipes within maxMissing` (Review Focus 2), `unknown ingredient id counts as missing and does not throw` (Review Focus 4).
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement as a pure function with no Flutter imports.
- [ ] **Step 4:** Run tests and `flutter analyze`. Expected: PASS.
- [ ] **Step 5:** Commit `feat: recipe matcher`.

---

### Task 7: Pantry, appliances and time entry UI

**Files:**
- Create: `lib/features/pantry/ui/pantry_screen.dart`, `lib/features/pantry/ui/appliance_picker.dart`; modify `lib/core/config/router.dart`, ARB files
- Test: `test/features/pantry_ui_test.dart`

**Interfaces:**
- Consumes: `PantryRepository`, `SettingsRepository`, `IngredientCatalog` via Provider.
- Produces: route `/pantry`; `class PantryScreen extends StatelessWidget`; `class AppliancePicker extends StatelessWidget` taking `Set<Appliance> selected` and `ValueChanged<Set<Appliance>> onChanged`.

- [ ] **Step 1: Write failing widget tests:** `typing a Hebrew ingredient with niqqud and tapping add stores the catalog ingredient` (Review Focus 3), `typing unknown text adds a custom ingredient and shows it`, `tapping a suggestion from search adds it`, `selecting appliances persists to SettingsRepository`, `time chips update maxMinutes` (chips: 15, 30, 45, 60, 90).
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement: text field with autocomplete from `IngredientCatalog.search`, a pick-from-list sheet grouped alphabetically, removable pantry chips, appliance multi-select, time chips. All strings via ARB in both languages. Photo input is not in this plan.
- [ ] **Step 4:** Run tests and `flutter analyze`. Expected: PASS.
- [ ] **Step 5:** Commit `feat: pantry and appliance entry`.

---

### Task 8: Suggestions, recipe detail, guided cooking

**Files:**
- Create: `lib/features/recipes/ui/suggestions_screen.dart`, `recipe_card.dart`, `recipe_detail_screen.dart`, `cooking_mode_screen.dart`; modify `router.dart`, ARB files
- Test: `test/features/recipes_ui_test.dart`

**Interfaces:**
- Consumes: `RecipeMatcher.match`, repositories, `ShoppingRepository.addMissing`.
- Produces: routes `/suggestions` (tabs "Cook now" and "Almost there"), `/recipe/:id`, `/cook/:id`; `RecipeCard({required Recipe recipe, required int missingCount})`.

- [ ] **Step 1: Write failing widget tests:** `suggestions shows cook now and almost there tabs from pantry state`, `almost there card shows missing count and detail lists missing ingredients`, `add missing to shopping list button adds items and skips duplicates`, `cooking mode steps forward and back and shows a step timer when timerSeconds is set`, `RecipeCard with a 120 character Hebrew title at 320 dp width does not overflow` (Review Focus 5: `expect(tester.takeException(), isNull)`).
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement screens with `GlassContainer` cards; the cooking mode keeps the screen awake via `wakelock_plus` (verify the latest version on pub.dev before adding) and uses a local countdown for step timers.
- [ ] **Step 4:** Run tests and `flutter analyze`. Expected: PASS.
- [ ] **Step 5:** Commit `feat: suggestions, recipe detail and guided cooking`.

---

### Task 9: Shopping list UI and app navigation

**Files:**
- Create: `lib/features/shopping/ui/shopping_screen.dart`; modify `router.dart`, ARB files
- Test: `test/features/shopping_ui_test.dart`

**Interfaces:**
- Consumes: `ShoppingRepository`, `IngredientCatalog.resolveOrCustom`.
- Produces: route `/shopping`; bottom navigation with Pantry, Suggestions, Shopping.

- [ ] **Step 1: Write failing widget tests:** `adding free text creates an item`, `checking an item moves it to the done section`, `clear checked removes only checked items`, `bottom navigation switches between the three screens`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement the screen and navigation shell. The list leaves room for a price line per item, rendered only when a price exists (Plan 2 supplies prices).
- [ ] **Step 4:** Run `flutter test`, `flutter analyze`. Expected: all PASS. Then `flutter run` on an emulator or device and walk through: add pantry items in Hebrew, pick appliances, see suggestions, cook a dish, add missing items to the list, switch theme to AMOLED, switch language to English. Report anything that fails.
- [ ] **Step 5:** Commit `feat: shopping list and navigation`.

---

## Self-Review

- Spec coverage: goals 1, 2, 3, 5 (typed and picked), 7 and the shopping list part of 4 are covered here. Goal 4 prices, goal 5 photo, goal 6 and goal 8 are in Plans 2 and 3 by design, so they have no task in this plan.
- Types are consistent across tasks: `Recipe`, `RecipeIngredient`, `Appliance`, `PantryItem`, `ShoppingItem`, `IngredientCatalog`, `MatchMode`, `RecipeMatch`.
- Open risk carried from the design: licence and Hebrew coverage of any free recipe source, handled in Task 5 by writing original recipes if no source qualifies.
