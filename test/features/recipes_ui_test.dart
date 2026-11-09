import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_card.dart';

import '../helpers/test_env.dart';

const _cookable = Recipe(
  id: 'cookable',
  titleHe: 'ביצה מבושלת',
  ingredients: [RecipeIngredient(ingredientId: 'egg')],
  steps: [
    RecipeStep(textHe: 'מרתיחים מים', timerSeconds: 60),
    RecipeStep(textHe: 'מכניסים ביצה'),
  ],
  totalMinutes: 10,
);

const _almost = Recipe(
  id: 'almost',
  titleHe: 'חביתה עשירה',
  ingredients: [
    RecipeIngredient(ingredientId: 'egg'),
    RecipeIngredient(ingredientId: 'milk'),
    RecipeIngredient(ingredientId: 'tomato'),
  ],
  steps: [RecipeStep(textHe: 'טורפים ומטגנים')],
  totalMinutes: 15,
);

void main() {
  Future<TestEnv> setUpEnv() async {
    final env = await TestEnv.create(recipes: [_cookable, _almost]);
    await env.pantry.upsert(const PantryItem(ingredientId: 'egg'));
    return env;
  }

  testWidgets('suggestions shows cook now and almost there tabs from pantry state', (tester) async {
    final env = await setUpEnv();
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_cookable')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_almost')), findsNothing);

    await tester.tap(find.byKey(const Key('tab_almost_there')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe_card_almost')), findsOneWidget);
    expect(find.byKey(const Key('recipe_card_cookable')), findsNothing);
  });

  testWidgets('almost there card shows missing count and detail lists missing ingredients', (tester) async {
    final env = await setUpEnv();
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_almost_there')));
    await tester.pumpAndSettle();
    expect(find.text('חסרים 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('recipe_card_almost')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('missing_milk')), findsOneWidget);
    expect(find.byKey(const Key('missing_tomato')), findsOneWidget);
    expect(find.byKey(const Key('missing_egg')), findsNothing);
  });

  testWidgets('add missing to shopping list button adds items and skips duplicates', (tester) async {
    final env = await setUpEnv();
    await tester.pumpWidget(env.wrapApp('/recipe/almost'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('add_missing_button')));
    await tester.tap(find.byKey(const Key('add_missing_button')));
    await tester.pumpAndSettle();
    expect(env.shopping.items.map((e) => e.ingredientId).toSet(), {'milk', 'tomato'});
    expect(env.shopping.items.length, 2);

    await tester.tap(find.byKey(const Key('add_missing_button')));
    await tester.pumpAndSettle();
    expect(env.shopping.items.length, 2);
  });

  testWidgets('cooking mode steps forward and back and shows a step timer when timerSeconds is set',
      (tester) async {
    final env = await setUpEnv();
    await tester.pumpWidget(env.wrapApp('/cook/cookable'));
    await tester.pumpAndSettle();
    expect(find.text('מרתיחים מים'), findsOneWidget);
    expect(find.byKey(const Key('step_timer')), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('next_step_button')));
    await tester.pumpAndSettle();
    expect(find.text('מכניסים ביצה'), findsOneWidget);
    expect(find.byKey(const Key('step_timer')), findsNothing);

    await tester.tap(find.byKey(const Key('prev_step_button')));
    await tester.pumpAndSettle();
    expect(find.text('מרתיחים מים'), findsOneWidget);
  });

  testWidgets('RecipeCard with a 120 character Hebrew title at 320 dp width does not overflow',
      (tester) async {
    final env = await TestEnv.create();
    final longTitle = List.filled(24, 'מתכון').join(' ');
    expect(longTitle.length, greaterThanOrEqualTo(120));
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(env.wrap(Scaffold(
      body: SizedBox(
        width: 320,
        child: RecipeCard(
          recipe: Recipe(
            id: 'long',
            titleHe: longTitle,
            ingredients: const [RecipeIngredient(ingredientId: 'egg')],
            steps: const [RecipeStep(textHe: 'x')],
            totalMinutes: 90,
          ),
          missingCount: 3,
        ),
      ),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('timer counts down from the first step when Start is pressed', (tester) async {
    final env = await setUpEnv();
    await tester.pumpWidget(env.wrapApp('/cook/cookable'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timer_toggle')));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('00:57'), findsOneWidget);

    await tester.tap(find.byKey(const Key('timer_toggle')));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:57'), findsOneWidget);
  });

  testWidgets('finished timer shows a done state instead of resetting', (tester) async {
    final env = await TestEnv.create(recipes: const [
      Recipe(
        id: 'quick',
        titleHe: 'מהיר',
        ingredients: [RecipeIngredient(ingredientId: 'egg')],
        steps: [RecipeStep(textHe: 'ממתינים', timerSeconds: 2)],
        totalMinutes: 5,
      ),
    ]);
    await tester.pumpWidget(env.wrapApp('/cook/quick'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timer_toggle')));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('00:00'), findsOneWidget);
    expect(find.byKey(const Key('timer_done')), findsOneWidget);

    await tester.tap(find.byKey(const Key('timer_toggle')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);
    expect(find.byKey(const Key('timer_done')), findsNothing);
  });
}
