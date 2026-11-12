import 'dart:convert';

import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

/// Bump when assets/recipes/starter_he.json changes so existing installs sync.
const int kStarterVersion = 7;

/// Minimum number of steps a real meal recipe must have (strict validation).
const int kMinSteps = 6;

class StarterRecipeLoader {
  /// Checks the raw JSON for appliance names that [Recipe.fromJson] would
  /// silently drop (typos), which would make a recipe look appliance-free.
  static List<String> validateJson(String json) {
    final problems = <String>[];
    for (final e in jsonDecode(json) as List<dynamic>) {
      final m = Map<String, dynamic>.from(e as Map);
      for (final name in (m['appliances'] as List<dynamic>? ?? const [])) {
        if (applianceFromName(name as String) == null) {
          problems.add('${m['id']}: unknown appliance $name');
        }
      }
    }
    return problems;
  }

  static List<Recipe> parse(String json) => (jsonDecode(json) as List<dynamic>)
      .map((e) => Recipe.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  /// Returns human-readable problems; an empty list means the recipes are valid.
  ///
  /// [strict] also requires real-meal quality: at least [kMinSteps] steps,
  /// servings from 1 to 8, and a quantity and unit for every required
  /// ingredient that is not a staple. [requirePhoto] requires a photo (except
  /// for ids in [noPhotoAllowed]); [assetExists] additionally checks that each
  /// photo file is really bundled.
  static List<String> validate(
    List<Recipe> recipes,
    IngredientCatalog catalog, {
    bool strict = false,
    bool requirePhoto = false,
    Set<String> noPhotoAllowed = const {},
    bool Function(String asset)? assetExists,
  }) {
    final problems = <String>[];
    final seen = <String>{};
    for (final r in recipes) {
      if (!seen.add(r.id)) problems.add('${r.id}: duplicate recipe id');
      if (r.totalMinutes <= 0)
        problems.add('${r.id}: totalMinutes must be > 0');
      if (r.steps.isEmpty) problems.add('${r.id}: recipe has no steps');
      if (r.ingredients.isEmpty)
        problems.add('${r.id}: recipe has no ingredients');
      for (final ing in r.ingredients) {
        final known = catalog.byId(ing.ingredientId);
        if (known == null) {
          problems.add('${r.id}: unknown ingredient id ${ing.ingredientId}');
        } else if (strict &&
            !ing.optional &&
            !known.isStaple &&
            (ing.quantity == null || ing.unit == null || ing.unit!.isEmpty)) {
          problems.add(
            '${r.id}: ingredient ${ing.ingredientId} needs a quantity and unit',
          );
        }
      }
      if (strict) {
        if (r.steps.isNotEmpty && r.steps.length < kMinSteps) {
          problems.add(
            '${r.id}: recipe has only ${r.steps.length} steps (need at least $kMinSteps)',
          );
        }
        if (r.servings < 1 || r.servings > 8) {
          problems.add('${r.id}: servings must be 1 to 8, got ${r.servings}');
        }
      }
      if (requirePhoto) {
        final photo = r.photo;
        if (photo == null) {
          if (!noPhotoAllowed.contains(r.id))
            problems.add('${r.id}: recipe has no photo');
        } else if (assetExists != null && !assetExists(photo.asset)) {
          problems.add('${r.id}: photo asset missing: ${photo.asset}');
        }
      }
    }
    return problems;
  }
}
