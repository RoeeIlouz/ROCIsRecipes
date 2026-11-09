import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/app.dart';

void main() {
  testWidgets('defaults to Hebrew RTL', (tester) async {
    await tester.pumpWidget(const RecipesApp());
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.rtl);
  });

  testWidgets('switches to English LTR', (tester) async {
    await tester.pumpWidget(const RecipesApp(locale: Locale('en')));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.ltr);
  });
}
