import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PriceSnapshot> load() async {
    final data = await rootBundle.load('assets/prices/snapshot.json.gz');
    return PriceSnapshot.fromGzipBytes(data.buffer.asUint8List());
  }

  test('bundled snapshot parses and has branches with coordinates in Israel', () async {
    final s = await load();
    expect(s.chains, isNotEmpty);
    expect(s.stores.length, greaterThan(100));
    for (final store in s.stores) {
      expect(store.lat, inInclusiveRange(29.4, 33.4), reason: store.id);
      expect(store.lng, inInclusiveRange(34.2, 35.9), reason: store.id);
      expect(store.address, isNotEmpty, reason: store.id);
      expect(store.prices, isNotEmpty, reason: store.id);
      expect(store.prices.values.every((p) => p > 0), isTrue, reason: store.id);
    }
  });

  test('bundled snapshot only prices ingredient ids that exist in the catalog', () async {
    final s = await load();
    final catalog = IngredientCatalog.fromJson(await rootBundle.loadString('assets/data/ingredients.json'));
    final unknown = {
      for (final store in s.stores)
        for (final id in store.prices.keys)
          if (catalog.byId(id) == null) id,
    };
    expect(unknown, isEmpty);
  });

  test('every chain referenced by a branch is declared', () async {
    final s = await load();
    final declared = s.chains.map((c) => c.id).toSet();
    expect(s.stores.map((st) => st.chainId).toSet().difference(declared), isEmpty);
  });
}
