import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/plan/week_planner.dart';
import 'package:rocis_recipes/features/prices/nearby_controller.dart';
import 'package:rocis_recipes/features/prices/price_repository.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/prices/store_resolver.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';

/// The supermarket a week is priced at: the chosen chain, else the nearest one with prices.
PriceStore? pickPlanStore(List<ResolvedStore> resolved, String? chainId) {
  final withStore = [
    for (final r in resolved)
      if (r.store != null) r,
  ];
  final chosen =
      withStore.where((r) => r.chainId == chainId).firstOrNull ??
      withStore.firstOrNull;
  return chosen?.store;
}

/// Builds a fresh week menu with the saved budget, kitchen and exclusions and stores it.
/// Safe to call from a callback: it only reads providers.
Future<void> buildWeekPlanNow(BuildContext context, {int days = 7}) async {
  final settings = context.read<SettingsRepository>();
  final recipes = context.read<RecipeRepository>().all;
  final pantry = context.read<PantryRepository>().ids;
  final resolved = resolveStores(
    snapshot: context.read<PriceRepository>().snapshot,
    location: context.read<NearbyController>().location,
    manual: settings.manualStoreIds,
  );
  final plan = generateWeekPlan(
    recipes: recipes,
    pantryIds: pantry,
    stapleIds: settings.stapleIds,
    appliances: settings.appliances,
    maxMinutes: settings.maxMinutes,
    store: pickPlanStore(resolved, settings.planChainId),
    budget: settings.weeklyBudget?.toDouble(),
    excludedIds: settings.hiddenRecipeIds,
    excludedIngredientIds: settings.excludedIngredientIds,
    days: days,
    seed: DateTime.now().millisecondsSinceEpoch % 10007,
  );
  final now = DateTime.now();
  await settings.setPlanStart(DateTime(now.year, now.month, now.day));
  await settings.setWeekPlan(plan);
}
