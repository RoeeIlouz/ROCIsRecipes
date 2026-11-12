import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';

import '../helpers/test_env.dart';

void main() {
  testWidgets('the shopping list can be copied as text to share', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final env = await TestEnv.create();
    await env.shopping.add(
      const ShoppingItem(
        id: 'a',
        label: 'חלב',
        ingredientId: 'milk',
        quantity: 2,
        unit: 'cup',
      ),
    );
    await env.shopping.add(const ShoppingItem(id: 'b', label: 'לחם'));
    await env.shopping.add(
      const ShoppingItem(id: 'c', label: 'ביצים', checked: true),
    );
    await tester.pumpWidget(env.wrapApp('/shopping'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('copy_list_button')));
    await tester.pumpAndSettle();
    expect(copied, isNotNull);
    expect(copied, contains('חלב'));
    expect(copied, contains('2'));
    expect(copied, contains('לחם'));
    // Items already bought are not part of what is left to buy.
    expect(copied, isNot(contains('ביצים')));
    expect(find.byKey(const Key('list_copied')), findsOneWidget);
  });

  testWidgets('there is nothing to copy for an empty list', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrapApp('/shopping'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('copy_list_button')), findsNothing);
  });
}
