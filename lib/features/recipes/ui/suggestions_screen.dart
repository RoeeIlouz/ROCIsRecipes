import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/ai/ai_ui.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/prices/recipe_cost.dart';
import 'package:rocis_recipes/features/prices/ui/price_summary.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_filters.dart';
import 'package:rocis_recipes/features/recipes/recipe_matcher.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_card.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_format.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  String? _meal; // null = all meals
  String? _protein; // null = any protein
  bool _mealPrep = false;
  bool _favoritesOnly = false;
  bool _inBudget = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsRepository>();
    final favorites = settings.favoriteIds;
    final recipes = context
        .watch<RecipeRepository>()
        .all
        .where(
          (r) =>
              matchesFilters(
                r,
                meal: _meal,
                protein: _protein,
                mealPrepOnly: _mealPrep,
              ) &&
              (!_favoritesOnly || favorites.contains(r.id)),
        )
        .toList();
    final pantry = context.watch<PantryRepository>().ids;

    final prices = PriceViewData.of(context);
    final money = currencyFormat(context);
    final budget = settings.weeklyBudget;
    // What is left of the weekly budget after the shopping list at the cheapest chain.
    final left = budget == null
        ? null
        : budget - (prices.cheapest?.total ?? 0.0);

    BuyCost? costOf(RecipeMatch m) =>
        estimateBuyCost(m.missingIngredientIds, prices.resolved);

    List<RecipeMatch> compute(MatchMode mode) {
      final matches = RecipeMatcher.match(
        recipes: recipes,
        pantryIds: pantry,
        stapleIds: settings.stapleIds,
        appliances: settings.appliances,
        maxMinutes: settings.maxMinutes,
        mode: mode,
      );
      if (!_inBudget || left == null) return matches;
      return [
        for (final m in matches)
          if ((costOf(m)?.total ?? 0) <= left) m,
      ];
    }

    String? labelOf(RecipeMatch m) {
      if (m.missingIngredientIds.isEmpty) return null;
      final cost = costOf(m);
      return cost == null ? null : l10n.buyCost(money.format(cost.total));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          key: const Key('add_recipe_fab'),
          tooltip: l10n.edNew,
          onPressed: () => context.push('/recipe-edit'),
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          title: Text(l10n.appName),
          actions: [
            IconButton(
              key: const Key('favorites_chip'),
              tooltip: l10n.favoritesChip,
              isSelected: _favoritesOnly,
              icon: const Icon(Icons.favorite_border),
              selectedIcon: const Icon(Icons.favorite),
              onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
            ),
            IconButton(
              key: const Key('ai_invent_button'),
              tooltip: l10n.aiInventTooltip,
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => inventFromPantry(context),
            ),
            IconButton(
              key: const Key('credits_button'),
              tooltip: l10n.creditsTitle,
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => context.push('/credits'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(key: const Key('tab_cook_now'), text: l10n.tabCookNow),
              Tab(
                key: const Key('tab_almost_there'),
                text: l10n.tabAlmostThere,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  _chip(const Key('meal_chip_all'), l10n.mealAll, null),
                  for (final t in kMealTypes)
                    _chip(Key('meal_chip_$t'), mealTypeLabel(l10n, t), t),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  _proteinChip(
                    const Key('protein_chip_all'),
                    l10n.proteinAll,
                    null,
                  ),
                  for (final k in kProteinKinds)
                    _proteinChip(
                      Key('protein_chip_$k'),
                      proteinLabel(l10n, k),
                      k,
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FilterChip(
                      key: const Key('meal_prep_chip'),
                      avatar: const Icon(Icons.kitchen_outlined, size: 18),
                      label: Text(l10n.mealPrepChip),
                      selected: _mealPrep,
                      onSelected: (v) => setState(() => _mealPrep = v),
                    ),
                  ),
                  if (budget != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: FilterChip(
                        key: const Key('budget_chip'),
                        avatar: const Icon(Icons.savings_outlined, size: 18),
                        label: Text(l10n.budgetChip),
                        selected: _inBudget,
                        onSelected: (v) => setState(() => _inBudget = v),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _MatchList(
                    matches: compute(MatchMode.cookNow),
                    labelOf: labelOf,
                  ),
                  _MatchList(
                    matches: compute(MatchMode.almostThere),
                    labelOf: labelOf,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proteinChip(Key key, String label, String? protein) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ChoiceChip(
      key: key,
      label: Text(label),
      selected: _protein == protein,
      onSelected: (_) => setState(() => _protein = protein),
    ),
  );

  Widget _chip(Key key, String label, String? meal) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ChoiceChip(
      key: key,
      label: Text(label),
      selected: _meal == meal,
      onSelected: (_) => setState(() => _meal = meal),
    ),
  );
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.matches, required this.labelOf});

  final List<RecipeMatch> matches;
  final String? Function(RecipeMatch) labelOf;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context).noMatches,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, i) {
        final m = matches[i];
        return RecipeCard(
          key: Key('recipe_card_${m.recipe.id}'),
          recipe: m.recipe,
          missingCount: m.missingIngredientIds.length,
          buyCostLabel: labelOf(m),
          onTap: () => context.push('/recipe/${m.recipe.id}'),
        );
      },
    );
  }
}
