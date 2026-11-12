import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/catalog/ingredient.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/catalog/ingredient_label.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/plan/week_planner.dart';
import 'package:rocis_recipes/features/prices/budget.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/prices/ui/budget_card.dart';
import 'package:rocis_recipes/features/prices/ui/price_summary.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_card.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_photo.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';
import 'package:rocis_recipes/features/shopping/shopping_repository.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';
import 'package:rocis_recipes/shared/ui/widgets/glass_container.dart';

const _days = 7;

/// A week of dinners built around the kitchen, a supermarket's prices and a weekly budget. Tonight's
/// dish is the big card; every day can be swapped, skipped, or hidden for good.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsRepository>();
    final recipes = context.watch<RecipeRepository>().all;
    final pantry = context.watch<PantryRepository>().ids;
    final view = PriceViewData.of(context);
    final money = currencyFormat(context);
    final locale = Localizations.localeOf(context);
    final isHebrew = locale.languageCode == 'he';

    // The supermarket the week is priced at: the chosen chain, else the nearest one with prices.
    final withStore = [
      for (final r in view.resolved)
        if (r.store != null) r,
    ];
    final chosen =
        withStore.where((r) => r.chainId == settings.planChainId).firstOrNull ??
        withStore.firstOrNull;
    final store = chosen?.store;

    final plan = settings.weekPlan;
    final hasPlan = plan.any((e) => e != null && e != kSkippedDay);
    final budget = settings.weeklyBudget;
    final byId = {for (final r in recipes) r.id: r};

    PlanSummary summaryOf(List<String?> p) => summarizePlan(
      p,
      recipes,
      pantryIds: pantry,
      stapleIds: settings.stapleIds,
      store: store,
    );
    final summary = summaryOf(plan);

    Future<void> generate({List<String?>? base, Set<int>? days}) async {
      final next = generateWeekPlan(
        recipes: recipes,
        pantryIds: pantry,
        stapleIds: settings.stapleIds,
        appliances: settings.appliances,
        maxMinutes: settings.maxMinutes,
        store: store,
        budget: budget?.toDouble(),
        excludedIds: settings.hiddenRecipeIds,
        excludedIngredientIds: settings.excludedIngredientIds,
        current: base,
        rebuildDays: days,
        days: _days,
        seed: DateTime.now().millisecondsSinceEpoch % 10007,
      );
      if (days == null) {
        final now = DateTime.now();
        await settings.setPlanStart(DateTime(now.year, now.month, now.day));
      }
      await settings.setWeekPlan(next);
    }

    List<String?> padded() => [
      for (var i = 0; i < _days; i++) i < plan.length ? plan[i] : null,
    ];

    Future<void> addToList() async {
      final catalog = context.read<IngredientCatalog>();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      await context.read<ShoppingRepository>().addMissing([
        for (final id in summary.shoppingIds)
          ShoppingItem(
            id: 'plan_${id}_$stamp',
            ingredientId: id,
            label: ingredientLabel(context, catalog, id),
          ),
      ]);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.planAdded)));
      }
    }

    final start = settings.planStart ?? DateTime.now();
    String dayLabel(int i) => i == 0
        ? l10n.planTonight
        : DateFormat.EEEE(
            locale.toString(),
          ).format(start.add(Duration(days: i)));

    // What each day adds to the basket, so cheap and pricey days are visible.
    final dayCost = <int, double>{};
    var previousTotal = 0.0;
    for (var i = 0; i < plan.length; i++) {
      final total = summaryOf(plan.sublist(0, i + 1)).total;
      dayCost[i] = double.parse((total - previousTotal).toStringAsFixed(2));
      previousTotal = total;
    }

    final status = budget == null
        ? null
        : BudgetStatus(budget: budget.toDouble(), spent: summary.total);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.planTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasPlan) Text(l10n.planIntro),
                if (hasPlan && store == null)
                  Text(
                    l10n.planItemsToBuy(summary.shoppingIds.length),
                    key: const Key('plan_items_count'),
                    style: theme.textTheme.titleLarge,
                  ),
                if (hasPlan && store != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        money.format(summary.total),
                        key: const Key('plan_total'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.planTotal)),
                    ],
                  ),
                  if (summary.unpriced > 0)
                    Text(
                      l10n.partialTotal(summary.unpriced),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
                if (status != null && store != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: status.fraction,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: status.isOver
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.budgetUsed(
                      money.format(summary.total),
                      money.format(budget),
                    ),
                  ),
                  if (status.isOver)
                    Text(
                      l10n.budgetOver(money.format(-status.remaining)),
                      key: const Key('plan_over_budget'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      key: const Key('plan_exclusions_button'),
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => const _ExclusionsSheet(),
                      ),
                      icon: const Icon(Icons.block_rounded),
                      label: Text(
                        settings.excludedIngredientIds.isEmpty
                            ? l10n.planExclusions
                            : l10n.planExclusionsCount(
                                settings.excludedIngredientIds.length,
                              ),
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('plan_set_budget'),
                      onPressed: () => editWeeklyBudget(context, budget),
                      icon: const Icon(Icons.savings_outlined),
                      label: Text(
                        budget == null ? l10n.budgetSet : l10n.budgetEdit,
                      ),
                    ),
                  ],
                ),
                if (withStore.isEmpty)
                  TextButton.icon(
                    key: const Key('plan_find_store'),
                    onPressed: () => context.push('/stores'),
                    icon: const Icon(Icons.storefront_outlined),
                    label: Text(l10n.planNoStore),
                  )
                else ...[
                  Text(l10n.planSupermarket, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final r in withStore)
                        ChoiceChip(
                          key: Key('plan_chain_${r.chainId}'),
                          label: Text(
                            _chainName(view.snapshot.chains, r, isHebrew),
                          ),
                          selected: r.chainId == chosen?.chainId,
                          onSelected: (_) => settings.setPlanChain(r.chainId),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const Key('plan_build_button'),
                      onPressed: recipes.isEmpty ? null : () => generate(),
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(hasPlan ? l10n.planRebuild : l10n.planBuild),
                    ),
                    if (hasPlan)
                      OutlinedButton.icon(
                        key: const Key('plan_add_to_list'),
                        onPressed: summary.shoppingIds.isEmpty
                            ? null
                            : addToList,
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: Text(l10n.planAddToList),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (plan.isNotEmpty)
            for (var i = 0; i < _days; i++)
              _DayCard(
                key: Key('plan_day_$i'),
                index: i,
                label: dayLabel(i),
                recipe: i < plan.length && plan[i] != null
                    ? byId[plan[i]]
                    : null,
                skipped: i < plan.length && plan[i] == kSkippedDay,
                cost: dayCost[i],
                hero: i == 0,
                onSwap: () => generate(base: padded(), days: {i}),
                onSkip: () async {
                  final next = padded();
                  if (plan[i] == kSkippedDay) {
                    next[i] = null;
                    await generate(base: next, days: {i});
                  } else {
                    next[i] = kSkippedDay;
                    await settings.setWeekPlan(next);
                  }
                },
                onHide: () async {
                  final id = plan[i];
                  if (id == null) return;
                  await settings.hideRecipe(id);
                  await generate(base: padded(), days: {i});
                },
              ),
        ],
      ),
    );
  }

  static String _chainName(
    List<PriceChain> chains,
    dynamic resolved,
    bool isHebrew,
  ) {
    final chain = chains.firstWhere((c) => c.id == resolved.chainId);
    return isHebrew ? chain.nameHe : chain.nameEn;
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    super.key,
    required this.index,
    required this.label,
    required this.recipe,
    required this.skipped,
    required this.cost,
    required this.hero,
    required this.onSwap,
    required this.onSkip,
    required this.onHide,
  });

  final int index;
  final String label;
  final Recipe? recipe;
  final bool skipped;
  final double? cost;
  final bool hero;
  final VoidCallback onSwap;
  final VoidCallback onSkip;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = currencyFormat(context);

    if (skipped || recipe == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          enableGlass: false,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleSmall),
                    Text(
                      skipped ? l10n.planSkippedDay : l10n.planEmptyDay,
                      key: Key(
                        skipped ? 'plan_skipped_$index' : 'plan_empty_$index',
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (skipped)
                IconButton(
                  key: Key('plan_skip_$index'),
                  tooltip: l10n.planUnskip,
                  icon: const Icon(Icons.undo_rounded),
                  onPressed: onSkip,
                )
              else
                IconButton(
                  key: Key('plan_swap_$index'),
                  tooltip: l10n.planSwap,
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: onSwap,
                ),
            ],
          ),
        ),
      );
    }

    final r = recipe!;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('plan_swap_$index'),
          tooltip: l10n.planSwap,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: onSwap,
        ),
        IconButton(
          key: Key('plan_skip_$index'),
          tooltip: l10n.planSkip,
          icon: const Icon(Icons.event_busy_outlined),
          onPressed: onSkip,
        ),
        IconButton(
          key: Key('plan_hide_$index'),
          tooltip: l10n.planHide,
          icon: const Icon(Icons.visibility_off_outlined),
          onPressed: onHide,
        ),
      ],
    );
    final meta = Wrap(
      spacing: 12,
      children: [
        Text(l10n.minutesShort(r.totalMinutes)),
        if (cost != null && cost! > 0)
          Text(
            l10n.buyCost(money.format(cost)),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        enableGlass: false,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/recipe/${r.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: hero
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RecipePhotoView(
                        photo: r.photo,
                        filePath: r.imagePath,
                        width: double.infinity,
                        height: 180,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        recipeTitle(context, r),
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      meta,
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton(
                            key: const Key('plan_cook_button'),
                            onPressed: () => context.push('/cook/${r.id}'),
                            child: Text(l10n.planCook),
                          ),
                          const Spacer(),
                          actions,
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      RecipePhotoView(
                        photo: r.photo,
                        filePath: r.imagePath,
                        width: 72,
                        height: 72,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: theme.textTheme.labelMedium),
                            Text(
                              recipeTitle(context, r),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                            meta,
                          ],
                        ),
                      ),
                      actions,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Pick ingredients the weekly menu should never use. Chips show what is excluded; delete one to allow it again.
class _ExclusionsSheet extends StatefulWidget {
  const _ExclusionsSheet();

  @override
  State<_ExclusionsSheet> createState() => _ExclusionsSheetState();
}

class _ExclusionsSheetState extends State<_ExclusionsSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = context.watch<IngredientCatalog>();
    final settings = context.watch<SettingsRepository>();
    final excluded = settings.excludedIngredientIds;
    final text = _query.text.trim();
    final matches = text.isEmpty
        ? const <Ingredient>[]
        : catalog.search(text, limit: 8);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.planExclusions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (excluded.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final id in excluded)
                  InputChip(
                    key: Key('exclude_chip_$id'),
                    label: Text(ingredientLabel(context, catalog, id)),
                    onDeleted: () => settings.toggleExcludedIngredient(id),
                  ),
              ],
            ),
          TextField(
            key: const Key('exclude_search'),
            controller: _query,
            decoration: InputDecoration(hintText: l10n.planExclusionsHint),
            onChanged: (_) => setState(() {}),
          ),
          for (final m in matches)
            if (!excluded.contains(m.id))
              ListTile(
                key: Key('exclude_pick_${m.id}'),
                dense: true,
                title: Text(ingredientLabel(context, catalog, m.id)),
                onTap: () {
                  settings.toggleExcludedIngredient(m.id);
                  _query.clear();
                  setState(() {});
                },
              ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              key: const Key('exclude_done'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.planExclusionsDone),
            ),
          ),
        ],
      ),
    );
  }
}
