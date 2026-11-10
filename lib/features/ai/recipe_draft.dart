import 'dart:convert';

import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

/// JSON schema the on-device model must follow when it reads a recipe.
const Map<String, Object?> kRecipeSchema = {
  'type': 'object',
  'properties': {
    'title': {'type': 'string'},
    'servings': {'type': 'integer'},
    'minutes': {'type': 'integer'},
    'ingredients': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'quantity': {'type': 'number'},
          'unit': {'type': 'string'},
        },
        'required': ['name'],
      },
    },
    'steps': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['title', 'ingredients', 'steps'],
};

/// JSON schema for "which ingredients are in this photo".
const Map<String, Object?> kIngredientListSchema = {
  'type': 'object',
  'properties': {
    'ingredients': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['ingredients'],
};

const _unitWords = <String, String>{
  'unit': 'unit',
  'units': 'unit',
  'pcs': 'unit',
  'piece': 'unit',
  'pieces': 'unit',
  "יח'": 'unit',
  'יחידה': 'unit',
  'יחידות': 'unit',
  'g': 'g',
  'gram': 'g',
  'grams': 'g',
  'גרם': 'g',
  'גר': 'g',
  "גר'": 'g',
  'kg': 'kg',
  'kilogram': 'kg',
  'kilograms': 'kg',
  'קילו': 'kg',
  'ק"ג': 'kg',
  'קילוגרם': 'kg',
  'ml': 'ml',
  'milliliter': 'ml',
  'milliliters': 'ml',
  'מ"ל': 'ml',
  'מיליליטר': 'ml',
  'l': 'l',
  'liter': 'l',
  'liters': 'l',
  'ליטר': 'l',
  'tbsp': 'tbsp',
  'tablespoon': 'tbsp',
  'tablespoons': 'tbsp',
  'כף': 'tbsp',
  'כפות': 'tbsp',
  'tsp': 'tsp',
  'teaspoon': 'tsp',
  'teaspoons': 'tsp',
  'כפית': 'tsp',
  'כפיות': 'tsp',
  'cup': 'cup',
  'cups': 'cup',
  'כוס': 'cup',
  'כוסות': 'cup',
  'clove': 'clove',
  'cloves': 'clove',
  'שן': 'clove',
  'שיניים': 'clove',
  'bunch': 'bunch',
  'bunches': 'bunch',
  'צרור': 'bunch',
  'צרורות': 'bunch',
  'can': 'can',
  'cans': 'can',
  'קופסה': 'can',
  'קופסאות': 'can',
  'קופסת': 'can',
  'pack': 'pack',
  'packs': 'pack',
  'package': 'pack',
  'חבילה': 'pack',
  'חבילות': 'pack',
  'slice': 'slice',
  'slices': 'slice',
  'פרוסה': 'slice',
  'פרוסות': 'slice',
  'pinch': 'pinch',
  'קורט': 'pinch',
};

/// One of the app's unit keys for [raw], or null when it is not a unit the app knows.
String? normalizeUnit(String? raw) {
  if (raw == null) return null;
  return _unitWords[raw.trim().toLowerCase()];
}

String _norm(String s) => s.trim().toLowerCase();

/// Catalog id for an ingredient name written by a person or a model; unknown names become a custom item.
String matchIngredientId(String name, IngredientCatalog catalog) {
  final n = _norm(name);
  for (final i in catalog.all) {
    if (_norm(i.nameHe) == n ||
        _norm(i.nameEn) == n ||
        i.synonyms.any((s) => _norm(s) == n))
      return i.id;
  }
  final hits = catalog.search(name.trim(), limit: 1);
  if (hits.isNotEmpty) return hits.first.id;
  return 'custom:${name.trim()}';
}

/// Catalog ids only (unknown names are skipped), without duplicates, for the photo-pantry flow.
List<String> ingredientIdsFromNames(
  Iterable<String> names,
  IngredientCatalog catalog, {
  int max = 30,
}) {
  final ids = <String>[];
  for (final name in names) {
    final id = matchIngredientId(name, catalog);
    if (id.startsWith('custom:') || ids.contains(id)) continue;
    ids.add(id);
    if (ids.length >= max) break;
  }
  return ids;
}

/// A recipe draft from the model's JSON, or null when it has no title, ingredient or step.
Recipe? recipeFromAiJson(Map<String, dynamic> json, IngredientCatalog catalog) {
  final title = (json['title'] as String?)?.trim() ?? '';
  final rawIngredients = (json['ingredients'] as List?) ?? const [];
  final steps = [
    for (final s in (json['steps'] as List?) ?? const [])
      if (s is String && s.trim().isNotEmpty) s.trim(),
  ];
  final ingredients = <RecipeIngredient>[];
  for (final item in rawIngredients) {
    if (item is! Map) continue;
    final name = (item['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) continue;
    final q = item['quantity'];
    ingredients.add(
      RecipeIngredient(
        ingredientId: matchIngredientId(name, catalog),
        quantity: q is num && q > 0 ? q.toDouble() : null,
        unit: normalizeUnit(item['unit'] as String?),
      ),
    );
  }
  if (title.isEmpty || ingredients.isEmpty || steps.isEmpty) return null;
  return Recipe(
    id: 'user_${DateTime.now().microsecondsSinceEpoch}',
    titleHe: title,
    ingredients: ingredients,
    steps: [for (final s in steps) RecipeStep(textHe: s)],
    totalMinutes: ((json['minutes'] as num?)?.toInt() ?? 30).clamp(1, 600),
    servings: ((json['servings'] as num?)?.toInt() ?? 2).clamp(1, 8),
    isUserCreated: true,
  );
}

/// Pulls the first JSON object out of a reply that may carry prose or code fences around it.
Map<String, dynamic>? extractJsonObject(String text) {
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final v = jsonDecode(text.substring(start, end + 1));
    return v is Map<String, dynamic> ? v : null;
  } catch (_) {
    return null;
  }
}
