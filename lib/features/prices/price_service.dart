import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';

/// Estimated list total at one chain's branch.
class ChainTotal {
  const ChainTotal({
    required this.chainId,
    required this.store,
    required this.distanceKm,
    required this.total,
    required this.pricedCount,
    required this.unpricedCount,
  });

  final String chainId;
  final PriceStore? store;
  final double? distanceKm;
  final double total;
  final int pricedCount;
  final int unpricedCount;

  /// False when no item on the list has a price here (a total would mean nothing).
  bool get hasData => pricedCount > 0;

  /// True when some items are not included in [total] because they have no price.
  bool get isPartial => hasData && unpricedCount > 0;
}

class PriceService {
  const PriceService();

  /// Sums the unchecked items priced at [store]. Items without a price (custom
  /// items, unmapped ingredients, or no branch at all) are counted as unpriced,
  /// never as zero.
  ChainTotal totalFor(
    List<ShoppingItem> items,
    String chainId,
    PriceStore? store, {
    double? distanceKm,
  }) {
    var total = 0.0;
    var priced = 0;
    var unpriced = 0;
    for (final item in items) {
      if (item.checked) continue;
      final price = priceOf(item, store);
      if (price == null) {
        unpriced++;
      } else {
        total += price;
        priced++;
      }
    }
    return ChainTotal(
      chainId: chainId,
      store: store,
      distanceKm: distanceKm,
      total: double.parse(total.toStringAsFixed(2)),
      pricedCount: priced,
      unpricedCount: unpriced,
    );
  }

  /// Estimated price of one list item at [store], or null when unknown.
  double? priceOf(ShoppingItem item, PriceStore? store) {
    final id = item.ingredientId;
    if (store == null || id == null) return null;
    return store.prices[id];
  }
}

/// The chain that best covers the list: fewest unpriced items, then lowest total.
ChainTotal? cheapestChain(List<ChainTotal> totals) {
  final candidates = totals.where((t) => t.hasData).toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final byUnpriced = a.unpricedCount.compareTo(b.unpricedCount);
    return byUnpriced != 0 ? byUnpriced : a.total.compareTo(b.total);
  });
  return candidates.first;
}
