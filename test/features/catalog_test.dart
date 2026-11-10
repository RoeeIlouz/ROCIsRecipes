import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/catalog/ingredient.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';

const _fixture = [
  Ingredient(
    id: 'tomato',
    nameHe: 'עגבנייה',
    nameEn: 'Tomato',
    synonyms: ['עגבניות'],
  ),
  Ingredient(
    id: 'cucumber',
    nameHe: 'מלפפון',
    nameEn: 'Cucumber',
    synonyms: ['מלפפונים'],
  ),
  Ingredient(id: 'salt', nameHe: 'מלח', nameEn: 'Salt', isStaple: true),
  Ingredient(
    id: 'pepper',
    nameHe: 'פלפל שחור',
    nameEn: 'Black pepper',
    isStaple: true,
  ),
  Ingredient(id: 'oil', nameHe: 'שמן', nameEn: 'Oil', isStaple: true),
  Ingredient(id: 'water', nameHe: 'מים', nameEn: 'Water', isStaple: true),
];

void main() {
  final catalog = IngredientCatalog(_fixture);

  test('resolves Hebrew plural via synonyms, ignoring niqqud', () {
    expect(catalog.resolve('עַגְבָנִיּוֹת')?.id, 'tomato');
  });

  test('resolves English name case-insensitively', () {
    expect(catalog.resolve(' TOMATO ')?.id, 'tomato');
  });

  test('resolves regardless of final letter form', () {
    expect(catalog.resolve('מלפפון')?.id, 'cucumber');
    expect(catalog.resolve('מלפפונ')?.id, 'cucumber');
  });

  test(
    'resolveOrCustom returns a custom non-staple ingredient for unknown text',
    () {
      final custom = catalog.resolveOrCustom('  פיצוחים ');
      expect(custom.id, startsWith('custom:'));
      expect(custom.isStaple, isFalse);
      expect(custom.nameHe, 'פיצוחים');
    },
  );

  test('resolveOrCustom does not throw on blank text', () {
    expect(catalog.resolveOrCustom('   ').id, 'custom:');
  });

  test('resolveOrCustom returns the catalog item when known', () {
    expect(catalog.resolveOrCustom('מלח').id, 'salt');
  });

  test('search is prefix-based on normalized names and respects limit', () {
    expect(catalog.search('עגב').map((e) => e.id), ['tomato']);
    expect(catalog.search('').isEmpty, isTrue);
    expect(catalog.search('m', limit: 1).length, lessThanOrEqualTo(1));
  });

  test('defaultStapleIds contains the staples', () {
    expect(catalog.defaultStapleIds, {'salt', 'pepper', 'oil', 'water'});
  });

  test('byId finds known ids and returns null for unknown', () {
    expect(catalog.byId('salt')?.nameHe, 'מלח');
    expect(catalog.byId('nope'), isNull);
  });

  test(
    'asset catalog has unique ids, at least 120 entries and the staples',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final json = await rootBundle.loadString('assets/data/ingredients.json');
      final real = IngredientCatalog.fromJson(json);
      final ids = real.all.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.length, greaterThanOrEqualTo(120));
      expect(
        real.defaultStapleIds,
        containsAll(['salt', 'pepper', 'oil', 'water']),
      );
    },
  );
}
