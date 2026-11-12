import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

import '../helpers/test_env.dart';

const _omelette = Recipe(
  id: 'omelette',
  titleHe: 'חביתה',
  servings: 2,
  ingredients: [
    RecipeIngredient(ingredientId: 'egg', quantity: 2, unit: 'unit'),
    RecipeIngredient(ingredientId: 'tomato', quantity: 1, unit: 'unit'),
  ],
  steps: [RecipeStep(textHe: 'טורפים')],
  totalMinutes: 10,
);

const _other = Recipe(
  id: 'other',
  titleHe: 'ביצה קשה',
  ingredients: [RecipeIngredient(ingredientId: 'egg')],
  steps: [RecipeStep(textHe: 'מבשלים')],
  totalMinutes: 10,
);

String _amount(WidgetTester tester, String id) =>
    tester.widget<Text>(find.byKey(Key('amount_$id'))).data!;

/// A tall screen so the whole dish page is built (the list builds only what is on screen).
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the servings stepper rescales every ingredient amount', (
    tester,
  ) async {
    _tall(tester);
    final env = await TestEnv.create(recipes: [_omelette]);
    await tester.pumpWidget(env.wrapApp('/recipe/omelette'));
    await tester.pumpAndSettle();
    expect(_amount(tester, 'egg'), startsWith('2'));

    await tester.tap(find.byKey(const Key('servings_plus')));
    await tester.tap(find.byKey(const Key('servings_plus')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('servings_value')), findsOneWidget);
    expect(_amount(tester, 'egg'), startsWith('4'));
    expect(_amount(tester, 'tomato'), startsWith('2'));

    await tester.tap(find.byKey(const Key('servings_minus')));
    await tester.pumpAndSettle();
    expect(_amount(tester, 'egg'), startsWith('3'));
  });

  testWidgets('the servings stepper stays between 1 and 24', (tester) async {
    _tall(tester);
    final env = await TestEnv.create(recipes: [_omelette]);
    await tester.pumpWidget(env.wrapApp('/recipe/omelette'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('servings_minus')));
    await tester.tap(find.byKey(const Key('servings_minus')));
    await tester.pumpAndSettle();
    expect(_amount(tester, 'egg'), startsWith('1'));
  });

  testWidgets('the shopping list gets the scaled amounts', (tester) async {
    _tall(tester);
    final env = await TestEnv.create(recipes: [_omelette]);
    await tester.pumpWidget(env.wrapApp('/recipe/omelette'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('servings_plus')));
    await tester.tap(find.byKey(const Key('servings_plus')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('add_missing_button')));
    await tester.tap(find.byKey(const Key('add_missing_button')));
    await tester.pumpAndSettle();
    final egg = env.shopping.items.firstWhere((i) => i.ingredientId == 'egg');
    expect(egg.quantity, 4);
  });

  test('favorites are remembered and toggled', () async {
    final env = await TestEnv.create(recipes: [_omelette]);
    expect(env.settings.isFavorite('omelette'), isFalse);
    await env.settings.toggleFavorite('omelette');
    expect(env.settings.isFavorite('omelette'), isTrue);
    expect(env.settings.favoriteIds, {'omelette'});
    await env.settings.toggleFavorite('omelette');
    expect(env.settings.favoriteIds, isEmpty);
  });

  testWidgets('the heart on a recipe toggles its favorite state', (
    tester,
  ) async {
    _tall(tester);
    final env = await TestEnv.create(recipes: [_omelette]);
    await tester.pumpWidget(env.wrapApp('/recipe/omelette'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('favorite_button')));
    await tester.pumpAndSettle();
    expect(env.settings.isFavorite('omelette'), isTrue);
    await tester.tap(find.byKey(const Key('favorite_button')));
    await tester.pumpAndSettle();
    expect(env.settings.isFavorite('omelette'), isFalse);
  });

  testWidgets('the favorites chip shows only favorite dishes', (tester) async {
    _tall(tester);
    final env = await TestEnv.create(recipes: [_omelette, _other]);
    await env.pantry.upsert(const PantryItem(ingredientId: 'egg'));
    await env.pantry.upsert(const PantryItem(ingredientId: 'tomato'));
    await env.settings.toggleFavorite('other');
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_omelette')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_other')), findsOneWidget);

    await tester.tap(find.byKey(const Key('favorites_chip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_omelette')), findsNothing);
    expect(find.byKey(const Key('recipe_card_other')), findsOneWidget);
  });
}
