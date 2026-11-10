import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_filters.dart';

import '../helpers/test_env.dart';

Recipe _r(
  String id,
  List<String> ingredients, {
  bool mealPrep = false,
  String meal = 'dinner',
  List<String> optional = const [],
}) => Recipe(
  id: id,
  titleHe: 'מתכון $id',
  ingredients: [
    for (final i in ingredients)
      RecipeIngredient(ingredientId: i, quantity: 1, unit: 'unit'),
    for (final i in optional)
      RecipeIngredient(
        ingredientId: i,
        quantity: 1,
        unit: 'unit',
        optional: true,
      ),
  ],
  steps: const [RecipeStep(textHe: 'שלב')],
  totalMinutes: 20,
  mealType: meal,
  mealPrep: mealPrep,
);

void main() {
  group('proteinKinds', () {
    test('poultry, beef and fish are recognised from required ingredients', () {
      expect(proteinKinds(_r('a', ['chicken_breast', 'rice'])), {'chicken'});
      expect(proteinKinds(_r('b', ['ground_beef'])), {'beef'});
      expect(proteinKinds(_r('c', ['salmon'])), {'fish'});
      expect(proteinKinds(_r('d', ['chicken', 'sausage'])), {
        'chicken',
        'beef',
      });
    });

    test(
      'no meat or fish means vegetarian, and optional meat does not count',
      () {
        expect(proteinKinds(_r('e', ['egg', 'tomato'])), {'vegetarian'});
        expect(proteinKinds(_r('f', ['egg'], optional: ['tuna'])), {
          'vegetarian',
        });
      },
    );
  });

  test('matchesFilters combines meal type, protein and meal prep', () {
    final prep = _r('p', ['chicken_breast'], mealPrep: true, meal: 'lunch');
    expect(matchesFilters(prep), isTrue);
    expect(
      matchesFilters(
        prep,
        meal: 'lunch',
        protein: 'chicken',
        mealPrepOnly: true,
      ),
      isTrue,
    );
    expect(matchesFilters(prep, meal: 'dinner'), isFalse);
    expect(matchesFilters(prep, protein: 'beef'), isFalse);
    expect(matchesFilters(_r('q', ['egg']), mealPrepOnly: true), isFalse);
  });

  test(
    'the meal prep flag survives a json round trip and defaults to false',
    () {
      final prep = _r('p', ['egg'], mealPrep: true);
      expect(Recipe.fromJson(prep.toJson()).mealPrep, isTrue);
      expect(Recipe.fromJson(_r('n', ['egg']).toJson()).mealPrep, isFalse);
    },
  );

  testWidgets('protein and meal prep chips filter the suggestion tabs', (
    tester,
  ) async {
    final env = await TestEnv.create(
      recipes: [
        _r('chick', ['egg', 'chicken_breast']),
        _r('veg', ['egg']),
        _r('prep', ['egg', 'milk'], mealPrep: true),
      ],
    );
    for (final id in ['egg', 'chicken_breast', 'milk']) {
      await env.pantry.upsert(PantryItem(ingredientId: id));
    }
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_chick')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_veg')), findsOneWidget);

    await tester.tap(find.byKey(const Key('protein_chip_chicken')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_chick')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_veg')), findsNothing);

    await tester.tap(find.byKey(const Key('protein_chip_all')));
    await tester.tap(find.byKey(const Key('meal_prep_chip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_prep')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_veg')), findsNothing);
  });
}
