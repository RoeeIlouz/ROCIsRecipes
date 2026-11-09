import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';

void main() {
  test('PantryItem keeps its custom label through JSON', () {
    const item = PantryItem(ingredientId: 'custom:פיצוחימ', label: 'פיצוחים');
    final back = PantryItem.fromJson(item.toJson());
    expect(back, item);
    expect(back.label, 'פיצוחים');
    expect(const PantryItem(ingredientId: 'egg').toJson().containsKey('label'), isFalse);
  });
}
