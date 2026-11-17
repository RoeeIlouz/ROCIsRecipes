import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/prices/recipe_cost.dart';
import 'package:rocis_recipes/features/prices/store_resolver.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

ResolvedStore _resolved(Map<String, double> prices) => ResolvedStore(
  chainId: 'shufersal',
  store: PriceStore(
    id: 's:1',
    chainId: 'shufersal',
    name: 'b',
    address: 'x',
    lat: 32,
    lng: 34.8,
    prices: prices,
  ),
  distanceKm: 1,
  source: StoreSource.gps,
);

Recipe _recipe(int servings, List<RecipeIngredient> ings) => Recipe(
  id: 'r',
  titleHe: 'מנה',
  servings: servings,
  ingredients: ings,
  steps: const [RecipeStep(textHe: 'x')],
  totalMinutes: 20,
);

void main() {
  test('a dish costs what all its needed ingredients cost, per serving', () {
    final cost = estimateRecipeCost(
      _recipe(3, const [
        RecipeIngredient(ingredientId: 'chicken'),
        RecipeIngredient(ingredientId: 'rice'),
      ]),
      [
        _resolved({'chicken': 20, 'rice': 10}),
      ],
      stapleIds: const {},
    );
    expect(cost!.total, 30);
    expect(cost.perServing, 10);
  });

  test('staples at home and optional ingredients are not counted', () {
    final cost = estimateRecipeCost(
      _recipe(2, const [
        RecipeIngredient(ingredientId: 'chicken'),
        RecipeIngredient(ingredientId: 'oil'),
        RecipeIngredient(ingredientId: 'parsley', optional: true),
      ]),
      [
        _resolved({'chicken': 20, 'oil': 15, 'parsley': 5}),
      ],
      stapleIds: const {'oil'},
    );
    expect(cost!.total, 20);
    expect(cost.perServing, 10);
  });

  test('no known prices means no estimate', () {
    final cost = estimateRecipeCost(
      _recipe(2, const [RecipeIngredient(ingredientId: 'chicken')]),
      [_resolved({})],
      stapleIds: const {},
    );
    expect(cost, isNull);
  });

  test('a dish with no servings listed is priced for one', () {
    final cost = estimateRecipeCost(
      _recipe(0, const [RecipeIngredient(ingredientId: 'rice')]),
      [
        _resolved({'rice': 9}),
      ],
      stapleIds: const {},
    );
    expect(cost!.perServing, 9);
  });
}
