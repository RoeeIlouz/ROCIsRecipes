import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/prices/budget.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/prices/recipe_cost.dart';
import 'package:rocis_recipes/features/prices/store_resolver.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';

import '../helpers/test_env.dart';

const _near = PriceStore(
  id: 'a1',
  chainId: 'alpha',
  name: 'Alpha Near',
  address: '1 Near St',
  lat: 32.01,
  lng: 34.8,
  prices: {'egg': 10, 'milk': 8, 'tomato': 40},
);
const _far = PriceStore(
  id: 'b1',
  chainId: 'beta',
  name: 'Beta Far',
  address: '2 Far St',
  lat: 32.1,
  lng: 34.8,
  prices: {'egg': 8, 'milk': 6, 'tomato': 40},
);

PriceSnapshot _snapshot() => PriceSnapshot(
  generatedAt: DateTime.now(),
  chains: const [
    PriceChain(id: 'beta', nameHe: 'בטא', nameEn: 'Beta'),
    PriceChain(id: 'alpha', nameHe: 'אלפא', nameEn: 'Alpha'),
  ],
  stores: const [_near, _far],
);

const _cheap = Recipe(
  id: 'cheap',
  titleHe: 'חביתה',
  ingredients: [
    RecipeIngredient(ingredientId: 'egg'),
    RecipeIngredient(ingredientId: 'milk'),
  ],
  steps: [RecipeStep(textHe: 'טורפים')],
  totalMinutes: 10,
);

const _pricey = Recipe(
  id: 'pricey',
  titleHe: 'סלט יקר',
  ingredients: [RecipeIngredient(ingredientId: 'tomato')],
  steps: [RecipeStep(textHe: 'חותכים')],
  totalMinutes: 10,
);

Future<TestEnv> _env({int? budget}) async {
  final env = await TestEnv.create(
    recipes: [_cheap, _pricey],
    snapshot: _snapshot(),
  );
  env.nearby.setManual(const UserLocation(lat: 32.0, lng: 34.8), 'here');
  if (budget != null) await env.settings.setWeeklyBudget(budget);
  return env;
}

void main() {
  test('the weekly budget is remembered and can be cleared', () async {
    final env = await TestEnv.create();
    expect(env.settings.weeklyBudget, isNull);
    await env.settings.setWeeklyBudget(250);
    expect(env.settings.weeklyBudget, 250);
    await env.settings.setWeeklyBudget(null);
    expect(env.settings.weeklyBudget, isNull);
  });

  test('budget status reports what is left, the share used and overspend', () {
    final ok = BudgetStatus(budget: 200, spent: 50);
    expect(ok.remaining, 150);
    expect(ok.fraction, 0.25);
    expect(ok.isOver, isFalse);
    final over = BudgetStatus(budget: 100, spent: 130);
    expect(over.remaining, -30);
    expect(over.fraction, 1.0);
    expect(over.isOver, isTrue);
  });

  test('buy cost uses the store that prices the most, then the cheapest', () {
    final resolved = [
      const ResolvedStore(
        chainId: 'alpha',
        store: _near,
        distanceKm: 1,
        source: StoreSource.gps,
      ),
      const ResolvedStore(
        chainId: 'beta',
        store: _far,
        distanceKm: 11,
        source: StoreSource.gps,
      ),
    ];
    final cost = estimateBuyCost(['egg', 'milk'], resolved)!;
    expect(cost.total, 14);
    expect(cost.unpriced, 0);
    final partial = estimateBuyCost(['egg', 'saffron'], resolved)!;
    expect(partial.total, 8);
    expect(partial.unpriced, 1);
    expect(estimateBuyCost(['saffron'], resolved), isNull);
    expect(estimateBuyCost(const [], resolved)!.total, 0);
    expect(estimateBuyCost(['egg'], const []), isNull);
  });

  testWidgets('the shopping tab shows the budget used and left', (
    tester,
  ) async {
    final env = await _env(budget: 100);
    await env.shopping.add(
      const ShoppingItem(id: 'e', label: 'ביצים', ingredientId: 'egg'),
    );
    await env.shopping.add(
      const ShoppingItem(id: 'm', label: 'חלב', ingredientId: 'milk'),
    );
    await tester.pumpWidget(env.wrapApp('/shopping'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('budget_card')), findsOneWidget);
    expect(find.byKey(const Key('budget_over')), findsNothing);
    // The list costs 14 at the cheapest chain, so 86 is left.
    expect(
      tester.widget<Text>(find.byKey(const Key('budget_remaining'))).data,
      contains('86'),
    );
  });

  testWidgets('a list above the budget is flagged', (tester) async {
    final env = await _env(budget: 10);
    await env.shopping.add(
      const ShoppingItem(id: 'e', label: 'ביצים', ingredientId: 'egg'),
    );
    await env.shopping.add(
      const ShoppingItem(id: 'm', label: 'חלב', ingredientId: 'milk'),
    );
    await tester.pumpWidget(env.wrapApp('/shopping'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('budget_over')), findsOneWidget);
  });

  testWidgets('the budget is set from the shopping tab', (tester) async {
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/shopping'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('budget_edit_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('budget_field')), '300');
    await tester.tap(find.byKey(const Key('budget_save')));
    await tester.pumpAndSettle();
    expect(env.settings.weeklyBudget, 300);
  });

  testWidgets('dish cards show what is needed to buy', (tester) async {
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_almost_there')));
    await tester.pumpAndSettle();
    final label = tester.widget<Text>(find.byKey(const Key('buy_cost_cheap')));
    expect(label.data, contains('14'));
  });

  testWidgets('the budget chip hides dishes that cost more than what is left', (
    tester,
  ) async {
    final env = await _env(budget: 30);
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_almost_there')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_cheap')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_pricey')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('budget_chip')),
      200,
      scrollable: find
          .ancestor(
            of: find.byKey(const Key('protein_chip_all')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('budget_chip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_cheap')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_pricey')), findsNothing);
  });

  testWidgets('without a budget there is no budget chip', (tester) async {
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('budget_chip')), findsNothing);
  });

  testWidgets('the stores screen lists branches nearest first and marks the '
      'cheapest chain for the list', (tester) async {
    final env = await _env();
    await env.shopping.add(
      const ShoppingItem(id: 'e', label: 'ביצים', ingredientId: 'egg'),
    );
    await tester.pumpWidget(env.wrapApp('/stores'));
    await tester.pumpAndSettle();
    final alpha = tester.getTopLeft(find.byKey(const Key('store_card_alpha')));
    final beta = tester.getTopLeft(find.byKey(const Key('store_card_beta')));
    expect(alpha.dy, lessThan(beta.dy));
    expect(
      find.descendant(
        of: find.byKey(const Key('store_card_beta')),
        matching: find.byKey(const Key('cheapest_badge')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('store_card_alpha')),
        matching: find.byKey(const Key('cheapest_badge')),
      ),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('store_navigate_alpha')));
    await tester.pump();
    expect(env.launched.single.toString(), contains('Near'));
  });

  testWidgets('without a location the stores screen asks for one', (
    tester,
  ) async {
    final env = await TestEnv.create(recipes: [_cheap], snapshot: _snapshot());
    await tester.pumpWidget(env.wrapApp('/stores'));
    await tester.pumpAndSettle();
    final hint = tester.widget<Text>(find.byKey(const Key('store_hint_alpha')));
    expect(hint.data, contains('מיקום'));
  });

  testWidgets('the shopping tab links to the stores screen', (tester) async {
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/shopping'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stores_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('store_card_alpha')), findsOneWidget);
  });
}
