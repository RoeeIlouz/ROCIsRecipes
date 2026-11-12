import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/recipes/recipe_filters.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_format.dart';
import 'package:rocis_recipes/features/recipes/recipe.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_photo.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';
import 'package:rocis_recipes/shared/ui/widgets/glass_container.dart';

/// Recipe title in the current locale, falling back to Hebrew.
String recipeTitle(BuildContext context, Recipe recipe) {
  final isHebrew = Localizations.localeOf(context).languageCode == 'he';
  final en = recipe.titleEn;
  return (isHebrew || en == null || en.isEmpty) ? recipe.titleHe : en;
}

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.missingCount,
    this.buyCostLabel,
    this.onTap,
  });

  final Recipe recipe;
  final int missingCount;

  /// Estimated price of what is still to buy ("about 14 to buy"), when known.
  final String? buyCostLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final kind = recipeKind(recipe);
    final favorite = context.select<SettingsRepository, bool>(
      (s) => s.isFavorite(recipe.id),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // No backdrop blur here: a blur per list item is the most expensive thing to draw.
      child: GlassContainer(
        enableGlass: false,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                RecipePhotoView(
                  photo: recipe.photo,
                  filePath: recipe.imagePath,
                  kind: kind,
                  width: 96,
                  height: 96,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipeTitle(context, recipe),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Tag(
                            icon: Icons.schedule_rounded,
                            text: l10n.minutesShort(recipe.totalMinutes),
                          ),
                          _Tag(
                            key: Key('recipe_kind_${recipe.id}'),
                            icon: _kindIcon(kind),
                            text: kindLabel(l10n, kind),
                          ),
                          if (recipe.mealPrep)
                            _Tag(
                              key: Key('recipe_meal_prep_${recipe.id}'),
                              icon: Icons.kitchen_outlined,
                              text: l10n.mealPrepLabel,
                              highlight: true,
                            ),
                        ],
                      ),
                      if (missingCount > 0 || buyCostLabel != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (missingCount > 0)
                              Text(
                                l10n.missingCount(missingCount),
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            if (buyCostLabel != null)
                              Text(
                                buyCostLabel!,
                                key: Key('buy_cost_${recipe.id}'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (favorite)
                  Icon(
                    Icons.favorite,
                    key: Key('recipe_favorite_${recipe.id}'),
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _kindIcon(String kind) => switch (kind) {
  'chicken' => Icons.dinner_dining,
  'beef' => Icons.kebab_dining,
  'fish' => Icons.set_meal,
  'dessert' => Icons.bakery_dining,
  'breakfast' => Icons.free_breakfast,
  _ => Icons.eco,
};

/// A small rounded label: an icon and a short word.
class _Tag extends StatelessWidget {
  const _Tag({
    super.key,
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = highlight ? scheme.secondary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (highlight ? scheme.secondary : scheme.surfaceContainerHighest)
            .withValues(alpha: highlight ? 0.16 : 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
