import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/recipes/recipe_matcher.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_card.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recipes = context.watch<RecipeRepository>().all;
    final pantry = context.watch<PantryRepository>().ids;
    final settings = context.watch<SettingsRepository>();

    List<RecipeMatch> compute(MatchMode mode) => RecipeMatcher.match(
          recipes: recipes,
          pantryIds: pantry,
          stapleIds: settings.stapleIds,
          appliances: settings.appliances,
          maxMinutes: settings.maxMinutes,
          mode: mode,
        );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appName),
          bottom: TabBar(
            tabs: [
              Tab(key: const Key('tab_cook_now'), text: l10n.tabCookNow),
              Tab(key: const Key('tab_almost_there'), text: l10n.tabAlmostThere),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MatchList(matches: compute(MatchMode.cookNow)),
            _MatchList(matches: compute(MatchMode.almostThere)),
          ],
        ),
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.matches});

  final List<RecipeMatch> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(AppLocalizations.of(context).noMatches, textAlign: TextAlign.center),
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
          onTap: () => context.push('/recipe/${m.recipe.id}'),
        );
      },
    );
  }
}
