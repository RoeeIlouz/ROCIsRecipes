import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/catalog/ingredient_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IngredientCatalog catalog;

  setUpAll(() async {
    catalog = IngredientCatalog.fromJson(
      await rootBundle.loadString('assets/data/ingredients.json'),
    );
  });

  test('every catalog ingredient has a known category', () {
    for (final i in catalog.all) {
      expect(kIngredientCategories, contains(i.category), reason: i.id);
    }
  });

  test('every category is used by at least five ingredients', () {
    for (final c in kIngredientCategories) {
      expect(
        catalog.all.where((i) => i.category == c).length,
        greaterThanOrEqualTo(5),
        reason: c,
      );
    }
  });

  test('every catalog ingredient gets a non-empty icon', () {
    for (final i in catalog.all) {
      expect(ingredientEmoji(i.id, i.category), isNotEmpty, reason: i.id);
    }
  });

  test(
    'common ingredients have their own icon rather than the category fallback',
    () {
      expect(ingredientEmoji('tomato', 'produce'), '🍅');
      expect(ingredientEmoji('egg', 'dairy'), '🥚');
      expect(ingredientEmoji('milk', 'dairy'), '🥛');
    },
  );

  test(
    'an ingredient without its own icon falls back to its category icon',
    () {
      expect(ingredientEmoji('mystery', 'spices'), kCategoryEmoji['spices']);
    },
  );

  test('custom ingredients and unknown categories get a generic icon', () {
    expect(ingredientEmoji('custom:xyz', null), '🍽️');
    expect(ingredientEmoji('mystery', 'nonsense'), '🍽️');
  });
}
