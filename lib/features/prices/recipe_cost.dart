import 'package:rocis_recipes/features/prices/store_resolver.dart';

/// Estimated price of the ingredients still to buy for a dish.
class BuyCost {
  const BuyCost({required this.total, required this.unpriced});

  final double total;

  /// Ingredients with no known price, which are not part of [total].
  final int unpriced;
}

/// What it costs to buy [ingredientIds] at the best of the [resolved] branches: the one that prices
/// the most of them, then the cheapest. Null when no branch is known or none prices any ingredient.
BuyCost? estimateBuyCost(
  Iterable<String> ingredientIds,
  List<ResolvedStore> resolved,
) {
  final ids = ingredientIds.toList();
  final stores = [
    for (final r in resolved)
      if (r.store != null) r.store!,
  ];
  if (stores.isEmpty) return null;
  if (ids.isEmpty) return const BuyCost(total: 0, unpriced: 0);
  BuyCost? best;
  for (final store in stores) {
    var total = 0.0;
    var unpriced = 0;
    for (final id in ids) {
      final price = store.prices[id];
      if (price == null) {
        unpriced++;
      } else {
        total += price;
      }
    }
    final candidate = BuyCost(
      total: double.parse(total.toStringAsFixed(2)),
      unpriced: unpriced,
    );
    if (best == null ||
        candidate.unpriced < best.unpriced ||
        (candidate.unpriced == best.unpriced && candidate.total < best.total)) {
      best = candidate;
    }
  }
  return best!.unpriced == ids.length ? null : best;
}
