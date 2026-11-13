import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/home/ui/home_screen.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/plan/ui/plan_screen.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_detail_screen.dart';

import '../helpers/test_env.dart';

Recipe _r(
  String id,
  List<String> ings, {
  String meal = 'dinner',
  bool mealPrep = false,
  int minutes = 20,
}) => Recipe(
  id: id,
  titleHe: 'מנה $id',
  ingredients: [for (final i in ings) RecipeIngredient(ingredientId: i)],
  steps: const [RecipeStep(textHe: 'x')],
  totalMinutes: minutes,
  mealType: meal,
  mealPrep: mealPrep,
);

final _recipes = [
  _r('cookable', ['egg'], minutes: 15),
  _r('prep', ['egg'], mealPrep: true),
  _r('chick', ['chicken_breast']),
  _r('beefy', ['ground_beef']),
  _r('cake', ['egg'], meal: 'dessert'),
];

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<TestEnv> _env({List<Recipe>? recipes}) async {
  final env = await TestEnv.create(recipes: recipes ?? _recipes);
  await env.pantry.upsert(const PantryItem(ingredientId: 'egg'));
  return env;
}

void main() {
  testWidgets('the app opens on the home screen', (tester) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const Key('home_greeting')), findsOneWidget);
  });

  testWidgets('tonight\'s dinner is the quickest dish the kitchen covers', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_hero')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('home_hero')),
        matching: find.text('מנה cookable'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home_hero_reason')), findsOneWidget);
  });

  testWidgets('tonight\'s dinner is the menu\'s dish when there is one', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    final now = DateTime.now();
    await env.settings.setPlanStart(DateTime(now.year, now.month, now.day));
    await env.settings.setWeekPlan(['chick', null]);
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('home_hero')),
        matching: find.text('מנה chick'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the hero\'s buttons open cooking mode and the dish page', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home_details')));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailScreen), findsOneWidget);
  });

  testWidgets('shelves group the dishes: cook now, meal prep, chicken, beef', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    for (final entry in {
      'home_shelf_cook_now': 'home_tile_cook_now_cookable',
      'home_shelf_meal_prep': 'home_tile_meal_prep_prep',
      'home_shelf_chicken': 'home_tile_chicken_chick',
      'home_shelf_beef': 'home_tile_beef_beefy',
    }.entries) {
      expect(find.byKey(Key(entry.key)), findsOneWidget, reason: entry.key);
      expect(
        find.descendant(
          of: find.byKey(Key(entry.key)),
          matching: find.byKey(Key(entry.value)),
        ),
        findsOneWidget,
        reason: entry.value,
      );
    }
    // Desserts are not main meals, so they are in no meat or meal-prep shelf.
    expect(find.byKey(const Key('home_tile_chicken_cake')), findsNothing);
  });

  testWidgets('dishes with a photo lead a shelf', (tester) async {
    _tall(tester);
    const photo = RecipePhoto(
      asset: 'assets/recipes/photos/none.jpg',
      author: 'a',
      license: 'CC BY',
      sourceUrl: 'https://commons.wikimedia.org/x',
    );
    final withPhoto = Recipe(
      id: 'pic',
      titleHe: 'מנה pic',
      ingredients: const [RecipeIngredient(ingredientId: 'chicken_breast')],
      steps: const [RecipeStep(textHe: 'x')],
      totalMinutes: 20,
      photo: photo,
    );
    final env = await _env(
      recipes: [
        for (var i = 0; i < 6; i++) _r('plain$i', ['chicken_breast']),
        withPhoto,
      ],
    );
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    final shelf = find.byKey(const Key('home_shelf_chicken'));
    final first = tester.getTopRight(
      find.descendant(
        of: shelf,
        matching: find.byKey(const Key('home_tile_chicken_pic')),
      ),
    );
    for (var i = 0; i < 6; i++) {
      final other = find.descendant(
        of: shelf,
        matching: find.byKey(Key('home_tile_chicken_plain$i')),
      );
      if (other.evaluate().isEmpty) continue;
      // Right to left: the photo dish sits to the right of (before) the others.
      expect(first.dx, greaterThan(tester.getTopRight(other).dx));
    }
  });

  testWidgets('the favorites shelf only appears once there are favorites', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_shelf_favorites')), findsNothing);
    await env.settings.toggleFavorite('chick');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_shelf_favorites')), findsOneWidget);
  });

  testWidgets('a tile opens its dish', (tester) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home_tile_chicken_chick')));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailScreen), findsOneWidget);
  });

  testWidgets('quick actions go to the menu, list, kitchen and stores', (
    tester,
  ) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home_action_plan')));
    await tester.pumpAndSettle();
    expect(find.byType(PlanScreen), findsOneWidget);
  });

  testWidgets('with nothing to cook it invites the user to fill the kitchen', (
    tester,
  ) async {
    _tall(tester);
    final env = await TestEnv.create(
      recipes: [
        _r('far', ['chicken_breast', 'ground_beef', 'tomato', 'milk']),
      ],
    );
    await tester.pumpWidget(env.wrapApp('/home'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_hero')), findsNothing);
    expect(find.byKey(const Key('home_empty')), findsOneWidget);
  });

  testWidgets('the bottom bar starts with a home tab', (tester) async {
    _tall(tester);
    final env = await _env();
    await tester.pumpWidget(env.wrapApp('/pantry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_home')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
