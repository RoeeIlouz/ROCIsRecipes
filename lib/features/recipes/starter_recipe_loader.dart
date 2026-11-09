import 'dart:convert';

import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

/// Bump when assets/recipes/starter_he.json changes so existing installs sync.
const int kStarterVersion = 1;

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
  static List<String> validate(List<Recipe> recipes, IngredientCatalog catalog) {
    final problems = <String>[];
    final seen = <String>{};
    for (final r in recipes) {
      if (!seen.add(r.id)) problems.add('${r.id}: duplicate recipe id');
      if (r.totalMinutes <= 0) problems.add('${r.id}: totalMinutes must be > 0');
      if (r.steps.isEmpty) problems.add('${r.id}: recipe has no steps');
      if (r.ingredients.isEmpty) problems.add('${r.id}: recipe has no ingredients');
      for (final ing in r.ingredients) {
        if (catalog.byId(ing.ingredientId) == null) {
          problems.add('${r.id}: unknown ingredient id ${ing.ingredientId}');
        }
      }
    }
    return problems;
  }
}
