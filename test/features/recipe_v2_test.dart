import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

Map<String, dynamic> _base() => {
  'id': 'rv2_x',
  'titleHe': 'שקשוקה',
  'ingredients': [
    {'ingredientId': 'egg', 'quantity': 4, 'unit': 'unit'},
  ],
  'steps': [
    {'textHe': 'מחממים'},
  ],
  'totalMinutes': 25,
};

void main() {
  test('Recipe v2 round-trips through JSON with a photo', () {
    const r = Recipe(
      id: 'rv2_x',
      titleHe: 'שקשוקה',
      titleEn: 'Shakshuka',
      ingredients: [
        RecipeIngredient(ingredientId: 'egg', quantity: 4, unit: 'unit'),
      ],
      steps: [RecipeStep(textHe: 'מחממים')],
      appliances: {Appliance.stovetop},
      totalMinutes: 25,
      servings: 3,
      difficulty: 'medium',
      mealType: 'breakfast',
      photo: RecipePhoto(
        asset: 'assets/recipes/photos/rv2_x.jpg',
        author: 'Jane Doe',
        license: 'CC BY-SA 4.0',
        sourceUrl: 'https://commons.wikimedia.org/wiki/File:Shakshuka.jpg',
      ),
    );
    final back = Recipe.fromJson(r.toJson());
    expect(back, r);
    expect(back.servings, 3);
    expect(back.difficulty, 'medium');
    expect(back.mealType, 'breakfast');
    expect(back.photo?.author, 'Jane Doe');
  });

  test('old recipes without the new fields parse with defaults', () {
    final r = Recipe.fromJson(_base());
    expect(r.servings, 2);
    expect(r.difficulty, 'easy');
    expect(r.mealType, 'dinner');
    expect(r.photo, isNull);
  });

  test('unknown difficulty or meal type falls back to the defaults', () {
    final r = Recipe.fromJson({
      ..._base(),
      'difficulty': 'impossible',
      'mealType': 'elevenses',
    });
    expect(r.difficulty, 'easy');
    expect(r.mealType, 'dinner');
  });

  test('every documented meal type and difficulty is accepted', () {
    for (final m in kMealTypes) {
      expect(Recipe.fromJson({..._base(), 'mealType': m}).mealType, m);
    }
    for (final d in kDifficulties) {
      expect(Recipe.fromJson({..._base(), 'difficulty': d}).difficulty, d);
    }
  });

  test('RecipePhoto equality and JSON round trip', () {
    const a = RecipePhoto(
      asset: 'a.jpg',
      author: 'x',
      license: 'CC0',
      sourceUrl: 'https://example.org',
    );
    expect(RecipePhoto.fromJson(a.toJson()), a);
    expect(
      a ==
          const RecipePhoto(
            asset: 'b.jpg',
            author: 'x',
            license: 'CC0',
            sourceUrl: 'https://example.org',
          ),
      isFalse,
    );
  });

  test('recipes with different servings are not equal', () {
    final a = Recipe.fromJson(_base());
    final b = Recipe.fromJson({..._base(), 'servings': 4});
    expect(a == b, isFalse);
  });
}
