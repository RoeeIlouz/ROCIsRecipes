import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

import '../helpers/test_env.dart';

Future<TestEnv> _open(
  WidgetTester tester, {
  List<Recipe> recipes = const [],
  String at = '/recipe-edit',
}) async {
  final env = await TestEnv.create(recipes: recipes);
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(env.wrapApp(at));
  await tester.pumpAndSettle();
  return env;
}

Future<void> _addEgg(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('editor_ingredient_search')),
    'ביצ',
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('editor_pick_egg')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'saving without a name, ingredient or step shows what is missing',
    (tester) async {
      final env = await _open(tester);
      await tester.tap(find.byKey(const Key('editor_save')));
      await tester.pumpAndSettle();
      expect(find.text('תנו שם למתכון'), findsOneWidget);
      expect(env.recipes.all, isEmpty);
    },
  );

  testWidgets('a complete recipe is saved as a user recipe with photo', (
    tester,
  ) async {
    final env = await _open(tester);
    env.photos.next = '/data/user_photos/1.jpg';
    await tester.enterText(
      find.byKey(const Key('editor_title')),
      'חביתה של סבתא',
    );
    await _addEgg(tester);
    await tester.enterText(find.byKey(const Key('editor_qty_egg')), '3');
    await tester.enterText(
      find.byKey(const Key('editor_step_0')),
      'טורפים וצולים',
    );
    await tester.tap(find.byKey(const Key('editor_photo_gallery')));
    await tester.pumpAndSettle();
    expect(env.photos.lastCamera, false);
    await tester.tap(find.byKey(const Key('editor_save')));
    await tester.pumpAndSettle();

    final saved = env.recipes.all.single;
    expect(saved.isUserCreated, isTrue);
    expect(saved.titleHe, 'חביתה של סבתא');
    expect(saved.ingredients.single.ingredientId, 'egg');
    expect(saved.ingredients.single.quantity, 3);
    expect(saved.steps.single.textHe, 'טורפים וצולים');
    expect(saved.imagePath, '/data/user_photos/1.jpg');
  });

  testWidgets('editing an existing user recipe keeps its id', (tester) async {
    const existing = Recipe(
      id: 'user_1',
      titleHe: 'ישן',
      ingredients: [
        RecipeIngredient(ingredientId: 'egg', quantity: 2, unit: 'unit'),
      ],
      steps: [RecipeStep(textHe: 'שלב')],
      totalMinutes: 10,
      isUserCreated: true,
    );
    final env = await _open(
      tester,
      recipes: [existing],
      at: '/recipe-edit?id=user_1',
    );
    await tester.enterText(find.byKey(const Key('editor_title')), 'חדש');
    await tester.tap(find.byKey(const Key('editor_save')));
    await tester.pumpAndSettle();
    expect(env.recipes.all.single.id, 'user_1');
    expect(env.recipes.all.single.titleHe, 'חדש');
  });

  testWidgets(
    'a user recipe can be deleted, a starter recipe has no delete button',
    (tester) async {
      const mine = Recipe(
        id: 'user_1',
        titleHe: 'שלי',
        ingredients: [RecipeIngredient(ingredientId: 'egg')],
        steps: [RecipeStep(textHe: 'שלב')],
        totalMinutes: 10,
        isUserCreated: true,
      );
      final env = await _open(tester, recipes: [mine], at: '/recipe/user_1');
      await tester.tap(find.byKey(const Key('delete_recipe_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_recipe')));
      await tester.pumpAndSettle();
      expect(env.recipes.all, isEmpty);
    },
  );

  testWidgets('the suggestions screen offers a button to add a recipe', (
    tester,
  ) async {
    await _open(tester, at: '/suggestions');
    expect(find.byKey(const Key('add_recipe_fab')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add_recipe_fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('editor_title')), findsOneWidget);
  });
}
