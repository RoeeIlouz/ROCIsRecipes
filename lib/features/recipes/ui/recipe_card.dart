import 'package:flutter/material.dart';
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
    this.onTap,
  });

  final Recipe recipe;
  final int missingCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // No backdrop blur here: a blur per list item is the most expensive thing to draw.
      child: GlassContainer(
        enableGlass: false,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                RecipePhotoView(
                  photo: recipe.photo,
                  filePath: recipe.imagePath,
                  width: 84,
                  height: 84,
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
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        children: [
                          Text(l10n.minutesShort(recipe.totalMinutes)),
                          if (missingCount > 0)
                            Text(
                              l10n.missingCount(missingCount),
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                        ],
                      ),
                    ],
                  ),
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
