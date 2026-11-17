import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

import '../helpers/test_env.dart';

const _store = PriceStore(
  id: 'a1',
  chainId: 'alpha',
  name: 'Alpha',
  address: '1 St',
  lat: 32.01,
  lng: 34.8,
  prices: {'egg': 10, 'milk': 4},
);

const _dish = Recipe(
  id: 'omelette',
  titleHe: 'חביתה',
  servings: 2,
  ingredients: [
    RecipeIngredient(ingredientId: 'egg'),
    RecipeIngredient(ingredientId: 'milk'),
  ],
  steps: [RecipeStep(textHe: 'טורפים')],
  totalMinutes: 10,
);

Future<TestEnv> _env({bool prices = true}) async {
  final env = await TestEnv.create(
    recipes: [_dish],
    snapshot: prices
        ? PriceSnapshot(
            generatedAt: DateTime.now(),
            chains: const [
              PriceChain(id: 'alpha', nameHe: 'אלפא', nameEn: 'Alpha'),
            ],
            stores: const [_store],
          )
        : null,
  );
  env.nearby.setManual(const UserLocation(lat: 32.0, lng: 34.8), 'here');
  return env;
}

void main() {
  testWidgets('a dish card shows the price of one serving', (tester) async {
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_all')));
    await tester.pumpAndSettle();
    final label = tester.widget<Text>(
      find.byKey(const Key('serving_cost_omelette')),
    );
    expect(label.data, contains('7'));
  });

  testWidgets('without prices a dish card shows no serving price', (
    tester,
  ) async {
    final env = await _env(prices: false);
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('serving_cost_omelette')), findsNothing);
  });

  testWidgets('the dish page shows the price of one serving', (tester) async {
    final env = await _env();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(env.wrapApp('/recipe/omelette'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail_serving_cost')), findsOneWidget);
  });
}
