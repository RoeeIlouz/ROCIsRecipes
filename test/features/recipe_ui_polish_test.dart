import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_filters.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_card.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_photo.dart';

import '../helpers/test_env.dart';

Recipe _r(
  String id,
  List<String> ings, {
  String meal = 'dinner',
  bool mealPrep = false,
}) => Recipe(
  id: id,
  titleHe: 'מנה $id',
  ingredients: [for (final i in ings) RecipeIngredient(ingredientId: i)],
  steps: const [RecipeStep(textHe: 'x')],
  totalMinutes: 20,
  mealType: meal,
  mealPrep: mealPrep,
);

void main() {
  test('every dish gets one kind, used for its placeholder and tags', () {
    expect(recipeKind(_r('a', ['chicken_breast', 'rice'])), 'chicken');
    expect(recipeKind(_r('b', ['ground_beef', 'pasta'])), 'beef');
    expect(recipeKind(_r('c', ['salmon'])), 'fish');
    expect(recipeKind(_r('d', ['tomato'])), 'vegetarian');
    expect(recipeKind(_r('e', ['flour', 'sugar'], meal: 'dessert')), 'dessert');
    expect(recipeKind(_r('f', ['egg'], meal: 'breakfast')), 'breakfast');
    // A dessert or breakfast is those first, whatever else it contains.
    expect(recipeKind(_r('g', ['chicken'], meal: 'breakfast')), 'breakfast');
    // Chicken wins over beef when a dish has both.
    expect(recipeKind(_r('h', ['chicken', 'ground_beef'])), 'chicken');
  });

  testWidgets('a dish without a photo shows an icon for its kind', (
    tester,
  ) async {
    final env = await TestEnv.create();
    for (final entry in {
      'chicken': Icons.dinner_dining,
      'beef': Icons.kebab_dining,
      'fish': Icons.set_meal,
      'vegetarian': Icons.eco,
      'dessert': Icons.bakery_dining,
      'breakfast': Icons.free_breakfast,
    }.entries) {
      await tester.pumpWidget(
        env.wrap(
          Scaffold(
            body: RecipePhotoView(
              photo: null,
              kind: entry.key,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('photo_placeholder')),
          matching: find.byIcon(entry.value),
        ),
        findsOneWidget,
        reason: entry.key,
      );
    }
  });

  testWidgets('without a kind the placeholder keeps the plain icon', (
    tester,
  ) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(
      env.wrap(
        const Scaffold(
          body: RecipePhotoView(photo: null, width: 100, height: 100),
        ),
      ),
    );
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
  });

  testWidgets('a card tags meal prep dishes and favorites', (tester) async {
    final env = await TestEnv.create();
    await env.settings.toggleFavorite('fav');
    await tester.pumpWidget(
      env.wrap(
        Scaffold(
          body: ListView(
            children: [
              RecipeCard(
                key: const Key('card_fav'),
                recipe: _r('fav', ['chicken'], mealPrep: true),
                missingCount: 0,
              ),
              RecipeCard(
                key: const Key('card_plain'),
                recipe: _r('plain', ['tomato']),
                missingCount: 0,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('recipe_meal_prep_fav')), findsOneWidget);
    expect(find.byKey(const Key('recipe_favorite_fav')), findsOneWidget);
    expect(find.byKey(const Key('recipe_meal_prep_plain')), findsNothing);
    expect(find.byKey(const Key('recipe_favorite_plain')), findsNothing);
    // The kind of dish is named on the card.
    expect(find.byKey(const Key('recipe_kind_fav')), findsOneWidget);
  });

  testWidgets('the dish page shows the title once, over the photo', (
    tester,
  ) async {
    final env = await TestEnv.create(
      recipes: [
        _r('r1', ['egg']),
      ],
    );
    await tester.pumpWidget(env.wrapApp('/recipe/r1'));
    await tester.pumpAndSettle();
    expect(find.text('מנה r1'), findsOneWidget);
    expect(find.byKey(const Key('recipe_hero')), findsOneWidget);
    expect(find.byKey(const Key('start_cooking_button')), findsOneWidget);
  });
}
