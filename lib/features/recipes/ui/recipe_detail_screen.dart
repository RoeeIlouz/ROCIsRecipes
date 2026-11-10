import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/catalog/ingredient_label.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/recipes/recipe_repository.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_card.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_format.dart';
import 'package:rocis_recipes/features/recipes/ui/recipe_photo.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';
import 'package:rocis_recipes/features/shopping/shopping_repository.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.edDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('confirm_delete_recipe'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<RecipeRepository>().delete(id);
      if (context.mounted)
        context.canPop() ? context.pop() : context.go('/suggestions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recipe = context.watch<RecipeRepository>().byId(recipeId);
    if (recipe == null) return Scaffold(appBar: AppBar());

    final catalog = context.watch<IngredientCatalog>();
    final have = {
      ...context.watch<PantryRepository>().ids,
      ...context.watch<SettingsRepository>().stapleIds,
    };
    final missing = [
      for (final ing in recipe.ingredients)
        if (!ing.optional && !have.contains(ing.ingredientId)) ing,
    ];

    Future<void> addMissing() async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      await context.read<ShoppingRepository>().addMissing([
        for (final ing in missing)
          ShoppingItem(
            id: 'rec_${ing.ingredientId}_$stamp',
            ingredientId: ing.ingredientId,
            label: ingredientLabel(context, catalog, ing.ingredientId),
            quantity: ing.quantity,
            unit: ing.unit,
          ),
      ]);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.addedToList)));
      }
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          recipeTitle(context, recipe),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (recipe.isUserCreated) ...[
            IconButton(
              key: const Key('edit_recipe_button'),
              tooltip: l10n.edEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/recipe-edit?id=${recipe.id}'),
            ),
            IconButton(
              key: const Key('delete_recipe_button'),
              tooltip: l10n.edDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, recipe.id),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RecipePhotoView(
            photo: recipe.photo,
            filePath: recipe.imagePath,
            height: 220,
            borderRadius: BorderRadius.circular(24),
          ),
          if (recipe.photo != null) PhotoCredit(photo: recipe.photo!),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.schedule_rounded, size: 18),
                label: Text(l10n.minutesShort(recipe.totalMinutes)),
              ),
              Chip(
                avatar: const Icon(Icons.people_rounded, size: 18),
                label: Text(l10n.servingsCount(recipe.servings)),
              ),
              Chip(
                avatar: const Icon(Icons.signal_cellular_alt_rounded, size: 18),
                label: Text(difficultyLabel(l10n, recipe.difficulty)),
              ),
              Chip(
                avatar: const Icon(Icons.restaurant_menu_rounded, size: 18),
                label: Text(mealTypeLabel(l10n, recipe.mealType)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.ingredientsTitle, style: theme.textTheme.titleLarge),
          for (final ing in recipe.ingredients)
            _IngredientTile(
              key: Key(
                '${have.contains(ing.ingredientId) || ing.optional ? 'have' : 'missing'}_${ing.ingredientId}',
              ),
              label: ingredientLabel(context, catalog, ing.ingredientId),
              isMissing: !ing.optional && !have.contains(ing.ingredientId),
              amount: formatIngredientAmount(l10n, ing),
              optional: ing.optional,
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const Key('start_cooking_button'),
                onPressed: () => context.push('/cook/${recipe.id}'),
                child: Text(l10n.startCooking),
              ),
              if (missing.isNotEmpty)
                OutlinedButton(
                  key: const Key('add_missing_button'),
                  onPressed: addMissing,
                  child: Text(l10n.addMissingToList),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.stepsTitle, style: theme.textTheme.titleLarge),
          for (var i = 0; i < recipe.steps.length; i++)
            ListTile(
              leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
              title: Text(
                _stepText(
                  context,
                  recipe.steps[i].textHe,
                  recipe.steps[i].textEn,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _stepText(BuildContext context, String he, String? en) {
  final isHebrew = Localizations.localeOf(context).languageCode == 'he';
  return (isHebrew || en == null || en.isEmpty) ? he : en;
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    super.key,
    required this.label,
    required this.isMissing,
    required this.amount,
    required this.optional,
  });

  final String label;
  final bool isMissing;
  final String amount;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(
        isMissing
            ? Icons.add_shopping_cart_rounded
            : Icons.check_circle_rounded,
        color: isMissing ? scheme.error : scheme.primary,
      ),
      title: Text(optional ? '$label (${l10n.optionalLabel})' : label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (amount.isNotEmpty) Text(amount),
          if (isMissing) ...[
            const SizedBox(width: 8),
            Text(l10n.missingBadge, style: TextStyle(color: scheme.error)),
          ],
        ],
      ),
    );
  }
}
