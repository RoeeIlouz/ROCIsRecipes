import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/ai/ai_ui.dart';
import 'package:rocis_recipes/features/home/tonight.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/plan/week_planner.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/recipe_filters.dart';
import 'package:rocis_recipes/features/recipes/recipe_matcher.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_card.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_format.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_photo.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

const _shelfSize = 12;

/// The first screen: a greeting, tonight's dinner as a big card, shortcuts, and shelves of dishes
/// (what can be cooked now, meal prep, chicken, beef, favorites) to browse by picture.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<SettingsRepository>();
    final recipes = context.watch<RecipeRepository>().all;
    final pantry = context.watch<PantryRepository>().ids;
    final now = DateTime.now();

    final tonight = pickTonight(
      recipes: recipes,
      plan: settings.weekPlan,
      planStart: settings.planStart,
      now: now,
      pantryIds: pantry,
      stapleIds: settings.stapleIds,
      maxMinutes: settings.maxMinutes,
      appliances: settings.appliances,
    );

    List<RecipeMatch> match(MatchMode mode) => RecipeMatcher.match(
      recipes: recipes,
      pantryIds: pantry,
      stapleIds: settings.stapleIds,
      appliances: settings.appliances,
      maxMinutes: settings.maxMinutes,
      mode: mode,
    );
    final cookNow = match(MatchMode.cookNow);
    final almost = match(MatchMode.almostThere);

    // The same dishes should not head every shelf every day: shuffle by the date.
    final rng = Random(
      now.year * 1000 + now.difference(DateTime(now.year)).inDays,
    );
    // Dishes with a picture lead each shelf: this is a screen to browse by photo.
    List<Recipe> daily(Iterable<Recipe> source) {
      final shuffled = [...source]..shuffle(rng);
      return [
        ...shuffled.where((r) => r.photo != null || r.imagePath != null),
        ...shuffled.where((r) => r.photo == null && r.imagePath == null),
      ].take(_shelfSize).toList();
    }

    final mains = [
      for (final r in recipes)
        if (kPlanMealTypes.contains(r.mealType)) r,
    ];
    final mealPrep = daily(mains.where((r) => r.mealPrep));
    final chicken = daily(mains.where((r) => recipeKind(r) == 'chicken'));
    final beef = daily(mains.where((r) => recipeKind(r) == 'beef'));
    final favorites = [
      for (final r in recipes)
        if (settings.favoriteIds.contains(r.id)) r,
    ].take(_shelfSize).toList();

    final greeting = switch (greetingFor(now.hour)) {
      Greeting.morning => l10n.homeGreetingMorning,
      Greeting.afternoon => l10n.homeGreetingAfternoon,
      Greeting.evening => l10n.homeGreetingEvening,
      Greeting.night => l10n.homeGreetingNight,
    };

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 12,
          bottom: 24,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        key: const Key('home_greeting'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.homeSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('home_ai_button'),
                  tooltip: l10n.aiInventTooltip,
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () => inventFromPantry(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (tonight != null)
            _Hero(tonight: tonight)
          else
            const _EmptyKitchen(),
          const SizedBox(height: 16),
          const _QuickActions(),
          const SizedBox(height: 8),
          _Shelf(
            id: 'cook_now',
            title: l10n.homeShelfCookNow,
            recipes: [for (final m in cookNow.take(_shelfSize)) m.recipe],
          ),
          _Shelf(
            id: 'almost',
            title: l10n.homeShelfAlmost,
            recipes: [for (final m in almost.take(_shelfSize)) m.recipe],
            missing: {
              for (final m in almost)
                m.recipe.id: m.missingIngredientIds.length,
            },
          ),
          _Shelf(
            id: 'meal_prep',
            title: l10n.homeShelfMealPrep,
            recipes: mealPrep,
          ),
          _Shelf(id: 'chicken', title: l10n.homeShelfChicken, recipes: chicken),
          _Shelf(id: 'beef', title: l10n.homeShelfBeef, recipes: beef),
          _Shelf(
            id: 'favorites',
            title: l10n.homeShelfFavorites,
            recipes: favorites,
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.tonight});

  final Tonight tonight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = tonight.recipe;
    final reason = switch (tonight.reason) {
      TonightReason.plan => l10n.homeFromPlan,
      TonightReason.cookNow => l10n.homeCookNowHint,
      TonightReason.almost => l10n.homeAlmostHint(tonight.missing),
    };
    return Padding(
      key: const Key('home_hero'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: () => context.push('/recipe/${r.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    RecipePhotoView(
                      photo: r.photo,
                      filePath: r.imagePath,
                      kind: recipeKind(r),
                      width: double.infinity,
                      height: 250,
                      borderRadius: BorderRadius.zero,
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.4, 1.0],
                            colors: [Colors.transparent, Color(0xE6000000)],
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 14,
                      start: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            reason,
                            key: const Key('home_hero_reason'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 16,
                      end: 16,
                      bottom: 14,
                      child: Text(
                        recipeTitle(context, r),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(l10n.minutesShort(r.totalMinutes)),
                      const Spacer(),
                      TextButton(
                        key: const Key('home_details'),
                        onPressed: () => context.push('/recipe/${r.id}'),
                        child: Text(l10n.homeDetails),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        key: const Key('home_cook'),
                        onPressed: () => context.push('/cook/${r.id}'),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l10n.homeLetsCook),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyKitchen extends StatelessWidget {
  const _EmptyKitchen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      key: const Key('home_empty'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.kitchen_rounded,
                size: 36,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 10),
              Text(l10n.homeEmptyTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(l10n.homeEmptyBody),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('home_empty_action'),
                onPressed: () => context.go('/pantry'),
                child: Text(l10n.homeEmptyAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _Action(
            keyName: 'plan',
            icon: Icons.calendar_month_rounded,
            label: l10n.homeActionPlan,
            onTap: () => context.go('/plan'),
          ),
          const SizedBox(width: 10),
          _Action(
            keyName: 'shopping',
            icon: Icons.shopping_cart_rounded,
            label: l10n.homeActionShopping,
            onTap: () => context.go('/shopping'),
          ),
          const SizedBox(width: 10),
          _Action(
            keyName: 'kitchen',
            icon: Icons.kitchen_rounded,
            label: l10n.homeActionKitchen,
            onTap: () => context.go('/pantry'),
          ),
          const SizedBox(width: 10),
          _Action(
            keyName: 'stores',
            icon: Icons.storefront_outlined,
            label: l10n.homeActionStores,
            onTap: () => context.push('/stores'),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        key: Key('home_action_$keyName'),
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.secondary.withValues(
                    alpha: 0.16,
                  ),
                  child: Icon(icon, color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.id,
    required this.title,
    required this.recipes,
    this.missing = const {},
  });

  final String id;
  final String title;
  final List<Recipe> recipes;
  final Map<String, int> missing;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      key: Key('home_shelf_$id'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                key: Key('home_see_all_$id'),
                onPressed: () => context.go('/suggestions'),
                child: Text(l10n.homeSeeAll),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recipes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _Tile(
              keyName: '${id}_${recipes[i].id}',
              recipe: recipes[i],
              missing: missing[recipes[i].id],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.keyName, required this.recipe, this.missing});

  final String keyName;
  final Recipe recipe;
  final int? missing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      key: Key('home_tile_$keyName'),
      width: 164,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/recipe/${recipe.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipePhotoView(
              photo: recipe.photo,
              filePath: recipe.imagePath,
              kind: recipeKind(recipe),
              width: 164,
              height: 116,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 8),
            Text(
              recipeTitle(context, recipe),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l10n.minutesShort(recipe.totalMinutes),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                if (missing != null && missing! > 0)
                  Text(
                    l10n.missingCount(missing!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
