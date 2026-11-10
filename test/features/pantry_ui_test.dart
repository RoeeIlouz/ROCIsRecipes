import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/pantry/ui/pantry_screen.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';

import '../helpers/test_env.dart';

void main() {
  Future<TestEnv> pump(WidgetTester tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const PantryScreen()));
    await tester.pumpAndSettle();
    return env;
  }

  testWidgets('typing a Hebrew ingredient with niqqud and tapping add stores the catalog ingredient',
      (tester) async {
    final env = await pump(tester);
    await tester.enterText(find.byKey(const Key('pantry_input')), 'עַגְבָנִיּוֹת');
    await tester.tap(find.byKey(const Key('pantry_add_button')));
    await tester.pumpAndSettle();
    expect(env.pantry.ids, {'tomato'});
    expect(find.text('עגבנייה'), findsOneWidget);
  });

  testWidgets('typing unknown text adds a custom ingredient and shows it', (tester) async {
    final env = await pump(tester);
    await tester.enterText(find.byKey(const Key('pantry_input')), 'פיצוחים');
    await tester.tap(find.byKey(const Key('pantry_add_button')));
    await tester.pumpAndSettle();
    expect(env.pantry.items.single.ingredientId, startsWith('custom:'));
    expect(find.text('פיצוחים'), findsOneWidget);
  });

  testWidgets('blank input adds nothing', (tester) async {
    final env = await pump(tester);
    await tester.enterText(find.byKey(const Key('pantry_input')), '   ');
    await tester.tap(find.byKey(const Key('pantry_add_button')));
    await tester.pumpAndSettle();
    expect(env.pantry.items, isEmpty);
  });

  testWidgets('tapping a suggestion from search adds it', (tester) async {
    final env = await pump(tester);
    await tester.enterText(find.byKey(const Key('pantry_input')), 'מלפ');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('suggestion_cucumber')));
    await tester.pumpAndSettle();
    expect(env.pantry.ids, {'cucumber'});
  });

  testWidgets('picking from the list adds the ingredient', (tester) async {
    final env = await pump(tester);
    await tester.tap(find.byKey(const Key('pick_from_list_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('picker_tile_milk')));
    await tester.pumpAndSettle();
    expect(env.pantry.ids, {'milk'});
  });

  testWidgets('selecting appliances persists to SettingsRepository', (tester) async {
    final env = await pump(tester);
    await tester.tap(find.byKey(const Key('appliance_oven')));
    await tester.pumpAndSettle();
    expect(env.settings.appliances, {Appliance.oven});
    await tester.tap(find.byKey(const Key('appliance_oven')));
    await tester.pumpAndSettle();
    expect(env.settings.appliances, isEmpty);
  });

  testWidgets('time chips update maxMinutes', (tester) async {
    final env = await pump(tester);
    await tester.ensureVisible(find.byKey(const Key('time_30')));
    await tester.tap(find.byKey(const Key('time_30')));
    await tester.pumpAndSettle();
    expect(env.settings.maxMinutes, 30);
  });
}
