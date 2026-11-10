import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/catalog/ingredient.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/starter_recipe_loader.dart';

import '../helpers/test_env.dart';

final _catalog = IngredientCatalog(const [
  Ingredient(id: 'egg', nameHe: 'ביצה', nameEn: 'Egg', category: 'dairy'),
  Ingredient(id: 'salt', nameHe: 'מלח', nameEn: 'Salt', isStaple: true, category: 'pantry'),
]);

List<RecipeStep> _steps(int n) => [for (var i = 0; i < n; i++) RecipeStep(textHe: 'שלב ${i + 1}')];

Recipe _recipe({
  String id = 'rv2_ok',
  int steps = 6,
  int servings = 2,
  List<RecipeIngredient>? ingredients,
  RecipePhoto? photo,
}) =>
    Recipe(
      id: id,
      titleHe: 'מתכון',
      ingredients: ingredients ??
          const [
            RecipeIngredient(ingredientId: 'egg', quantity: 4, unit: 'unit'),
            RecipeIngredient(ingredientId: 'salt'),
          ],
      steps: _steps(steps),
      totalMinutes: 20,
      servings: servings,
      photo: photo,
    );

const _photo = RecipePhoto(asset: 'a/b.jpg', author: 'x', license: 'CC0', sourceUrl: 'https://example.org');

void main() {
  group('strict validation', () {
    test('a complete recipe passes', () {
      expect(StarterRecipeLoader.validate([_recipe()], _catalog, strict: true), isEmpty);
    });

    test('fewer than 6 steps is reported', () {
      final problems = StarterRecipeLoader.validate([_recipe(steps: 5)], _catalog, strict: true);
      expect(problems.single, allOf(contains('rv2_ok'), contains('5 steps')));
    });

    test('servings outside 1 to 8 is reported', () {
      expect(StarterRecipeLoader.validate([_recipe(servings: 0)], _catalog, strict: true), isNotEmpty);
      expect(StarterRecipeLoader.validate([_recipe(servings: 9)], _catalog, strict: true), isNotEmpty);
    });

    test('a non-staple ingredient without quantity or unit is reported', () {
      final problems = StarterRecipeLoader.validate(
        [_recipe(ingredients: const [RecipeIngredient(ingredientId: 'egg')])],
        _catalog,
        strict: true,
      );
      expect(problems.single, allOf(contains('egg'), contains('quantity')));
    });

    test('staples and optional ingredients may omit quantities', () {
      final problems = StarterRecipeLoader.validate(
        [
          _recipe(ingredients: const [
            RecipeIngredient(ingredientId: 'egg', quantity: 2, unit: 'unit'),
            RecipeIngredient(ingredientId: 'salt'),
          ])
        ],
        _catalog,
        strict: true,
      );
      expect(problems, isEmpty);
    });

    test('non-strict validation ignores these rules', () {
      expect(StarterRecipeLoader.validate([_recipe(steps: 1, servings: 0)], _catalog), isEmpty);
    });
  });

  group('photo validation', () {
    test('a missing photo is reported only when photos are required', () {
      expect(StarterRecipeLoader.validate([_recipe()], _catalog), isEmpty);
      final problems = StarterRecipeLoader.validate([_recipe()], _catalog, requirePhoto: true);
      expect(problems.single, allOf(contains('rv2_ok'), contains('photo')));
    });

    test('recipes on the allow list may have no photo', () {
      expect(
        StarterRecipeLoader.validate([_recipe()], _catalog, requirePhoto: true, noPhotoAllowed: {'rv2_ok'}),
        isEmpty,
      );
    });

    test('a photo whose asset file is missing is reported', () {
      final problems = StarterRecipeLoader.validate(
        [_recipe(photo: _photo)],
        _catalog,
        requirePhoto: true,
        assetExists: (_) => false,
      );
      expect(problems.single, allOf(contains('rv2_ok'), contains('a/b.jpg')));
    });

    test('a photo with an existing asset passes', () {
      expect(
        StarterRecipeLoader.validate([_recipe(photo: _photo)], _catalog,
            requirePhoto: true, assetExists: (_) => true),
        isEmpty,
      );
    });
  });

  group('retireStarter', () {
    test('removes old starter recipes and keeps user recipes (Review Focus 2)', () async {
      final env = await TestEnv.create();
      await env.recipes.upsert(_recipe(id: 'old_starter'));
      await env.recipes.upsert(_recipe(id: 'new_starter'));
      await env.recipes.upsert(Recipe(
        id: 'mine',
        titleHe: 'שלי',
        ingredients: const [RecipeIngredient(ingredientId: 'egg')],
        steps: _steps(1),
        totalMinutes: 5,
        isUserCreated: true,
      ));
      await env.recipes.retireStarter({'new_starter'});
      expect(env.recipes.all.map((r) => r.id).toSet(), {'new_starter', 'mine'});
    });

    test('keeps a user recipe even when its id is not in the keep list', () async {
      final env = await TestEnv.create();
      await env.recipes.upsert(Recipe(
        id: 'mine',
        titleHe: 'שלי',
        ingredients: const [RecipeIngredient(ingredientId: 'egg')],
        steps: _steps(1),
        totalMinutes: 5,
        isUserCreated: true,
      ));
      await env.recipes.retireStarter(<String>{});
      expect(env.recipes.byId('mine'), isNotNull);
    });
  });
}
