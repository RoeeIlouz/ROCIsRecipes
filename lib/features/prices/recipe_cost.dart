import 'package:rocis_recipes/features/prices/store_resolver.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';

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

/// What a whole dish costs to make from scratch, and what one serving of it costs.
class RecipeCost {
  const RecipeCost({
    required this.total,
    required this.perServing,
    required this.unpriced,
  });

  final double total;
  final double perServing;

  /// Needed ingredients with no known price (not part of [total]).
  final int unpriced;
}

/// Price of everything [recipe] needs (optional ingredients and [stapleIds] left out) at the best of
/// the [resolved] branches, divided by its servings. Null when no price is known.
RecipeCost? estimateRecipeCost(
  Recipe recipe,
  List<ResolvedStore> resolved, {
  required Set<String> stapleIds,
}) {
  final ids = {
    for (final i in recipe.ingredients)
      if (!i.optional && !stapleIds.contains(i.ingredientId)) i.ingredientId,
  };
  final cost = estimateBuyCost(ids, resolved);
  if (cost == null) return null;
  final servings = recipe.servings < 1 ? 1 : recipe.servings;
  return RecipeCost(
    total: cost.total,
    perServing: double.parse((cost.total / servings).toStringAsFixed(2)),
    unpriced: cost.unpriced,
  );
}
