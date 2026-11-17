import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/home/ui/home_screen.dart';
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
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  test('settings remember the household size and the finished setup', () async {
    final env = await TestEnv.create(onboarded: false);
    expect(env.settings.onboardingDone, isFalse);
    expect(env.settings.householdSize, 1);
    await env.settings.setHouseholdSize(3);
    await env.settings.setOnboardingDone(true);
    expect(env.settings.householdSize, 3);
    expect(env.settings.onboardingDone, isTrue);
    await env.settings.setHouseholdSize(99);
    expect(env.settings.householdSize, 8);
  });

  testWidgets('a first run opens the welcome screen', (tester) async {
    await _tall(tester);
    final env = await TestEnv.create(onboarded: false);
    await tester.pumpWidget(env.wrapApp('/'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onb_start')), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('after setup the app opens normally', (tester) async {
    await _tall(tester);
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrapApp('/'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onb_start')), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('skipping goes to Home and does not ask again', (tester) async {
    await _tall(tester);
    final env = await TestEnv.create(onboarded: false);
    await tester.pumpWidget(env.wrapApp('/'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onb_skip')));
    await tester.pumpAndSettle();
    expect(env.settings.onboardingDone, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('budget and household are saved and a week is built', (
    tester,
  ) async {
    await _tall(tester);
    final env = await TestEnv.create(
      onboarded: false,
      recipes: [_dinner('a'), _dinner('b'), _dinner('c')],
    );
    await tester.pumpWidget(env.wrapApp('/'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onb_start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onb_budget_300')));
    await tester.tap(find.byKey(const Key('onb_people_plus')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onb_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onb_finish_build')));
    await tester.pumpAndSettle();
    expect(env.settings.weeklyBudget, 300);
    expect(env.settings.householdSize, 2);
    expect(env.settings.onboardingDone, isTrue);
    expect(env.settings.weekPlan.any((e) => e != null), isTrue);
    expect(find.byKey(const Key('plan_build_button')), findsOneWidget);
  });
}
