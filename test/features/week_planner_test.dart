import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/plan/week_planner.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

Recipe _r(
  String id,
  List<String> ings, {
  int minutes = 20,
  String meal = 'dinner',
  Set<Appliance> appliances = const {},
}) => Recipe(
  id: id,
  titleHe: id,
  ingredients: [for (final i in ings) RecipeIngredient(ingredientId: i)],
  steps: [const RecipeStep(textHe: 'x')],
  totalMinutes: minutes,
  mealType: meal,
  appliances: appliances,
);

const _store = PriceStore(
  id: 's',
  chainId: 'c',
  name: 'S',
  address: 'A',
  lat: 0,
  lng: 0,
  prices: {
    'egg': 10,
    'milk': 8,
    'tomato': 20,
    'chicken': 30,
    'rice': 6,
    'onion': 4,
  },
);

final _eggMilk = _r('egg_milk', ['egg', 'milk']); // 18
final _eggTomato = _r('egg_tomato', ['egg', 'tomato']); // 30, or 20 after egg
final _chickenRice = _r('chicken_rice', ['chicken', 'rice']); // 36
final _riceOnion = _r('rice_onion', ['rice', 'onion']); // 10
final _pantryOnly = _r('pantry_only', ['salt', 'rice']); // 0 with rice at home

List<String?> _plan(
  List<Recipe> recipes, {
  Set<String> pantry = const {'salt'},
  double? budget,
  int days = 3,
  Set<String> excluded = const {},
  Set<Appliance> appliances = const {Appliance.stovetop},
  List<String?>? current,
  Set<int>? rebuild,
  Set<String> excludedIngredients = const {},
  int seed = 0,
}) => generateWeekPlan(
  recipes: recipes,
  pantryIds: pantry,
  stapleIds: const {'salt'},
  appliances: appliances,
  maxMinutes: 60,
  store: _store,
  budget: budget,
  excludedIds: excluded,
  excludedIngredientIds: excludedIngredients,
  current: current,
  rebuildDays: rebuild,
  days: days,
  seed: seed,
);

void main() {
  final all = [_eggMilk, _eggTomato, _chickenRice, _riceOnion, _pantryOnly];

  test('the plan never costs more than the budget', () {
    final plan = _plan(all, budget: 40, days: 5);
    final summary = summarizePlan(
      plan,
      all,
      pantryIds: const {'salt'},
      stapleIds: const {'salt'},
      store: _store,
    );
    expect(summary.total, lessThanOrEqualTo(40));
    expect(plan.whereType<String>(), isNotEmpty);
  });

  test('dishes that need nothing new are planned first', () {
    final plan = _plan(all, pantry: const {'salt', 'rice'}, days: 2);
    expect(plan.first, 'pantry_only');
  });

  test('no dish appears twice and days are filled while dishes last', () {
    final plan = _plan(all, days: 5);
    expect(plan.whereType<String>().toSet().length, 5);
  });

  test('an excluded dish is never planned', () {
    final plan = _plan(all, days: 5, excluded: {'egg_milk', 'rice_onion'});
    expect(plan, isNot(contains('egg_milk')));
    expect(plan, isNot(contains('rice_onion')));
  });

  test('ingredients shared with earlier days cost nothing again', () {
    final plan = _plan([_eggMilk, _eggTomato], days: 2);
    final summary = summarizePlan(
      plan,
      [_eggMilk, _eggTomato],
      pantryIds: const {'salt'},
      stapleIds: const {'salt'},
      store: _store,
    );
    // egg 10 + milk 8 + tomato 20, the egg is bought once.
    expect(summary.total, 38);
    expect(summary.shoppingIds, unorderedEquals(['egg', 'milk', 'tomato']));
  });

  test('a day no dish can be afforded for stays empty', () {
    final plan = _plan(all, budget: 5, days: 2);
    expect(plan, [null, null]);
  });

  test('swapping one day keeps the others and picks a different dish', () {
    final base = _plan(all, days: 3);
    final swapped = _plan(all, days: 3, current: base, rebuild: {1});
    expect(swapped[0], base[0]);
    expect(swapped[2], base[2]);
    expect(swapped[1], isNot(base[1]));
    expect(swapped[1], isNotNull);
  });

  test('dishes needing an appliance the kitchen lacks are skipped', () {
    final oven = _r('oven_dish', ['rice'], appliances: {Appliance.oven});
    final plan = _plan([oven, _riceOnion], days: 2);
    expect(plan, isNot(contains('oven_dish')));
    final withOven = _plan(
      [oven],
      days: 1,
      appliances: {Appliance.stovetop, Appliance.oven},
    );
    expect(withOven, ['oven_dish']);
  });

  test('dishes with an ingredient the user avoids are never planned', () {
    final plan = _plan(all, days: 5, excludedIngredients: {'egg', 'onion'});
    for (final id in plan.whereType<String>()) {
      final recipe = all.firstWhere((r) => r.id == id);
      final ids = recipe.ingredients.map((i) => i.ingredientId).toSet();
      expect(ids.contains('egg') || ids.contains('onion'), isFalse);
    }
    expect(plan.whereType<String>(), isNotEmpty);
  });

  test('an avoided ingredient also rules out dishes that only list it as '
      'optional', () {
    final optional = Recipe(
      id: 'opt',
      titleHe: 'opt',
      ingredients: const [
        RecipeIngredient(ingredientId: 'rice'),
        RecipeIngredient(ingredientId: 'onion', optional: true),
      ],
      steps: const [RecipeStep(textHe: 'x')],
      totalMinutes: 10,
    );
    final plan = _plan([optional], days: 1, excludedIngredients: {'onion'});
    expect(plan, [null]);
  });

  test('only lunch and dinner dishes are planned', () {
    final cake = _r('cake', ['egg'], meal: 'dessert');
    final plan = _plan([cake, _riceOnion], days: 2);
    expect(plan, isNot(contains('cake')));
  });

  test('the same seed gives the same plan', () {
    expect(_plan(all, days: 4, seed: 7), _plan(all, days: 4, seed: 7));
  });

  test('the summary counts items without a known price', () {
    final odd = _r('odd', ['saffron', 'rice']);
    final summary = summarizePlan(
      ['odd'],
      [odd],
      pantryIds: const {'salt'},
      stapleIds: const {'salt'},
      store: _store,
    );
    expect(summary.total, 6);
    expect(summary.unpriced, 1);
    expect(summary.shoppingIds, ['saffron', 'rice']);
  });
}
