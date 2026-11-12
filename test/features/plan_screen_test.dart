import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/plan/week_planner.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/plan/ui/plan_screen.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

import '../helpers/test_env.dart';

Recipe _r(String id, List<String> ings) => Recipe(
  id: id,
  titleHe: 'מנה $id',
  ingredients: [for (final i in ings) RecipeIngredient(ingredientId: i)],
  steps: const [RecipeStep(textHe: 'x')],
  totalMinutes: 20,
);

final _recipes = [
  _r('a', ['egg']),
  _r('b', ['milk']),
  _r('c', ['tomato']),
  _r('d', ['cucumber']),
  _r('e', ['egg', 'milk']),
  _r('f', ['egg', 'tomato']),
  _r('g', ['milk', 'tomato']),
  _r('h', ['cucumber', 'tomato']),
];

const _store = PriceStore(
  id: 's1',
  chainId: 'alpha',
  name: 'Alpha',
  address: '1 St',
  lat: 32.0,
  lng: 34.8,
  prices: {'egg': 10, 'milk': 8, 'tomato': 20, 'cucumber': 6},
);

Future<TestEnv> _env({int? budget}) async {
  final env = await TestEnv.create(
    recipes: _recipes,
    snapshot: PriceSnapshot(
      generatedAt: DateTime.now(),
      chains: const [PriceChain(id: 'alpha', nameHe: 'אלפא', nameEn: 'Alpha')],
      stores: const [_store],
    ),
  );
  env.nearby.setManual(const UserLocation(lat: 32.0, lng: 34.8), 'here');
  if (budget != null) await env.settings.setWeeklyBudget(budget);
  return env;
}

/// A tall screen so every day card is built (the list builds only what is on screen).
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _build(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('plan_build_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty week offers to build one, then shows a dish per day', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/plan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan_day_0')), findsNothing);
    await _build(tester);
    expect(env.settings.weekPlan, hasLength(7));
    expect(env.settings.weekPlan.whereType<String>(), hasLength(7));
    expect(find.byKey(const Key('plan_day_0')), findsOneWidget);
    expect(find.byKey(const Key('plan_total')), findsOneWidget);
  });

  testWidgets('a small budget leaves the days it cannot cover empty', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env(budget: 25);
    await tester.pumpWidget(env.wrapApp('/plan'));
    await tester.pumpAndSettle();
    await _build(tester);
    final filled = env.settings.weekPlan.whereType<String>().length;
    expect(filled, lessThan(7));
    expect(find.byKey(const Key('plan_empty_6')), findsOneWidget);
    expect(find.byKey(const Key('plan_over_budget')), findsNothing);
  });

  testWidgets('the plan is remembered when the screen is opened again', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/plan'));
    await tester.pumpAndSettle();
    await _build(tester);
    final saved = [...env.settings.weekPlan];
    await tester.pumpWidget(env.wrapApp('/plan'));
    await tester.pumpAndSettle();
    expect(env.settings.weekPlan, saved);
    expect(find.byKey(const Key('plan_day_3')), findsOneWidget);
  });

  testWidgets('swapping a day picks another dish and keeps the rest', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/plan'));
    await tester.pumpAndSettle();
    await _build(tester);
    final before = [...env.settings.weekPlan];
    await tester.ensureVisible(find.byKey(const Key('plan_swap_2')));
    await tester.tap(find.byKey(const Key('plan_swap_2')));
    await tester.pumpAndSettle();
    final after = env.settings.weekPlan;
    expect(after[2], isNot(before[2]));
    for (final i in [0, 1, 3, 4, 5, 6]) {
      expect(after[i], before[i]);
    }
  });

  testWidgets('a day can be skipped and brought back', (tester) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/plan'));
    await tester.pumpAndSettle();
    await _build(tester);
    await tester.ensureVisible(find.byKey(const Key('plan_skip_1')));
    await tester.tap(find.byKey(const Key('plan_skip_1')));
    await tester.pumpAndSettle();
    expect(env.settings.weekPlan[1], kSkippedDay);
    expect(find.byKey(const Key('plan_skipped_1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('plan_skip_1')));
    await tester.pumpAndSettle();
    expect(env.settings.weekPlan[1], isNot(kSkippedDay));
    expect(env.settings.weekPlan[1], isNotNull);
  });

  testWidgets('hiding a dish replaces it and keeps it out of future weeks', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/plan'));
    await tester.pumpAndSettle();
    await _build(tester);
    final hidden = env.settings.weekPlan[0]!;
    await tester.tap(find.byKey(const Key('plan_hide_0')));
    await tester.pumpAndSettle();
    expect(env.settings.hiddenRecipeIds, contains(hidden));
    expect(env.settings.weekPlan[0], isNot(hidden));
    await _build(tester);
    expect(env.settings.weekPlan, isNot(contains(hidden)));
  });

  testWidgets('the week\'s ingredients can be sent to the shopping list', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/plan'));
    await tester.pumpAndSettle();
    await _build(tester);
    await tester.ensureVisible(find.byKey(const Key('plan_add_to_list')));
    await tester.tap(find.byKey(const Key('plan_add_to_list')));
    await tester.pumpAndSettle();
    expect(env.shopping.items.map((i) => i.ingredientId).toSet(), {
      'egg',
      'milk',
      'tomato',
      'cucumber',
    });
  });

  testWidgets('the bottom bar has a menu tab', (tester) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/pantry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_plan')));
    await tester.pumpAndSettle();
    expect(find.byType(PlanScreen), findsOneWidget);
  });

  test('the plan, its start day and hidden dishes are stored', () async {
    final env = await TestEnv.create();
    expect(env.settings.weekPlan, isEmpty);
    await env.settings.setWeekPlan(['a', null, kSkippedDay]);
    expect(env.settings.weekPlan, ['a', null, kSkippedDay]);
    await env.settings.hideRecipe('x');
    expect(env.settings.hiddenRecipeIds, {'x'});
    await env.settings.setPlanChain('alpha');
    expect(env.settings.planChainId, 'alpha');
  });
}
