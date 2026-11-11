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

/// Field names for a model that cannot follow [kRecipeSchema] (no constrained decoding), so it still
/// answers with the keys the app reads.
const String kRecipeJsonHint =
    'Use exactly this JSON shape: {"title": "...", "servings": 2, "minutes": 30, '
    '"ingredients": [{"name": "...", "quantity": 1, "unit": "unit"}], "steps": ["...", "..."]}';

String? _firstString(Map json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

List _firstList(Map json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is List) return v;
  }
  return const [];
}

/// Models sometimes wrap the recipe ({"recipe": {...}}); returns the inner object in that case.
Map _unwrapRecipe(Map json) {
  if (json['title'] != null || json['ingredients'] != null) return json;
  for (final k in const ['recipe', 'dish', 'data', 'result']) {
    final v = json[k];
    if (v is Map) return v;
  }
  return json;
}

/// "2 ביצים" or "כוס אורז" written as one line: quantity and unit are split off the name.
RecipeIngredient _ingredientFromText(String text, IngredientCatalog catalog) {
  final m = RegExp(
    r'^\s*(\d+(?:[./]\d+)?)?\s*(.*)$',
  ).matchAsPrefix(text.trim());
  var rest = (m?.group(2) ?? text).trim();
  double? quantity;
  final num = m?.group(1);
  if (num != null) {
    final parts = num.split('/');
    quantity = parts.length == 2
        ? (double.tryParse(parts[0]) ?? 0) / (double.tryParse(parts[1]) ?? 1)
        : double.tryParse(num);
  }
  String? unit;
  final words = rest.split(RegExp(r'\s+'));
  if (words.length > 1) {
    final u = normalizeUnit(words.first);
    if (u != null) {
      unit = u;
      rest = words.skip(1).join(' ');
      if (rest.startsWith('של ')) rest = rest.substring(3);
    }
  }
  if (quantity != null && quantity <= 0) quantity = null;
  return RecipeIngredient(
    ingredientId: matchIngredientId(rest, catalog),
    quantity: quantity,
    unit: unit,
  );
}

/// A recipe draft from the model's JSON, or null when it has no title, ingredient or step.
/// Tolerates the common alternative key names and ingredients/steps written as plain strings.
Recipe? recipeFromAiJson(
  Map<String, dynamic> input,
  IngredientCatalog catalog,
) {
  final json = _unwrapRecipe(input);
  final title =
      _firstString(json, const [
        'title',
        'name',
        'recipe_name',
        'dish_name',
        'dish',
        'recipe',
      ]) ??
      '';
  final steps = <String>[];
  for (final s in _firstList(json, const [
    'steps',
    'instructions',
    'directions',
    'method',
  ])) {
    final text = s is String
        ? s
        : s is Map
        ? _firstString(s, const ['text', 'step', 'instruction', 'description'])
        : null;
    if (text != null && text.trim().isNotEmpty) steps.add(text.trim());
  }
  final ingredients = <RecipeIngredient>[];
  for (final item in _firstList(json, const [
    'ingredients',
    'ingredient_list',
  ])) {
    if (item is String) {
      if (item.trim().isNotEmpty)
        ingredients.add(_ingredientFromText(item, catalog));
      continue;
    }
    if (item is! Map) continue;
    final name = _firstString(item, const ['name', 'ingredient', 'item']) ?? '';
    if (name.isEmpty) continue;
    final q = item['quantity'] ?? item['amount'];
    ingredients.add(
      RecipeIngredient(
        ingredientId: matchIngredientId(name, catalog),
        quantity: q is num && q > 0 ? q.toDouble() : null,
        unit: normalizeUnit(item['unit'] as String?),
      ),
    );
  }
  if (title.isEmpty || ingredients.isEmpty || steps.isEmpty) return null;
  final minutes = json['minutes'] ?? json['total_minutes'] ?? json['time'];
  return Recipe(
    id: 'user_${DateTime.now().microsecondsSinceEpoch}',
    titleHe: title,
    ingredients: ingredients,
    steps: [for (final s in steps) RecipeStep(textHe: s)],
    totalMinutes: ((minutes as num?)?.toInt() ?? 30).clamp(1, 600),
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
