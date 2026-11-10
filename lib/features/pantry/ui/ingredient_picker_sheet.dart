import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/catalog/ingredient.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/catalog/ingredient_icons.dart';
import 'package:rocis_recipes/features/catalog/ingredient_label.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

/// Opens the ingredient gallery as a bottom sheet. Tapping a tile adds or removes the
/// ingredient straight away, so several can be picked before closing.
Future<void> showIngredientPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    builder: (_) => const IngredientPickerSheet(),
  );
}

String categoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'produce' => l10n.catProduce,
      'dairy' => l10n.catDairy,
      'meat' => l10n.catMeat,
      'grains' => l10n.catGrains,
      'pantry' => l10n.catPantry,
      'spices' => l10n.catSpices,
      'snacks' => l10n.catSnacks,
      _ => category,
    };

class IngredientPickerSheet extends StatefulWidget {
  const IngredientPickerSheet({super.key});

  @override
  State<IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<IngredientPickerSheet> {
  final _search = TextEditingController();
  String? _category; // null means all

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Ingredient> _visible(IngredientCatalog catalog, BuildContext context) {
    final query = _search.text;
    var items = query.trim().isEmpty
        ? [...catalog.all]
        : catalog.search(query, limit: 1000);
    if (_category != null)
      items = items.where((i) => i.category == _category).toList();
    final isHebrew = Localizations.localeOf(context).languageCode == 'he';
    String name(Ingredient i) =>
        (isHebrew || i.nameEn.isEmpty) ? i.nameHe : i.nameEn;
    items.sort((a, b) => name(a).compareTo(name(b)));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final catalog = context.watch<IngredientCatalog>();
    final pantry = context.watch<PantryRepository>();
    final selected = pantry.ids;
    final items = _visible(catalog, context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.pickerTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  key: const Key('picker_close'),
                  tooltip: l10n.closeLabel,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              key: const Key('picker_search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.pickerSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  key: const Key('picker_cat_all'),
                  label: l10n.categoryAll,
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in kIngredientCategories)
                  _CategoryChip(
                    key: Key('picker_cat_$c'),
                    label: '${kCategoryEmoji[c]} ${categoryLabel(l10n, c)}',
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      l10n.pickerEmpty,
                      key: const Key('picker_empty'),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 104,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.86,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final ing = items[i];
                      final isSelected = selected.contains(ing.id);
                      return _IngredientTile(
                        ingredient: ing,
                        label: ingredientLabel(context, catalog, ing.id),
                        selected: isSelected,
                        onTap: () => isSelected
                            ? pantry.remove(ing.id)
                            : pantry.upsert(PantryItem(ingredientId: ing.id)),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('picker_done'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    selected.isEmpty
                        ? l10n.pickerDone
                        : '${l10n.pickerDone} (${selected.length})',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    required this.ingredient,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Ingredient ingredient;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: Key('picker_tile_${ingredient.id}'),
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ingredientEmoji(ingredient.id, ingredient.category),
                    style: const TextStyle(fontSize: 34),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected)
              PositionedDirectional(
                top: 6,
                end: 6,
                child: Icon(
                  Icons.check_circle_rounded,
                  key: Key('picker_selected_${ingredient.id}'),
                  size: 20,
                  color: scheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
