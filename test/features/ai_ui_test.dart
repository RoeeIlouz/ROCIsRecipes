import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rocis_recipes/features/pantry/pantry_item.dart';

import '../helpers/test_env.dart';

Future<TestEnv> _open(
  WidgetTester tester,
  String at, {
  void Function(TestEnv)? setup,
}) async {
  final env = await TestEnv.create();
  setup?.call(env);
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(env.wrapApp(at));
  await tester.pumpAndSettle();
  return env;
}

const _eggRecipe = {
  'title': 'חביתה מהסריקה',
  'servings': 2,
  'minutes': 10,
  'ingredients': [
    {'name': 'ביצים', 'quantity': 3, 'unit': "יח'"},
  ],
  'steps': ['טורפים וצולים'],
};

Future<void> _importFromText(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('editor_ai_import')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('ai_text')),
    'מתכון לחביתה: 3 ביצים',
  );
  await tester.tap(find.byKey(const Key('ai_analyze')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('importing pasted text fills the editor for review', (
    tester,
  ) async {
    final env = await _open(
      tester,
      '/recipe-edit',
      setup: (e) => e.ai.recipeJson = _eggRecipe,
    );
    await _importFromText(tester);
    expect(env.ai.lastText, contains('3 ביצים'));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('editor_title')))
          .controller!
          .text,
      'חביתה מהסריקה',
    );
    expect(find.byKey(const Key('editor_row_egg')), findsOneWidget);
    expect(
      env.recipes.all,
      isEmpty,
      reason: 'nothing is saved until the user presses save',
    );
  });

  testWidgets('the model is downloaded after the user agrees, once', (
    tester,
  ) async {
    final env = await _open(
      tester,
      '/recipe-edit',
      setup: (e) {
        e.ai.installed = false;
        e.ai.recipeJson = _eggRecipe;
      },
    );
    await tester.tap(find.byKey(const Key('editor_ai_import')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ai_text')), 'x');
    await tester.tap(find.byKey(const Key('ai_analyze')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai_download_confirm')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai_download_confirm')));
    await tester.pumpAndSettle();
    expect(env.ai.installs, 1);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('editor_title')))
          .controller!
          .text,
      'חביתה מהסריקה',
    );
  });

  testWidgets('declining the download changes nothing', (tester) async {
    final env = await _open(
      tester,
      '/recipe-edit',
      setup: (e) => e.ai.installed = false,
    );
    await tester.tap(find.byKey(const Key('editor_ai_import')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ai_text')), 'x');
    await tester.tap(find.byKey(const Key('ai_analyze')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai_download_cancel')));
    await tester.pumpAndSettle();
    expect(env.ai.installs, 0);
  });

  testWidgets(
    'an unreadable reply tells the user instead of failing silently',
    (tester) async {
      await _open(tester, '/recipe-edit', setup: (e) => e.ai.recipeJson = null);
      await _importFromText(tester);
      expect(find.byKey(const Key('ai_failed')), findsOneWidget);
    },
  );

  testWidgets('an engine error is reported as unavailable', (tester) async {
    await _open(
      tester,
      '/recipe-edit',
      setup: (e) => e.ai.error = StateError('no engine'),
    );
    await _importFromText(tester);
    expect(find.byKey(const Key('ai_failed')), findsOneWidget);
  });

  testWidgets(
    'a photo of the kitchen offers the found ingredients and adds the confirmed ones',
    (tester) async {
      final env = await _open(
        tester,
        '/pantry',
        setup: (e) {
          e.photos.nextBytes = Uint8List.fromList([1, 2, 3]);
          e.ai.names = ['ביצים', 'עגבנייה', 'דבר לא מוכר'];
        },
      );
      await tester.tap(find.byKey(const Key('pantry_ai_scan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ai_scan_gallery')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai_found_egg')), findsOneWidget);
      expect(find.byKey(const Key('ai_found_tomato')), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('ai_found_tomato')),
      ); // untick tomato
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ai_found_add')));
      await tester.pumpAndSettle();
      expect(env.pantry.ids, {'egg'});
    },
  );

  group('invent a dish from the pantry', () {
    testWidgets('opens the AI dish in the editor with the pantry as input', (
      tester,
    ) async {
      final env = await _open(
        tester,
        '/suggestions',
        setup: (e) => e.ai.recipeJson = _eggRecipe,
      );
      await env.pantry.upsert(const PantryItem(ingredientId: 'egg'));
      await env.pantry.upsert(const PantryItem(ingredientId: 'tomato'));
      await tester.tap(find.byKey(const Key('ai_invent_button')));
      await tester.pumpAndSettle();
      expect(env.ai.lastInventIngredients, containsAll(['ביצה', 'עגבנייה']));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('editor_title')))
            .controller!
            .text,
        'חביתה מהסריקה',
      );
      expect(
        env.recipes.all,
        isEmpty,
        reason: 'only saved when the user saves',
      );
    });

    testWidgets('asks for ingredients first when the kitchen is empty', (
      tester,
    ) async {
      final env = await _open(
        tester,
        '/suggestions',
        setup: (e) => e.ai.recipeJson = _eggRecipe,
      );
      await tester.tap(find.byKey(const Key('ai_invent_button')));
      await tester.pumpAndSettle();
      expect(env.ai.lastInventIngredients, isNull);
      expect(find.text('הוסיפו קודם מצרכים למטבח'), findsOneWidget);
    });

    testWidgets(
      'a failed attempt says so and stays on the suggestions screen',
      (tester) async {
        final env = await _open(
          tester,
          '/suggestions',
          setup: (e) => e.ai.recipeJson = null,
        );
        await env.pantry.upsert(const PantryItem(ingredientId: 'egg'));
        await tester.tap(find.byKey(const Key('ai_invent_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('editor_title')), findsNothing);
        expect(find.byKey(const Key('ai_invent_button')), findsOneWidget);
      },
    );
  });
}
