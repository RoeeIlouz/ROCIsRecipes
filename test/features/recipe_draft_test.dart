import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/ai/recipe_draft.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';

import '../helpers/test_env.dart';

void main() {
  final catalog = IngredientCatalog(testIngredients);

  test(
    'units are normalised from Hebrew and English spellings, unknown units are dropped',
    () {
      expect(normalizeUnit('גרם'), 'g');
      expect(normalizeUnit('Grams'), 'g');
      expect(normalizeUnit('כפות'), 'tbsp');
      expect(normalizeUnit('tsp'), 'tsp');
      expect(normalizeUnit('כוסות'), 'cup');
      expect(normalizeUnit("יח'"), 'unit');
      expect(normalizeUnit('whatever'), isNull);
      expect(normalizeUnit(null), isNull);
    },
  );

  test(
    'ingredient names are matched to the catalog, others become custom items',
    () {
      expect(matchIngredientId('ביצים', catalog), 'egg');
      expect(matchIngredientId('Tomato', catalog), 'tomato');
      expect(matchIngredientId('חלב', catalog), 'milk');
      expect(matchIngredientId('זעפרן', catalog), 'custom:זעפרן');
    },
  );

  test('a model reply becomes a user recipe draft', () {
    final r = recipeFromAiJson({
      'title': 'חביתה',
      'servings': 20,
      'minutes': 15,
      'ingredients': [
        {'name': 'ביצים', 'quantity': 3, 'unit': "יח'"},
        {'name': 'מלח', 'quantity': null, 'unit': null},
        {'name': 'זעפרן', 'quantity': 1, 'unit': 'קורט'},
      ],
      'steps': ['טורפים', '', 'צולים'],
    }, catalog)!;
    expect(r.isUserCreated, isTrue);
    expect(r.titleHe, 'חביתה');
    expect(r.servings, 8);
    expect(r.totalMinutes, 15);
    expect(r.ingredients.map((i) => i.ingredientId), [
      'egg',
      'salt',
      'custom:זעפרן',
    ]);
    expect(r.ingredients.first.quantity, 3);
    expect(r.ingredients.first.unit, 'unit');
    expect(r.ingredients.last.unit, 'pinch');
    expect(r.steps.map((s) => s.textHe), ['טורפים', 'צולים']);
  });

  test('a reply without a title, ingredients or steps is rejected', () {
    expect(
      recipeFromAiJson({'title': '', 'ingredients': [], 'steps': []}, catalog),
      isNull,
    );
    expect(
      recipeFromAiJson({
        'title': 'x',
        'ingredients': [
          {'name': 'ביצה'},
        ],
        'steps': [],
      }, catalog),
      isNull,
    );
    expect(recipeFromAiJson({'nonsense': true}, catalog), isNull);
  });

  test('replies wrapped in prose or code fences are still parsed', () {
    expect(extractJsonObject('Here you go:\n```json\n{"a": 1}\n```'), {'a': 1});
    expect(extractJsonObject('no json here'), isNull);
  });

  test(
    'ingredient names from a photo are matched, de-duplicated and capped',
    () {
      final found = ingredientIdsFromNames([
        'ביצים',
        'ביצה',
        'Tomato',
        'unknown thing',
      ], catalog);
      expect(found, ['egg', 'tomato']);
    },
  );
}
