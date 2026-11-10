import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/starter_recipe_loader.dart';
import 'package:rocis_recipes/features/recipes/ui/cooking_mode_screen.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';

import '../helpers/test_env.dart';

Recipe _recipe(
  String id,
  String title, {
  bool user = false,
  int minutes = 10,
}) => Recipe(
  id: id,
  titleHe: title,
  ingredients: const [RecipeIngredient(ingredientId: 'egg')],
  steps: const [RecipeStep(textHe: 'x')],
  totalMinutes: minutes,
  isUserCreated: user,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shopping dedupe', () {
    test(
      'addIfNew skips an unchecked item with the same ingredient id',
      () async {
        final env = await TestEnv.create();
        expect(
          await env.shopping.addIfNew(
            const ShoppingItem(id: 'a', ingredientId: 'egg', label: 'ביצה'),
          ),
          isTrue,
        );
        expect(
          await env.shopping.addIfNew(
            const ShoppingItem(id: 'b', ingredientId: 'egg', label: 'ביצים'),
          ),
          isFalse,
        );
        expect(env.shopping.items.length, 1);
      },
    );

    test(
      'addIfNew skips custom items with the same normalized label',
      () async {
        final env = await TestEnv.create();
        await env.shopping.addIfNew(
          const ShoppingItem(id: 'a', label: 'שוקולד'),
        );
        expect(
          await env.shopping.addIfNew(
            const ShoppingItem(id: 'b', label: '  שוקולד '),
          ),
          isFalse,
        );
        expect(
          await env.shopping.addIfNew(
            const ShoppingItem(id: 'c', label: 'Chocolate'),
          ),
          isTrue,
        );
        expect(env.shopping.items.length, 2);
      },
    );

    test('addIfNew allows re-adding an item that is already checked', () async {
      final env = await TestEnv.create();
      await env.shopping.add(
        const ShoppingItem(
          id: 'a',
          ingredientId: 'egg',
          label: 'ביצה',
          checked: true,
        ),
      );
      expect(
        await env.shopping.addIfNew(
          const ShoppingItem(id: 'b', ingredientId: 'egg', label: 'ביצה'),
        ),
        isTrue,
      );
    });
  });

  group('starter recipe JSON validation', () {
    test('real asset has no unknown appliance names', () async {
      final json = await rootBundle.loadString(
        'assets/recipes/starter_he.json',
      );
      expect(StarterRecipeLoader.validateJson(json), isEmpty);
    });

    test('validateJson reports an unknown appliance name', () {
      const json =
          '[{"id":"bad","titleHe":"x","ingredients":[{"ingredientId":"egg"}],'
          '"steps":[{"textHe":"a"}],"appliances":["stovetopp"],"totalMinutes":5}]';
      final problems = StarterRecipeLoader.validateJson(json);
      expect(problems.length, 1);
      expect(problems.single, allOf(contains('bad'), contains('stovetopp')));
    });
  });

  group('starter recipe sync', () {
    test(
      'syncStarter adds new, updates starter recipes and keeps user recipes',
      () async {
        final env = await TestEnv.create();
        await env.recipes.upsert(_recipe('s1', 'ישן'));
        await env.recipes.upsert(_recipe('mine', 'שלי', user: true));
        await env.recipes.syncStarter([
          _recipe('s1', 'חדש'),
          _recipe('s2', 'נוסף'),
        ]);
        final byId = {for (final r in env.recipes.all) r.id: r};
        expect(byId['s1']!.titleHe, 'חדש');
        expect(byId['s2'], isNotNull);
        expect(byId['mine']!.titleHe, 'שלי');
      },
    );

    test(
      'syncStarter never overwrites a user recipe with the same id',
      () async {
        final env = await TestEnv.create();
        await env.recipes.upsert(_recipe('s1', 'שלי', user: true));
        await env.recipes.syncStarter([_recipe('s1', 'מערכת')]);
        expect(env.recipes.byId('s1')!.titleHe, 'שלי');
      },
    );

    test('settings starterVersion defaults to 0 and persists', () async {
      final env = await TestEnv.create();
      expect(env.settings.starterVersion, 0);
      await env.settings.setStarterVersion(2);
      expect(env.settings.starterVersion, 2);
    });
  });

  group('recipe detail layout', () {
    testWidgets(
      'action buttons do not overflow at 320 dp with English labels',
      (tester) async {
        final env = await TestEnv.create(
          recipes: [
            Recipe(
              id: 'r',
              titleHe: 'מתכון',
              ingredients: const [
                RecipeIngredient(ingredientId: 'egg'),
                RecipeIngredient(ingredientId: 'milk'),
              ],
              steps: const [RecipeStep(textHe: 'x')],
              totalMinutes: 10,
            ),
          ],
        );
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          env.wrapApp('/recipe/r', locale: const Locale('en')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('timer math', () {
    test('secondsLeft rounds up partial seconds and never goes negative', () {
      final now = DateTime(2026, 1, 1, 12);
      expect(secondsLeft(now.add(const Duration(milliseconds: 2500)), now), 3);
      expect(secondsLeft(now.add(const Duration(seconds: 2)), now), 2);
      expect(secondsLeft(now.subtract(const Duration(seconds: 5)), now), 0);
    });
  });
}
