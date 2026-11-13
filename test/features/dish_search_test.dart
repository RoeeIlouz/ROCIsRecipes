import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_filters.dart';
import 'package:rocis_recipes/features/recipes/recipe_matcher.dart';

import '../helpers/test_env.dart';

Recipe _r(String id, String title, List<String> ings, {String? en}) => Recipe(
  id: id,
  titleHe: title,
  titleEn: en,
  ingredients: [for (final i in ings) RecipeIngredient(ingredientId: i)],
  steps: const [RecipeStep(textHe: 'x')],
  totalMinutes: 20,
);

String _names(String id) => switch (id) {
  'egg' => 'ביצה ביצים egg',
  'milk' => 'חלב milk',
  'tomato' => 'עגבנייה עגבניות tomato',
  _ => id,
};

void main() {
  final omelette = _r('o', 'חביתה מושלמת', [
    'egg',
    'milk',
  ], en: 'Perfect omelette');
  final salad = _r('s', 'סלט עגבניות', ['tomato']);

  test('an empty search matches everything', () {
    expect(matchesQuery(omelette, '', _names), isTrue);
    expect(matchesQuery(omelette, '   ', _names), isTrue);
  });

  test('a search matches the Hebrew or English title', () {
    expect(matchesQuery(omelette, 'חביתה', _names), isTrue);
    expect(matchesQuery(omelette, 'omelette', _names), isTrue);
    expect(matchesQuery(omelette, 'OMELETTE', _names), isTrue);
    expect(matchesQuery(salad, 'חביתה', _names), isFalse);
  });

  test('a search matches an ingredient name', () {
    expect(matchesQuery(omelette, 'חלב', _names), isTrue);
    expect(matchesQuery(omelette, 'milk', _names), isTrue);
    expect(matchesQuery(salad, 'חלב', _names), isFalse);
  });

  test('every word of the search has to match something', () {
    expect(matchesQuery(omelette, 'חביתה חלב', _names), isTrue);
    expect(matchesQuery(omelette, 'חביתה עגבניה', _names), isFalse);
  });

  test('the all-dishes list keeps dishes needing many ingredients', () {
    final big = _r('big', 'גדול', ['a', 'b', 'c', 'd', 'e']);
    final all = RecipeMatcher.match(
      recipes: [big, omelette],
      pantryIds: const {},
      stapleIds: const {},
      appliances: const {},
      maxMinutes: 5,
      mode: MatchMode.all,
    );
    expect(all.map((m) => m.recipe.id), containsAll(['big', 'o']));
    expect(
      all.firstWhere((m) => m.recipe.id == 'big').missingIngredientIds,
      hasLength(5),
    );
  });

  testWidgets('the all dishes tab lists every dish, even far from cookable', (
    tester,
  ) async {
    final env = await TestEnv.create(
      recipes: [
        omelette,
        _r('far', 'מנה רחוקה', ['tomato', 'milk', 'egg', 'cucumber', 'salt']),
      ],
    );
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_far')), findsNothing);
    await tester.tap(find.byKey(const Key('tab_all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_far')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_o')), findsOneWidget);
  });

  testWidgets('typing in the search box narrows the list', (tester) async {
    final env = await TestEnv.create(recipes: [omelette, salad]);
    await env.pantry.upsert(const PantryItem(ingredientId: 'egg'));
    await env.pantry.upsert(const PantryItem(ingredientId: 'milk'));
    await env.pantry.upsert(const PantryItem(ingredientId: 'tomato'));
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_o')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_s')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('dish_search')), 'חלב');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_o')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_s')), findsNothing);
    await tester.enterText(find.byKey(const Key('dish_search')), '');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_s')), findsOneWidget);
  });
}
