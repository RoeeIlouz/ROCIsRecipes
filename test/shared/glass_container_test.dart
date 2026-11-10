import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/shared/ui/widgets/glass_container.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, {required bool glass}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: GlassContainer(
              enableGlass: glass,
              padding: const EdgeInsets.all(24),
              child: const SizedBox(height: 40, child: Text('content')),
            ),
          ),
        ),
      ),
    ));
  }

  for (final glass in [true, false]) {
    testWidgets('the clipping Material covers the whole card, not just the padded content (glass: $glass)',
        (tester) async {
      await pumpCard(tester, glass: glass);
      final card = tester.getSize(find.byType(GlassContainer));
      final material = tester.getSize(
        find.descendant(of: find.byType(GlassContainer), matching: find.byType(Material)).first,
      );
      // If the Material shrank to the content box, its rounded clip would cut text and
      // borders near the card's inner edge (the first letter of Hebrew titles).
      // Only the 1px border may sit outside it (it was 50px narrower and 50px shorter).
      expect(card.width - material.width, lessThanOrEqualTo(2));
      expect(card.height - material.height, lessThanOrEqualTo(2));
    });

    testWidgets('padding still insets the child (glass: $glass)', (tester) async {
      await pumpCard(tester, glass: glass);
      final card = tester.getTopLeft(find.byType(GlassContainer));
      final text = tester.getTopLeft(find.text('content'));
      expect(text.dx - card.dx, greaterThanOrEqualTo(24));
      expect(text.dy - card.dy, greaterThanOrEqualTo(24));
    });
  }
}
