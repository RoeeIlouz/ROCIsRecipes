import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/catalog/ingredient.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/starter_recipe_loader.dart';

final _hebrew = RegExp('[֐-׿]');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(List<Recipe>, IngredientCatalog)> loadReal() async {
    final catalog = IngredientCatalog.fromJson(
      await rootBundle.loadString('assets/data/ingredients.json'),
    );
    final recipes = StarterRecipeLoader.parse(
      await rootBundle.loadString('assets/recipes/starter_he.json'),
    );
    return (recipes, catalog);
  }

  test(
    'every starter recipe passes validation against the real catalog',
    () async {
      final (recipes, catalog) = await loadReal();
      expect(
        StarterRecipeLoader.validate(recipes, catalog, strict: true),
        isEmpty,
      );
    },
  );

  test('starter collection has a sensible number of recipes', () async {
    final (recipes, _) = await loadReal();
    expect(recipes.length, inInclusiveRange(100, 400));
  });

  test('at least 90 percent have Hebrew titles', () async {
    final (recipes, _) = await loadReal();
    final hebrew = recipes.where((r) => _hebrew.hasMatch(r.titleHe)).length;
    expect(hebrew / recipes.length, greaterThanOrEqualTo(0.9));
  });

  test(
    'collection includes no-appliance recipes and every appliance kind is used or optional',
    () async {
      final (recipes, _) = await loadReal();
      expect(
        recipes.where((r) => r.appliances.isEmpty).length,
        greaterThanOrEqualTo(1),
      );
    },
  );

  test('validate reports an unknown ingredient id', () {
    final catalog = IngredientCatalog(const [
      Ingredient(id: 'egg', nameHe: 'ביצה', nameEn: 'Egg'),
    ]);
    const bad = Recipe(
      id: 'bad1',
      titleHe: 'x',
      ingredients: [RecipeIngredient(ingredientId: 'nope')],
      steps: [RecipeStep(textHe: 'a')],
      totalMinutes: 5,
    );
    final problems = StarterRecipeLoader.validate([bad], catalog);
    expect(problems.length, 1);
    expect(problems.single, allOf(contains('bad1'), contains('nope')));
  });

  test('validate rejects totalMinutes <= 0, no steps and duplicate ids', () {
    final catalog = IngredientCatalog(const [
      Ingredient(id: 'egg', nameHe: 'ביצה', nameEn: 'Egg'),
    ]);
    const zero = Recipe(
      id: 'z',
      titleHe: 'x',
      ingredients: [RecipeIngredient(ingredientId: 'egg')],
      steps: [RecipeStep(textHe: 'a')],
      totalMinutes: 0,
    );
    const noSteps = Recipe(
      id: 'n',
      titleHe: 'x',
      ingredients: [RecipeIngredient(ingredientId: 'egg')],
      steps: [],
      totalMinutes: 5,
    );
    final problems = StarterRecipeLoader.validate([
      zero,
      noSteps,
      noSteps,
    ], catalog);
    expect(
      problems.where((p) => p.contains('z')).length,
      greaterThanOrEqualTo(1),
    );
    expect(
      problems.where((p) => p.contains('steps')).length,
      greaterThanOrEqualTo(1),
    );
    expect(problems.where((p) => p.contains('duplicate')).length, 1);
  });
}
