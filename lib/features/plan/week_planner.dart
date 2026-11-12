import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_filters.dart';

/// Marks a day of the stored plan the user chose to skip (no dish, and it is not filled again).
const String kSkippedDay = '!skip';

/// Meal types a weekly menu is built from (one main meal per day).
const Set<String> kPlanMealTypes = {'dinner', 'lunch'};

/// What buying for a weekly plan comes to.
class PlanSummary {
  const PlanSummary({
    required this.shoppingIds,
    required this.total,
    required this.unpriced,
  });

  /// Ingredients to buy, once each, in the order the plan needs them.
  final List<String> shoppingIds;

  /// Price of everything in [shoppingIds] that has a known price at the store.
  final double total;

  /// Ingredients in [shoppingIds] without a known price (not part of [total]).
  final int unpriced;
}

List<String> _required(Recipe r) => [
  for (final i in r.ingredients)
    if (!i.optional) i.ingredientId,
];

/// Builds a menu of one dish per day that stays within [budget] when the [store]'s prices are known.
///
/// Days are filled in order. Each day takes the dish that adds the least to the shopping basket:
/// ingredients already at home, or already bought for an earlier day, cost nothing again, so the
/// menu naturally reuses ingredients and starts with what the kitchen already has. Dishes must fit the
/// time and appliances, are never repeated, and the same main protein two days in a row is avoided
/// when there is a comparable alternative. A day with no dish that fits the budget is left null.
///
/// With [current] and [rebuildDays] only those days are chosen again (the others are kept and their
/// ingredients count), which is how one dish is swapped. [seed] varies ties so the result is repeatable.
List<String?> generateWeekPlan({
  required List<Recipe> recipes,
  required Set<String> pantryIds,
  required Set<String> stapleIds,
  required Set<Appliance> appliances,
  required int maxMinutes,
  required PriceStore? store,
  double? budget,
  Set<String> excludedIds = const {},
  List<String?>? current,
  Set<int>? rebuildDays,
  int days = 7,
  int seed = 0,
}) {
  final byId = {for (final r in recipes) r.id: r};
  final plan = <String?>[
    for (var d = 0; d < days; d++)
      (current != null && d < current.length) ? current[d] : null,
  ];
  final redo = rebuildDays ?? {for (var d = 0; d < days; d++) d};
  for (final d in redo) {
    if (d >= 0 && d < days) plan[d] = null;
  }

  final eligible = [
    for (final r in recipes)
      if (kPlanMealTypes.contains(r.mealType) &&
          r.totalMinutes <= maxMinutes &&
          appliances.containsAll(r.appliances) &&
          !excludedIds.contains(r.id))
        r,
  ];

  double priceOf(String id) => store?.prices[id] ?? 0;

  final bought = {...pantryIds, ...stapleIds};
  var spent = 0.0;
  final used = <String>{};
  for (final id in plan.whereType<String>()) {
    final r = byId[id];
    if (r == null) continue;
    used.add(id);
    for (final ing in _required(r)) {
      if (bought.add(ing)) spent += priceOf(ing);
    }
  }

  // When one day is swapped, the dish it had is skipped unless nothing else fits.
  final replaced = <String>{
    if (rebuildDays != null && current != null)
      for (final d in rebuildDays)
        if (d >= 0 && d < current.length && current[d] != null) current[d]!,
  };

  for (final d in (redo.toList()..sort())) {
    if (d < 0 || d >= days) continue;
    final previous = d > 0 && plan[d - 1] != null ? byId[plan[d - 1]] : null;
    final previousKinds = previous == null
        ? const <String>{}
        : proteinKinds(previous);

    (Recipe, double)? pick({required bool avoidReplaced}) {
      Recipe? best;
      var bestScore = double.infinity;
      var bestMarginal = 0.0;
      for (final r in eligible) {
        if (used.contains(r.id)) continue;
        if (avoidReplaced && replaced.contains(r.id)) continue;
        var marginal = 0.0;
        var unpriced = 0;
        for (final ing in {..._required(r)}) {
          if (bought.contains(ing)) continue;
          final price = store?.prices[ing];
          if (price == null) {
            unpriced++;
          } else {
            marginal += price;
          }
        }
        if (budget != null && store != null && spent + marginal > budget) {
          continue;
        }
        final kinds = proteinKinds(r);
        final repeats =
            kinds.any(previousKinds.contains) && !kinds.contains('vegetarian');
        final jitter = ((r.id.hashCode ^ (seed * 7919)) & 0xffff) / 0xffff;
        final score =
            marginal +
            unpriced * 5 +
            r.totalMinutes * 0.02 +
            (repeats ? 4 : 0) +
            jitter;
        if (score < bestScore) {
          bestScore = score;
          best = r;
          bestMarginal = marginal;
        }
      }
      return best == null ? null : (best, bestMarginal);
    }

    final choice = pick(avoidReplaced: true) ?? pick(avoidReplaced: false);
    if (choice == null) continue;
    final (best, marginal) = choice;
    plan[d] = best.id;
    used.add(best.id);
    for (final ing in _required(best)) {
      bought.add(ing);
    }
    spent += marginal;
  }
  return plan;
}

/// The shopping basket and its price for [plan] (null days are skipped).
PlanSummary summarizePlan(
  List<String?> plan,
  List<Recipe> recipes, {
  required Set<String> pantryIds,
  required Set<String> stapleIds,
  required PriceStore? store,
}) {
  final byId = {for (final r in recipes) r.id: r};
  final have = {...pantryIds, ...stapleIds};
  final ids = <String>[];
  for (final id in plan) {
    final r = id == null ? null : byId[id];
    if (r == null) continue;
    for (final ing in _required(r)) {
      if (have.contains(ing) || ids.contains(ing)) continue;
      ids.add(ing);
    }
  }
  var total = 0.0;
  var unpriced = 0;
  for (final id in ids) {
    final price = store?.prices[id];
    if (price == null) {
      unpriced++;
    } else {
      total += price;
    }
  }
  return PlanSummary(
    shoppingIds: ids,
    total: double.parse(total.toStringAsFixed(2)),
    unpriced: unpriced,
  );
}
