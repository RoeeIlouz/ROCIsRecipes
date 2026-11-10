import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/pantry/ui/ingredient_picker_sheet.dart';
import 'package:rocis_recipes/features/pantry/ui/pantry_screen.dart';

import '../helpers/test_env.dart';

void main() {
  Future<TestEnv> openPicker(WidgetTester tester) async {
    final env = await TestEnv.create();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(env.wrap(const PantryScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick_from_list_button')));
    await tester.pumpAndSettle();
    return env;
  }

  testWidgets('opens a sheet with a tile and icon for every ingredient', (tester) async {
    await openPicker(tester);
    expect(find.byType(IngredientPickerSheet), findsOneWidget);
    for (final id in ['tomato', 'cucumber', 'egg', 'milk', 'salt']) {
      expect(find.byKey(Key('picker_tile_$id')), findsOneWidget, reason: id);
    }
    expect(find.text('🍅'), findsOneWidget);
    expect(find.text('🥛'), findsOneWidget);
  });

  testWidgets('tapping a tile adds the ingredient and tapping again removes it', (tester) async {
    final env = await openPicker(tester);
    await tester.tap(find.byKey(const Key('picker_tile_milk')));
    await tester.pumpAndSettle();
    expect(env.pantry.ids, {'milk'});
    expect(find.byKey(const Key('picker_selected_milk')), findsOneWidget);

    await tester.tap(find.byKey(const Key('picker_tile_milk')));
    await tester.pumpAndSettle();
    expect(env.pantry.ids, isEmpty);
    expect(find.byKey(const Key('picker_selected_milk')), findsNothing);
  });

  testWidgets('the sheet stays open so several ingredients can be picked', (tester) async {
    final env = await openPicker(tester);
    await tester.tap(find.byKey(const Key('picker_tile_egg')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('picker_tile_tomato')));
    await tester.pumpAndSettle();
    expect(env.pantry.ids, {'egg', 'tomato'});
    expect(find.byType(IngredientPickerSheet), findsOneWidget);
  });

  testWidgets('ingredients already in the pantry show as selected', (tester) async {
    final env = await TestEnv.create();
    await env.pantry.upsert(const PantryItem(ingredientId: 'egg'));
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(env.wrap(const PantryScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick_from_list_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker_selected_egg')), findsOneWidget);
    expect(find.byKey(const Key('picker_selected_milk')), findsNothing);
  });

  testWidgets('the close button closes the sheet', (tester) async {
    await openPicker(tester);
    await tester.tap(find.byKey(const Key('picker_close')));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientPickerSheet), findsNothing);
  });

  testWidgets('the done button closes the sheet', (tester) async {
    await openPicker(tester);
    await tester.tap(find.byKey(const Key('picker_done')));
    await tester.pumpAndSettle();
    expect(find.byType(IngredientPickerSheet), findsNothing);
  });

  testWidgets('search filters the grid by Hebrew name', (tester) async {
    await openPicker(tester);
    await tester.enterText(find.byKey(const Key('picker_search')), 'חלב');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker_tile_milk')), findsOneWidget);
    expect(find.byKey(const Key('picker_tile_egg')), findsNothing);
  });

  testWidgets('search understands plural synonyms and niqqud', (tester) async {
    await openPicker(tester);
    await tester.enterText(find.byKey(const Key('picker_search')), 'עַגְבָנִיּוֹת');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker_tile_tomato')), findsOneWidget);
  });

  testWidgets('a category chip filters the grid and All restores it', (tester) async {
    await openPicker(tester);
    await tester.tap(find.byKey(const Key('picker_cat_dairy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker_tile_milk')), findsOneWidget);
    expect(find.byKey(const Key('picker_tile_egg')), findsOneWidget);
    expect(find.byKey(const Key('picker_tile_tomato')), findsNothing);

    await tester.tap(find.byKey(const Key('picker_cat_all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker_tile_tomato')), findsOneWidget);
  });

  testWidgets('no matches shows an empty message', (tester) async {
    await openPicker(tester);
    await tester.enterText(find.byKey(const Key('picker_search')), 'zzzzzz');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('picker_empty')), findsOneWidget);
  });
}
