import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_matcher.dart';

Recipe _r(
  String id,
  List<String> required, {
  List<String> optional = const [],
  Set<Appliance> appliances = const {},
  int minutes = 10,
}) =>
    Recipe(
      id: id,
      titleHe: id,
      ingredients: [
        for (final i in required) RecipeIngredient(ingredientId: i),
        for (final i in optional) RecipeIngredient(ingredientId: i, optional: true),
      ],
      steps: const [RecipeStep(textHe: 'x')],
      appliances: appliances,
      totalMinutes: minutes,
    );

List<String> _ids(List<RecipeMatch> m) => m.map((e) => e.recipe.id).toList();

List<RecipeMatch> _match(
  List<Recipe> recipes, {
  Set<String> pantry = const {},
  Set<String> staples = const {},
  Set<Appliance> appliances = const {Appliance.stovetop, Appliance.oven},
  int maxMinutes = 60,
  MatchMode mode = MatchMode.cookNow,
  int maxMissing = 3,
}) =>
    RecipeMatcher.match(
      recipes: recipes,
      pantryIds: pantry,
      stapleIds: staples,
      appliances: appliances,
      maxMinutes: maxMinutes,
      mode: mode,
      maxMissing: maxMissing,
    );

void main() {
  test('cookNow returns only fully covered recipes', () {
    final recipes = [_r('a', ['egg', 'milk']), _r('b', ['egg', 'flour'])];
    expect(_ids(_match(recipes, pantry: {'egg', 'milk'})), ['a']);
  });

  test('staples count as available', () {
    final recipes = [_r('a', ['egg', 'salt'])];
    expect(_ids(_match(recipes, pantry: {'egg'}, staples: {'salt'})), ['a']);
  });

  test('optional ingredients never count as missing', () {
    final recipes = [_r('a', ['egg'], optional: ['parsley'])];
    final m = _match(recipes, pantry: {'egg'});
    expect(_ids(m), ['a']);
    expect(m.single.missingIngredientIds, isEmpty);
  });

  test('almostThere returns 1 to 3 missing sorted by fewest missing then time', () {
    final recipes = [
      _r('one_slow', ['a', 'b'], minutes: 30),
      _r('one_fast', ['a', 'c'], minutes: 10),
      _r('three', ['a', 'x', 'y', 'z']),
      _r('four', ['a', 'p', 'q', 'r', 's']),
      _r('none', ['a']),
    ];
    final m = _match(recipes, pantry: {'a'}, mode: MatchMode.almostThere);
    expect(_ids(m), ['one_fast', 'one_slow', 'three']);
    expect(m.last.missingIngredientIds, ['x', 'y', 'z']);
  });

  test('recipe over the time limit is excluded', () {
    final recipes = [_r('slow', ['egg'], minutes: 90), _r('fast', ['egg'], minutes: 20)];
    expect(_ids(_match(recipes, pantry: {'egg'}, maxMinutes: 30)), ['fast']);
  });

  test('recipe needing an unowned appliance is excluded', () {
    final recipes = [
      _r('micro', ['egg'], appliances: {Appliance.microwave}),
      _r('stove', ['egg'], appliances: {Appliance.stovetop}),
    ];
    expect(_ids(_match(recipes, pantry: {'egg'})), ['stove']);
  });

  test('no appliances selected keeps only no-appliance recipes', () {
    final recipes = [
      _r('stove', ['egg'], appliances: {Appliance.stovetop}),
      _r('cold', ['egg']),
    ];
    expect(_ids(_match(recipes, pantry: {'egg'}, appliances: const {})), ['cold']);
  });

  test('empty pantry: cookNow is empty and almostThere only has recipes within maxMissing', () {
    final recipes = [_r('two', ['a', 'b']), _r('five', ['a', 'b', 'c', 'd', 'e'])];
    expect(_match(recipes), isEmpty);
    expect(_ids(_match(recipes, mode: MatchMode.almostThere)), ['two']);
    expect(_ids(_match(recipes, mode: MatchMode.almostThere, maxMissing: 5)), ['two', 'five']);
  });

  test('unknown ingredient id counts as missing and does not throw', () {
    final recipes = [_r('a', ['egg', 'ghost_ingredient'])];
    final m = _match(recipes, pantry: {'egg'}, mode: MatchMode.almostThere);
    expect(m.single.missingIngredientIds, ['ghost_ingredient']);
  });
}
