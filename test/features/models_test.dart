import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';

void main() {
  test('Recipe round-trips through JSON', () {
    const r = Recipe(
      id: 'r1',
      titleHe: 'שקשוקה',
      titleEn: 'Shakshuka',
      ingredients: [
        RecipeIngredient(ingredientId: 'egg', quantity: 3, unit: 'unit'),
        RecipeIngredient(ingredientId: 'parsley', optional: true),
      ],
      steps: [
        RecipeStep(textHe: 'מבשלים', textEn: 'Cook', timerSeconds: 300),
        RecipeStep(textHe: 'מגישים'),
      ],
      appliances: {Appliance.stovetop, Appliance.oven},
      totalMinutes: 25,
    );
    final back = Recipe.fromJson(r.toJson());
    expect(back, r);
    expect(back.ingredients[1].optional, isTrue);
    expect(back.steps.first.timerSeconds, 300);
    expect(back.appliances, {Appliance.stovetop, Appliance.oven});
    expect(back.isUserCreated, isFalse);
  });

  test('Appliance parses by name and unknown names are dropped', () {
    final r = Recipe.fromJson({
      'id': 'r2',
      'titleHe': 'x',
      'ingredients': <dynamic>[],
      'steps': [
        {'textHe': 'a'}
      ],
      'appliances': ['oven', 'spaceship'],
      'totalMinutes': 5,
    });
    expect(r.appliances, {Appliance.oven});
  });

  test('ShoppingItem.copyWith toggles checked', () {
    const item = ShoppingItem(id: 's1', label: 'חלב');
    final toggled = item.copyWith(checked: true);
    expect(item.checked, isFalse);
    expect(toggled.checked, isTrue);
    expect(ShoppingItem.fromJson(toggled.toJson()), toggled);
  });
}
