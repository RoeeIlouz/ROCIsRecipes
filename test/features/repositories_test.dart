import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';
import 'package:rocis_recipes/features/shopping/shopping_repository.dart';

Recipe _recipe(String id) => Recipe(
  id: id,
  titleHe: 'מתכון $id',
  ingredients: const [RecipeIngredient(ingredientId: 'egg')],
  steps: const [RecipeStep(textHe: 'לבשל')],
  totalMinutes: 10,
);

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('rocis_hive_');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'pantry upsert replaces same ingredient and persists across reopen',
    () async {
      var box = await Hive.openBox<Map>('pantry');
      var repo = PantryRepository(box);
      await repo.upsert(const PantryItem(ingredientId: 'egg', quantity: 2));
      await repo.upsert(const PantryItem(ingredientId: 'egg', quantity: 5));
      expect(repo.items.length, 1);
      expect(repo.items.single.quantity, 5);
      expect(repo.ids, {'egg'});

      await box.close();
      box = await Hive.openBox<Map>('pantry');
      repo = PantryRepository(box);
      expect(repo.items.single.quantity, 5);

      await repo.remove('egg');
      expect(repo.items, isEmpty);
    },
  );

  test(
    'shopping addMissing does not duplicate an unchecked ingredient',
    () async {
      final repo = ShoppingRepository(await Hive.openBox<Map>('shopping'));
      await repo.add(
        const ShoppingItem(id: 'a', ingredientId: 'milk', label: 'חלב'),
      );
      await repo.addMissing(const [
        ShoppingItem(id: 'b', ingredientId: 'milk', label: 'חלב'),
        ShoppingItem(id: 'c', ingredientId: 'egg', label: 'ביצים'),
        ShoppingItem(id: 'd', ingredientId: 'egg', label: 'ביצים'),
      ]);
      expect(repo.items.map((e) => e.id), ['a', 'c']);

      await repo.toggle('a');
      await repo.addMissing(const [
        ShoppingItem(id: 'e', ingredientId: 'milk', label: 'חלב'),
      ]);
      expect(repo.items.map((e) => e.id), containsAll(['a', 'e']));

      await repo.clearChecked();
      expect(repo.items.map((e) => e.id), ['c', 'e']);
    },
  );

  test('settings default maxMinutes is 45 and staples seed once', () async {
    final repo = SettingsRepository(await Hive.openBox('settings'));
    expect(repo.maxMinutes, 45);
    expect(repo.appliances, isEmpty);
    expect(repo.stapleIds, isEmpty);

    await repo.seedStaplesIfUnset({'salt', 'oil'});
    expect(repo.stapleIds, {'salt', 'oil'});
    await repo.setStapleIds({'salt'});
    await repo.seedStaplesIfUnset({'salt', 'oil'});
    expect(repo.stapleIds, {'salt'});

    await repo.setAppliances({Appliance.oven, Appliance.microwave});
    await repo.setMaxMinutes(30);
    expect(repo.appliances, {Appliance.oven, Appliance.microwave});
    expect(repo.maxMinutes, 30);
  });

  test(
    'appliances default to stove, oven and microwave once, and respect a later choice',
    () async {
      final repo = SettingsRepository(await Hive.openBox('settings'));
      await repo.seedAppliancesIfUnset();
      expect(repo.appliances, {
        Appliance.stovetop,
        Appliance.oven,
        Appliance.microwave,
      });
      await repo.setAppliances({Appliance.airFryer});
      await repo.seedAppliancesIfUnset();
      expect(repo.appliances, {Appliance.airFryer});
      await repo.setAppliances({});
      await repo.seedAppliancesIfUnset();
      expect(repo.appliances, isEmpty);
    },
  );

  test('recipe seedIfEmpty is a no-op when recipes exist', () async {
    final repo = RecipeRepository(await Hive.openBox<Map>('recipes'));
    await repo.seedIfEmpty([_recipe('r1'), _recipe('r2')]);
    expect(repo.all.length, 2);
    await repo.seedIfEmpty([_recipe('r3')]);
    expect(repo.all.map((e) => e.id), ['r1', 'r2']);
    await repo.upsert(_recipe('r3'));
    expect(repo.all.length, 3);
  });
}
