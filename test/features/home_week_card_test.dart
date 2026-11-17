import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

import '../helpers/test_env.dart';

Recipe _dinner(String id) => Recipe(
  id: id,
  titleHe: 'מנה $id',
  mealType: 'dinner',
  ingredients: [RecipeIngredient(ingredientId: 'egg_$id')],
  steps: const [RecipeStep(textHe: 'x')],
  totalMinutes: 20,
);

Future<void> _tall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('without a menu, Home offers to build the week', (tester) async {
    await _tall(tester);
    final env = await TestEnv.create(recipes: [_dinner('a'), _dinner('b')]);
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_week_build')), findsOneWidget);
    expect(find.byKey(const Key('home_week_card')), findsNothing);
    await tester.tap(find.byKey(const Key('home_week_build')));
    await tester.pumpAndSettle();
    expect(env.settings.weekPlan.any((e) => e != null), isTrue);
    expect(find.byKey(const Key('plan_build_button')), findsOneWidget);
  });

  testWidgets('with a menu, Home shows the week and its progress', (
    tester,
  ) async {
    await _tall(tester);
    final env = await TestEnv.create(recipes: [_dinner('a'), _dinner('b')]);
    await env.settings.setWeeklyBudget(300);
    await env.settings.setPlanStart(DateTime.now());
    await env.settings.setWeekPlan(['a', 'b', null, null, null, null, null]);
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_week_card')), findsOneWidget);
    expect(find.byKey(const Key('home_week_build')), findsNothing);
    final count = tester.widget<Text>(find.byKey(const Key('home_week_count')));
    expect(count.data, contains('2'));
    expect(find.byKey(const Key('home_week_bar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_week_card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan_build_button')), findsOneWidget);
  });
}
