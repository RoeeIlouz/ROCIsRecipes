import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_updater.dart';

import '../helpers/test_env.dart';

Map<String, dynamic> _json(String id, {String ing = 'egg'}) => {
  'id': id,
  'titleHe': 'מנה $id',
  'servings': 2,
  'difficulty': 'easy',
  'mealType': 'dinner',
  'totalMinutes': 20,
  'appliances': <String>[],
  'ingredients': [
    {'ingredientId': ing, 'quantity': 2, 'unit': 'unit'},
  ],
  'steps': [
    for (var i = 1; i <= 6; i++) {'textHe': 'שלב $i'},
  ],
};

/// A published pack: manifest plus gzip bytes, like the data branch serves.
class _Pack {
  _Pack(List<Map<String, dynamic>> recipes, {int version = 20}) {
    bytes = gzip.encode(utf8.encode(jsonEncode(recipes)));
    manifest = jsonEncode({
      'version': version,
      'count': recipes.length,
      'sha256': sha256.convert(bytes).toString(),
      'bytes': bytes.length,
    });
  }

  late final List<int> bytes;
  late final String manifest;
}

void main() {
  test(
    'a newer pack adds recipes, retires old built-ins, keeps your own',
    () async {
      final env = await TestEnv.create(
        recipes: [
          const Recipe(
            id: 'old_builtin',
            titleHe: 'ישן',
            ingredients: [RecipeIngredient(ingredientId: 'egg')],
            steps: [RecipeStep(textHe: 'x')],
            totalMinutes: 5,
          ),
          const Recipe(
            id: 'mine',
            titleHe: 'שלי',
            ingredients: [RecipeIngredient(ingredientId: 'egg')],
            steps: [RecipeStep(textHe: 'x')],
            totalMinutes: 5,
            isUserCreated: true,
          ),
        ],
      );
      await env.settings.setStarterVersion(8);
      final pack = _Pack([_json('new_a'), _json('new_b', ing: 'milk')]);
      env.packs
        ..manifest = pack.manifest
        ..bytes = pack.bytes;
      final result = await env.recipeUpdater.update();
      expect(result.status, RecipeUpdateStatus.updated);
      expect(result.version, 20);
      final ids = env.recipes.all.map((r) => r.id).toSet();
      expect(ids, {'new_a', 'new_b', 'mine'});
      expect(env.settings.starterVersion, 20);
    },
  );

  test(
    'the same or an older pack changes nothing and downloads nothing',
    () async {
      final env = await TestEnv.create();
      await env.settings.setStarterVersion(20);
      final pack = _Pack([_json('x')], version: 20);
      env.packs
        ..manifest = pack.manifest
        ..bytes = pack.bytes;
      final result = await env.recipeUpdater.update();
      expect(result.status, RecipeUpdateStatus.upToDate);
      expect(env.packs.packFetches, 0);
      expect(env.recipes.all, isEmpty);
    },
  );

  test('a pack whose checksum does not match is refused', () async {
    final env = await TestEnv.create();
    await env.settings.setStarterVersion(8);
    final pack = _Pack([_json('x')]);
    final corrupted = [...pack.bytes];
    corrupted[corrupted.length ~/ 2] ^= 0xFF;
    env.packs
      ..manifest = pack.manifest
      ..bytes = corrupted;
    final result = await env.recipeUpdater.update();
    expect(result.status, RecipeUpdateStatus.failed);
    expect(env.recipes.all, isEmpty);
    expect(env.settings.starterVersion, 8);
  });

  test('a pack with an invalid recipe is refused as a whole', () async {
    final env = await TestEnv.create();
    await env.settings.setStarterVersion(8);
    final bad = _json('bad', ing: 'not_an_ingredient');
    final pack = _Pack([_json('good'), bad]);
    env.packs
      ..manifest = pack.manifest
      ..bytes = pack.bytes;
    final result = await env.recipeUpdater.update();
    expect(result.status, RecipeUpdateStatus.failed);
    expect(env.recipes.all, isEmpty);
  });

  test('a pack with too few steps is refused', () async {
    final env = await TestEnv.create();
    await env.settings.setStarterVersion(8);
    final short = _json('short')
      ..['steps'] = [
        {'textHe': 'x'},
      ];
    final pack = _Pack([short]);
    env.packs
      ..manifest = pack.manifest
      ..bytes = pack.bytes;
    expect(
      (await env.recipeUpdater.update()).status,
      RecipeUpdateStatus.failed,
    );
  });

  test('being offline is a failure, not a crash', () async {
    final env = await TestEnv.create();
    await env.settings.setStarterVersion(8);
    final result = await env.recipeUpdater.update();
    expect(result.status, RecipeUpdateStatus.failed);
  });

  test('a manifest that is not JSON is refused', () async {
    final env = await TestEnv.create();
    await env.settings.setStarterVersion(8);
    env.packs.manifest = '<html>nope</html>';
    expect(
      (await env.recipeUpdater.update()).status,
      RecipeUpdateStatus.failed,
    );
  });

  test('the check runs at most twice a day', () {
    final now = DateTime(2026, 1, 1, 12);
    expect(shouldCheckForRecipes(null, now), isTrue);
    expect(
      shouldCheckForRecipes(now.subtract(const Duration(hours: 1)), now),
      isFalse,
    );
    expect(
      shouldCheckForRecipes(now.subtract(const Duration(hours: 13)), now),
      isTrue,
    );
  });

  testWidgets('the menu has a button that checks for new recipes', (
    tester,
  ) async {
    final env = await TestEnv.create();
    await env.settings.setStarterVersion(8);
    final pack = _Pack([_json('fresh')]);
    env.packs
      ..manifest = pack.manifest
      ..bytes = pack.bytes;
    await tester.pumpWidget(env.wrapApp('/suggestions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu_update_recipes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipes_update_result')), findsOneWidget);
    expect(env.recipes.all.map((r) => r.id), contains('fresh'));
  });
}
