import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';
import 'package:rocis_recipes/features/shopping/ui/shopping_screen.dart';

import '../../helpers/test_env.dart';

PriceStore _store(String id, String chain, String name, double lat, double lng, Map<String, double> prices) =>
    PriceStore(id: id, chainId: chain, name: name, address: 'הרצל 5, תל אביב', lat: lat, lng: lng, prices: prices);

PriceSnapshot _snapshot({DateTime? generatedAt}) => PriceSnapshot(
      generatedAt: generatedAt ?? DateTime.now(),
      chains: const [
        PriceChain(id: 'shufersal', nameHe: 'שופרסל', nameEn: 'Shufersal'),
        PriceChain(id: 'carrefour', nameHe: 'קרפור', nameEn: 'Carrefour'),
      ],
      stores: [
        _store('shufersal:near', 'shufersal', 'שלי קרוב', 32.09, 34.79, {'egg': 12.9, 'milk': 6.5}),
        _store('shufersal:far', 'shufersal', 'שלי רחוק', 31.2, 34.8, {'egg': 11.0, 'milk': 5.0}),
        _store('carrefour:1', 'carrefour', 'קרפור מרכז', 32.08, 34.78, {'egg': 13.5}),
      ],
    );

const _telAviv = UserLocation(lat: 32.0853, lng: 34.7818);
const _eilat = UserLocation(lat: 29.5577, lng: 34.9519);

Future<TestEnv> _env(
  WidgetTester tester, {
  LocationStatus status = LocationStatus.granted,
  UserLocation? at = _telAviv,
  PriceSnapshot? snapshot,
}) async {
  final env = await TestEnv.create(
    snapshot: snapshot ?? _snapshot(),
    location: FakeLocationProvider(status: status, location: at),
  );
  await env.shopping.add(const ShoppingItem(id: 'a', ingredientId: 'egg', label: 'ביצה'));
  await env.shopping.add(const ShoppingItem(id: 'b', ingredientId: 'milk', label: 'חלב'));
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(env.wrap(const ShoppingScreen()));
  await tester.pumpAndSettle();
  return env;
}

Future<void> _useLocation(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('use_location_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a total per chain in NIS for the nearest branch', (tester) async {
    final env = await _env(tester);
    expect(env.nearby.status, isNull);
    await _useLocation(tester);

    final shufersal = tester.widget<Text>(find.byKey(const Key('price_total_shufersal')));
    expect(shufersal.data, allOf(contains('₪'), contains('19.40')));
    expect(find.text('שלי קרוב'), findsOneWidget);
    expect(find.text('שלי רחוק'), findsNothing);

    final carrefour = tester.widget<Text>(find.byKey(const Key('price_total_carrefour')));
    expect(carrefour.data, allOf(contains('₪'), contains('13.50')));
  });

  testWidgets('partial total shows how many items have no price', (tester) async {
    await _env(tester);
    await _useLocation(tester);
    expect(find.byKey(const Key('partial_carrefour')), findsOneWidget);
    expect(find.text('ל-1 פריטים אין מחיר'), findsOneWidget);
    expect(find.byKey(const Key('partial_shufersal')), findsNothing);
  });

  testWidgets('chain with no priced items shows no data and no total', (tester) async {
    final env = await _env(tester);
    await env.shopping.clearChecked();
    for (final item in env.shopping.items) {
      await env.shopping.remove(item.id);
    }
    await env.shopping.add(const ShoppingItem(id: 'x', label: 'שוקולד'));
    await tester.pumpAndSettle();
    await _useLocation(tester);
    expect(find.byKey(const Key('no_data_shufersal')), findsOneWidget);
    expect(find.byKey(const Key('price_total_shufersal')), findsNothing);
  });

  testWidgets('denied location shows the branch picker and persists the choice', (tester) async {
    final env = await _env(tester, status: LocationStatus.denied, at: null);
    await _useLocation(tester);
    expect(find.byKey(const Key('price_total_shufersal')), findsNothing);

    await tester.tap(find.byKey(const Key('store_picker_shufersal')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('שלי רחוק').last);
    await tester.pumpAndSettle();

    expect(env.settings.manualStoreIds['shufersal'], 'shufersal:far');
    final total = tester.widget<Text>(find.byKey(const Key('price_total_shufersal')));
    expect(total.data, contains('16.00'));
  });

  testWidgets('a saved manual branch is used when location is not granted', (tester) async {
    final env = await TestEnv.create(
      snapshot: _snapshot(),
      location: FakeLocationProvider(status: LocationStatus.denied),
    );
    await env.settings.setManualStore('shufersal', 'shufersal:near');
    await env.shopping.add(const ShoppingItem(id: 'a', ingredientId: 'egg', label: 'ביצה'));
    await tester.pumpWidget(env.wrap(const ShoppingScreen()));
    await tester.pumpAndSettle();
    final total = tester.widget<Text>(find.byKey(const Key('price_total_shufersal')));
    expect(total.data, contains('12.90'));
  });

  testWidgets('far from all branches shows a too far message', (tester) async {
    await _env(tester, at: _eilat);
    await _useLocation(tester);
    expect(find.byKey(const Key('too_far_shufersal')), findsOneWidget);
    expect(find.byKey(const Key('price_total_shufersal')), findsNothing);
  });

  testWidgets('stale snapshot shows a warning and a fresh one does not', (tester) async {
    await _env(tester, snapshot: _snapshot(generatedAt: DateTime.now().subtract(const Duration(days: 8))));
    expect(find.byKey(const Key('stale_warning')), findsOneWidget);
  });

  testWidgets('fresh snapshot shows no stale warning', (tester) async {
    await _env(tester);
    expect(find.byKey(const Key('stale_warning')), findsNothing);
  });

  testWidgets('navigate opens a Google Maps search link for the branch address', (tester) async {
    final env = await _env(tester);
    await _useLocation(tester);
    await tester.tap(find.byKey(const Key('navigate_shufersal')));
    await tester.pumpAndSettle();
    final uri = env.launched.single;
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['query'], 'הרצל 5, תל אביב');
  });

  testWidgets('price line appears under priced items at the best covering chain', (tester) async {
    await _env(tester);
    await _useLocation(tester);
    final line = tester.widget<Text>(find.byKey(const Key('price_line_a')));
    expect(line.data, allOf(contains('₪'), contains('12.90')));
    expect(find.byKey(const Key('price_line_b')), findsOneWidget);
  });

  testWidgets('no price block is shown when the snapshot has no chains', (tester) async {
    final env = await TestEnv.create();
    await env.shopping.add(const ShoppingItem(id: 'a', ingredientId: 'egg', label: 'ביצה'));
    await tester.pumpWidget(env.wrap(const ShoppingScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('use_location_button')), findsNothing);
  });

  testWidgets('shows the OpenStreetMap attribution', (tester) async {
    await _env(tester);
    expect(find.text('נתוני מפה מתורמי OpenStreetMap'), findsOneWidget);
  });
}
