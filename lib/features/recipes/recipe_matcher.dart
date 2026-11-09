import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

enum MatchMode { cookNow, almostThere }

class RecipeMatch {
  const RecipeMatch({required this.recipe, required this.missingIngredientIds});

  final Recipe recipe;
  final List<String> missingIngredientIds;
}

class RecipeMatcher {
  /// Pure matching logic: no Flutter imports, no catalog lookups.
  ///
  /// A recipe is eligible when it fits [maxMinutes] and every appliance it
  /// needs is in [appliances]. Missing ingredients are the required ones not
  /// in [pantryIds] or [stapleIds]. [MatchMode.cookNow] keeps recipes with
  /// none missing; [MatchMode.almostThere] keeps 1 to [maxMissing] missing.
  /// Results are sorted by fewest missing, then shortest time.
  static List<RecipeMatch> match({
    required List<Recipe> recipes,
    required Set<String> pantryIds,
    required Set<String> stapleIds,
    required Set<Appliance> appliances,
    required int maxMinutes,
    required MatchMode mode,
    int maxMissing = 3,
  }) {
    final results = <RecipeMatch>[];
    for (final recipe in recipes) {
      if (recipe.totalMinutes > maxMinutes) continue;
      if (!appliances.containsAll(recipe.appliances)) continue;

      final missing = <String>[];
      for (final ing in recipe.ingredients) {
        if (ing.optional) continue;
        final id = ing.ingredientId;
        if (pantryIds.contains(id) || stapleIds.contains(id)) continue;
        if (!missing.contains(id)) missing.add(id);
      }

      final keep = switch (mode) {
        MatchMode.cookNow => missing.isEmpty,
        MatchMode.almostThere => missing.isNotEmpty && missing.length <= maxMissing,
      };
      if (keep) results.add(RecipeMatch(recipe: recipe, missingIngredientIds: missing));
    }
    results.sort((a, b) {
      final byMissing = a.missingIngredientIds.length.compareTo(b.missingIngredientIds.length);
      if (byMissing != 0) return byMissing;
      return a.recipe.totalMinutes.compareTo(b.recipe.totalMinutes);
    });
    return results;
  }
}
