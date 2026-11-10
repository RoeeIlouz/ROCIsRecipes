import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_card.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_format.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

import '../helpers/test_env.dart';

const _credit = RecipePhoto(
  asset: 'assets/recipes/photos/does_not_exist.jpg',
  author: 'Jane Doe',
  license: 'CC BY-SA 4.0',
  sourceUrl: 'https://commons.wikimedia.org/wiki/File:Dish.jpg',
);

Recipe _recipe(
  String id, {
  String mealType = 'dinner',
  RecipePhoto? photo,
  List<RecipeIngredient>? ingredients,
}) => Recipe(
  id: id,
  titleHe: 'מתכון $id',
  ingredients:
      ingredients ??
      const [RecipeIngredient(ingredientId: 'egg', quantity: 4, unit: 'unit')],
  steps: const [RecipeStep(textHe: 'שלב')],
  totalMinutes: 20,
  servings: 2,
  difficulty: 'easy',
  mealType: mealType,
  photo: photo,
);

void main() {
  group('amount and unit formatting', () {
    test('formatAmount uses fraction glyphs and trims trailing zeros', () {
      expect(formatAmount(0.5), '½');
      expect(formatAmount(1.5), '1½');
      expect(formatAmount(2), '2');
      expect(formatAmount(0.25), '¼');
      expect(formatAmount(0.75), '¾');
      expect(formatAmount(0.33), '⅓');
      expect(formatAmount(2.5), '2½');
      expect(formatAmount(3.7), '3.7');
      expect(formatAmount(1000), '1000');
    });

    test('Hebrew units agree in number', () async {
      final he = await AppLocalizations.delegate.load(const Locale('he'));
      expect(unitLabel(he, 'tbsp', 1), 'כף');
      expect(unitLabel(he, 'tbsp', 2), 'כפות');
      expect(unitLabel(he, 'clove', 3), 'שיניים');
      expect(unitLabel(he, 'g', 100), 'גרם');
      expect(unitLabel(he, 'unit', 4), "יח'");
      expect(unitLabel(he, 'mystery', 2), 'mystery');
    });

    test('English units agree in number', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(unitLabel(en, 'cup', 1), 'cup');
      expect(unitLabel(en, 'cup', 2), 'cups');
      expect(unitLabel(en, 'tbsp', 2), 'tbsp');
    });

    test(
      'formatIngredientAmount combines amount and unit (fractions stay singular)',
      () async {
        final he = await AppLocalizations.delegate.load(const Locale('he'));
        String f(double? q, String? u) => formatIngredientAmount(
          he,
          RecipeIngredient(ingredientId: 'x', quantity: q, unit: u),
        );
        expect(f(4, 'unit'), "4 יח'");
        expect(f(0.5, 'cup'), '½ כוס');
        expect(f(1.5, 'cup'), '1½ כוסות');
        expect(f(1, 'pinch'), '1 קורט');
        expect(f(null, null), '');
        expect(f(2, null), '2');
      },
    );
  });

  group('photos', () {
    testWidgets('a recipe without a photo shows the placeholder', (
      tester,
    ) async {
      final env = await TestEnv.create();
      await tester.pumpWidget(
        env.wrap(
          Scaffold(body: RecipeCard(recipe: _recipe('a'), missingCount: 0)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photo_placeholder')), findsOneWidget);
    });

    testWidgets(
      'a photo whose asset cannot be loaded falls back to the placeholder',
      (tester) async {
        final env = await TestEnv.create();
        await tester.pumpWidget(
          env.wrap(
            Scaffold(
              body: RecipeCard(
                recipe: _recipe('a', photo: _credit),
                missingCount: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('photo_placeholder')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('recipe detail', () {
    Future<TestEnv> openDetail(WidgetTester tester, Recipe recipe) async {
      final env = await TestEnv.create(recipes: [recipe]);
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(env.wrapApp('/recipe/${recipe.id}'));
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets(
      'shows servings, difficulty, meal type and ingredient quantities',
      (tester) async {
        await openDetail(tester, _recipe('a'));
        expect(find.text('2 מנות'), findsOneWidget);
        expect(find.text('קל'), findsOneWidget);
        expect(find.text('ערב'), findsOneWidget);
        expect(find.text("4 יח'"), findsOneWidget);
      },
    );

    testWidgets(
      'the credit line shows author and license and opens the source page',
      (tester) async {
        final env = await openDetail(tester, _recipe('a', photo: _credit));
        expect(find.text('צילום: Jane Doe, CC BY-SA 4.0'), findsOneWidget);
        await tester.tap(find.byKey(const Key('photo_credit')));
        await tester.pumpAndSettle();
        expect(env.launched.single, Uri.parse(_credit.sourceUrl));
      },
    );

    testWidgets('no credit line without a photo', (tester) async {
      await openDetail(tester, _recipe('a'));
      expect(find.byKey(const Key('photo_credit')), findsNothing);
    });
  });

  group('meal type filter', () {
    testWidgets('a meal chip filters both tabs and All restores the list', (
      tester,
    ) async {
      final env = await TestEnv.create(
        recipes: [
          _recipe('b1', mealType: 'breakfast'),
          _recipe('d1'),
        ],
      );
      await env.pantry.upsert(const PantryItem(ingredientId: 'egg'));
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(env.wrapApp('/suggestions'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recipe_card_b1')), findsOneWidget);
      expect(find.byKey(const Key('recipe_card_d1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('meal_chip_breakfast')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recipe_card_b1')), findsOneWidget);
      expect(find.byKey(const Key('recipe_card_d1')), findsNothing);

      await tester.tap(find.byKey(const Key('meal_chip_all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recipe_card_d1')), findsOneWidget);
    });
  });

  group('credits screen', () {
    testWidgets(
      'lists only recipes that have a photo credit and opens the source',
      (tester) async {
        final env = await TestEnv.create(
          recipes: [
            _recipe('with', photo: _credit),
            _recipe('without'),
          ],
        );
        await tester.pumpWidget(env.wrapApp('/credits'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('credit_with')), findsOneWidget);
        expect(find.byKey(const Key('credit_without')), findsNothing);
        await tester.tap(find.byKey(const Key('credit_with')));
        await tester.pumpAndSettle();
        expect(env.launched.single, Uri.parse(_credit.sourceUrl));
      },
    );

    testWidgets('an empty credits list says so', (tester) async {
      final env = await TestEnv.create(recipes: [_recipe('without')]);
      await tester.pumpWidget(env.wrapApp('/credits'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('credits_empty')), findsOneWidget);
    });
  });
}
