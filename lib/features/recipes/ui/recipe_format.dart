import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

final Map<double, String> _fractions = {
  0.25: '¼',
  0.33: '⅓',
  0.5: '½',
  0.67: '⅔',
  0.75: '¾',
};

/// A quantity as people write it: 1½ rather than 1.5, and no trailing ".0".
String formatAmount(double q) {
  final whole = q.floor();
  final frac = q - whole;
  if (frac < 0.02) return '$whole';
  if (frac > 0.98) return '${whole + 1}';
  for (final entry in _fractions.entries) {
    if ((frac - entry.key).abs() < 0.02)
      return whole == 0 ? entry.value : '$whole${entry.value}';
  }
  final text = q.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// The unit name for [count] of it, in the current language (an unknown unit is shown as is).
String unitLabel(AppLocalizations l10n, String unit, num count) =>
    switch (unit) {
      'unit' => l10n.unitUnit,
      'g' => l10n.unitG,
      'kg' => l10n.unitKg,
      'ml' => l10n.unitMl,
      'l' => l10n.unitL,
      'pinch' => l10n.unitPinch,
      'tbsp' => l10n.unitTbsp(count),
      'tsp' => l10n.unitTsp(count),
      'cup' => l10n.unitCup(count),
      'clove' => l10n.unitClove(count),
      'bunch' => l10n.unitBunch(count),
      'can' => l10n.unitCan(count),
      'pack' => l10n.unitPack(count),
      'slice' => l10n.unitSlice(count),
      _ => unit,
    };

/// "2 כפות", "½ כוס", "4 יח'", or an empty string when the recipe gives no quantity.
String formatIngredientAmount(
  AppLocalizations l10n,
  RecipeIngredient ingredient,
) {
  final quantity = ingredient.quantity;
  if (quantity == null) return '';
  final amount = formatAmount(quantity);
  final unit = ingredient.unit;
  if (unit == null || unit.isEmpty) return amount;
  // Amounts of one or less take the singular form ("half a cup", not "half cups").
  return '$amount ${unitLabel(l10n, unit, quantity > 1 ? quantity : 1)}';
}

String mealTypeLabel(AppLocalizations l10n, String mealType) =>
    switch (mealType) {
      'breakfast' => l10n.mealBreakfast,
      'lunch' => l10n.mealLunch,
      'dinner' => l10n.mealDinner,
      'snack' => l10n.mealSnack,
      'dessert' => l10n.mealDessert,
      _ => mealType,
    };

String proteinLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'chicken' => l10n.proteinChicken,
  'beef' => l10n.proteinBeef,
  'fish' => l10n.proteinFish,
  'vegetarian' => l10n.proteinVegetarian,
  _ => kind,
};

/// Name of a [recipeKind] in the current language.
String kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'dessert' => l10n.mealDessert,
  'breakfast' => l10n.mealBreakfast,
  _ => proteinLabel(l10n, kind),
};

String difficultyLabel(AppLocalizations l10n, String difficulty) =>
    switch (difficulty) {
      'easy' => l10n.diffEasy,
      'medium' => l10n.diffMedium,
      _ => difficulty,
    };
