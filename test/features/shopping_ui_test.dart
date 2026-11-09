import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/pantry/ui/pantry_screen.dart';
import 'package:rocis_recipes/features/recipes/ui/suggestions_screen.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';
import 'package:rocis_recipes/features/shopping/ui/shopping_screen.dart';

import '../helpers/test_env.dart';

void main() {
  testWidgets('adding free text creates an item', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShoppingScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('shopping_input')), '  שוקולד  ');
    await tester.tap(find.byKey(const Key('shopping_add_button')));
    await tester.pumpAndSettle();
    expect(env.shopping.items.single.label, 'שוקולד');
    expect(env.shopping.items.single.ingredientId, isNull);
    expect(find.text('שוקולד'), findsOneWidget);
  });

  testWidgets('adding a known ingredient name links to the catalog', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShoppingScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('shopping_input')), 'ביצים');
    await tester.tap(find.byKey(const Key('shopping_add_button')));
    await tester.pumpAndSettle();
    expect(env.shopping.items.single.ingredientId, 'egg');
  });

  testWidgets('blank text adds nothing', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShoppingScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('shopping_input')), '   ');
    await tester.tap(find.byKey(const Key('shopping_add_button')));
    await tester.pumpAndSettle();
    expect(env.shopping.items, isEmpty);
  });

  testWidgets('checking an item moves it to the done section', (tester) async {
    final env = await TestEnv.create();
    await env.shopping.add(const ShoppingItem(id: 'a', label: 'חלב'));
    await env.shopping.add(const ShoppingItem(id: 'b', label: 'לחם'));
    await tester.pumpWidget(env.wrap(const ShoppingScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('done_section')), findsNothing);

    await tester.tap(find.byKey(const Key('shopping_item_a')));
    await tester.pumpAndSettle();
    expect(env.shopping.items.firstWhere((e) => e.id == 'a').checked, isTrue);
    expect(
      find.descendant(of: find.byKey(const Key('done_section')), matching: find.byKey(const Key('shopping_item_a'))),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const Key('done_section')), matching: find.byKey(const Key('shopping_item_b'))),
      findsNothing,
    );
  });

  testWidgets('clear checked removes only checked items', (tester) async {
    final env = await TestEnv.create();
    await env.shopping.add(const ShoppingItem(id: 'a', label: 'חלב', checked: true));
    await env.shopping.add(const ShoppingItem(id: 'b', label: 'לחם'));
    await tester.pumpWidget(env.wrap(const ShoppingScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clear_checked_button')));
    await tester.pumpAndSettle();
    expect(env.shopping.items.map((e) => e.id), ['b']);
  });

  testWidgets('bottom navigation switches between the three screens', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrapApp('/pantry'));
    await tester.pumpAndSettle();
    expect(find.byType(PantryScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_shopping')));
    await tester.pumpAndSettle();
    expect(find.byType(ShoppingScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_suggestions')));
    await tester.pumpAndSettle();
    expect(find.byType(SuggestionsScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_pantry')));
    await tester.pumpAndSettle();
    expect(find.byType(PantryScreen), findsOneWidget);
  });
}
