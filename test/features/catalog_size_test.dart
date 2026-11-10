import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/catalog/ingredient_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IngredientCatalog catalog;

  setUpAll(() async {
    catalog = IngredientCatalog.fromJson(await rootBundle.loadString('assets/data/ingredients.json'));
  });

  test('the catalog has at least 160 ingredients', () {
    expect(catalog.all.length, greaterThanOrEqualTo(160));
  });

  test('ingredients needed for real meals exist', () {
    const needed = [
      'leek', 'radish', 'arugula', 'cherry_tomato', 'ground_turkey', 'turkey_breast', 'white_fish',
      'sardines', 'halloumi', 'ricotta', 'lasagna_sheets', 'barley', 'freekeh', 'puff_pastry',
      'pizza_dough', 'tomato_sauce', 'silan', 'cornstarch', 'yeast', 'powdered_sugar', 'harissa',
      'hummus', 'baharat', 'pine_nuts', 'pistachios', 'cashews', 'dates', 'coconut_flakes',
      'pomegranate_molasses', 'matbucha',
    ];
    for (final id in needed) {
      expect(catalog.byId(id), isNotNull, reason: id);
    }
  });

  test('new ingredients resolve by their Hebrew names', () {
    expect(catalog.resolve('כרישה')?.id, 'leek');
    expect(catalog.resolve('צנוברים')?.id, 'pine_nuts');
    expect(catalog.resolve('סילאן')?.id, 'silan');
    expect(catalog.resolve('חלומי')?.id, 'halloumi');
    expect(catalog.resolve('מטבוחה')?.id, 'matbucha');
  });

  test('every new ingredient has its own icon, not the category fallback', () {
    for (final id in ['leek', 'pizza_dough', 'puff_pastry', 'pine_nuts', 'white_fish']) {
      final category = catalog.byId(id)!.category;
      expect(ingredientEmoji(id, category), isNot(kCategoryEmoji[category]), reason: id);
    }
  });
}
