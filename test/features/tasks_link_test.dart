import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';
import 'package:rocis_recipes/features/shopping/shopping_screen_tasks.dart';
import 'package:rocis_recipes/features/shopping/ui/shopping_screen.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

import '../helpers/test_env.dart';

void main() {
  test('the link carries the title and one checklist line per open item', () {
    final uri = buildTasksUri('קניות', ['ביצה 4 יח\'', 'חלב']);
    expect(uri.scheme, 'rocistasks');
    expect(uri.host, 'add_task');
    expect(uri.queryParameters['title'], 'קניות');
    expect(uri.queryParameters['notes'], '- ביצה 4 יח\'\n- חלב');
  });

  testWidgets('the button opens ROCIs Tasks with the unchecked items only', (
    tester,
  ) async {
    final env = await TestEnv.create();
    await env.shopping.add(
      const ShoppingItem(id: 'a', ingredientId: 'egg', label: 'ביצה'),
    );
    await env.shopping.add(
      const ShoppingItem(
        id: 'b',
        ingredientId: 'milk',
        label: 'חלב',
        checked: true,
      ),
    );
    await tester.pumpWidget(env.wrap(const ShoppingScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send_to_tasks_button')));
    await tester.pumpAndSettle();
    final uri = env.launched.single;
    expect(uri.scheme, 'rocistasks');
    expect(uri.queryParameters['notes'], contains('ביצה'));
    expect(uri.queryParameters['notes'], isNot(contains('חלב')));
  });

  testWidgets('the button is hidden when nothing is left to buy', (
    tester,
  ) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShoppingScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('send_to_tasks_button')), findsNothing);
    expect(AppLocalizations.supportedLocales, isNotEmpty);
  });
}
