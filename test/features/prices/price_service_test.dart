import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/prices/price_service.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';

PriceStore _store(Map<String, double> prices, {String chain = 'shufersal'}) =>
    PriceStore(
      id: '$chain:1',
      chainId: chain,
      name: 'branch',
      address: 'x',
      lat: 32,
      lng: 34.8,
      prices: prices,
    );

ShoppingItem _item(String id, {String? ingredientId, bool checked = false}) =>
    ShoppingItem(
      id: id,
      ingredientId: ingredientId,
      label: id,
      checked: checked,
    );

void main() {
  const service = PriceService();

  test('totals sum the price of unchecked priced items', () {
    final total = service.totalFor(
      [_item('a', ingredientId: 'egg'), _item('b', ingredientId: 'milk')],
      'shufersal',
      _store({'egg': 10, 'milk': 7.5}),
    );
    expect(total.total, 17.5);
    expect(total.pricedCount, 2);
    expect(total.unpricedCount, 0);
    expect(total.hasData, isTrue);
    expect(total.isPartial, isFalse);
  });

  test('checked items are ignored', () {
    final total = service.totalFor(
      [
        _item('a', ingredientId: 'egg'),
        _item('b', ingredientId: 'milk', checked: true),
      ],
      'shufersal',
      _store({'egg': 10, 'milk': 7.5}),
    );
    expect(total.total, 10);
    expect(total.pricedCount, 1);
    expect(total.unpricedCount, 0);
  });

  test('unpriced item is excluded and total is partial', () {
    final total = service.totalFor(
      [_item('a', ingredientId: 'egg'), _item('b', ingredientId: 'bread')],
      'shufersal',
      _store({'egg': 10}),
    );
    expect(total.total, 10);
    expect(total.unpricedCount, 1);
    expect(total.isPartial, isTrue);
    expect(total.hasData, isTrue);
  });

  test('no priced items means no data', () {
    final total = service.totalFor(
      [_item('a', ingredientId: 'bread')],
      'shufersal',
      _store({'egg': 10}),
    );
    expect(total.hasData, isFalse);
    expect(total.total, 0);
    expect(total.unpricedCount, 1);
  });

  test('custom items without an ingredient id count as unpriced', () {
    final total = service.totalFor(
      [_item('a', ingredientId: 'egg'), _item('b')],
      'shufersal',
      _store({'egg': 10}),
    );
    expect(total.unpricedCount, 1);
    expect(total.isPartial, isTrue);
  });

  test('no branch means no data and every unchecked item unpriced', () {
    final total = service.totalFor(
      [_item('a', ingredientId: 'egg'), _item('b', checked: true)],
      'shufersal',
      null,
    );
    expect(total.hasData, isFalse);
    expect(total.store, isNull);
    expect(total.unpricedCount, 1);
    expect(total.chainId, 'shufersal');
  });

  test('an empty list has no data', () {
    final total = service.totalFor(const [], 'shufersal', _store({'egg': 10}));
    expect(total.hasData, isFalse);
    expect(total.isPartial, isFalse);
  });

  group('cheapestChain', () {
    ChainTotal t(String chain, double total, int priced, int unpriced) =>
        ChainTotal(
          chainId: chain,
          store: null,
          distanceKm: null,
          total: total,
          pricedCount: priced,
          unpricedCount: unpriced,
        );

    test('prefers fewer unpriced items, then lower total', () {
      final result = cheapestChain([
        t('a', 5, 1, 2),
        t('b', 20, 3, 0),
        t('c', 18, 3, 0),
      ]);
      expect(result?.chainId, 'c');
    });

    test(
      'ignores chains without data and returns null when none have data',
      () {
        expect(cheapestChain([t('a', 0, 0, 3)]), isNull);
        expect(cheapestChain(const []), isNull);
      },
    );
  });
}
