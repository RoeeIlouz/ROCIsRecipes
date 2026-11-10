import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/catalog/ingredient.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/catalog/ingredient_label.dart';
import 'package:rocis_recipes/features/pantry/pantry_item.dart';
import 'package:rocis_recipes/features/pantry/pantry_repository.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/pantry/ui/appliance_picker.dart';
import 'package:rocis_recipes/features/pantry/ui/ingredient_picker_sheet.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';
import 'package:rocis_recipes/shared/ui/widgets/glass_container.dart';

const List<int> kTimeChoices = [15, 30, 45, 60, 90];

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addIngredient(Ingredient ing) async {
    final isCustom = ing.id.startsWith('custom:');
    if (ing.id == 'custom:') return;
    await context.read<PantryRepository>().upsert(
      PantryItem(ingredientId: ing.id, label: isCustom ? ing.nameHe : null),
    );
    if (!mounted) return;
    _controller.clear();
    setState(() {});
  }

  Future<void> _addTyped() async {
    final catalog = context.read<IngredientCatalog>();
    await _addIngredient(catalog.resolveOrCustom(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = context.watch<IngredientCatalog>();
    final pantry = context.watch<PantryRepository>();
    final settings = context.watch<SettingsRepository>();
    final suggestions = catalog.search(_controller.text);
    final items = pantry.items;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pantryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('pantry_input'),
            controller: _controller,
            decoration: InputDecoration(hintText: l10n.pantryInputHint),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _addTyped(),
          ),
          for (final s in suggestions)
            ListTile(
              key: Key('suggestion_${s.id}'),
              dense: true,
              title: Text(ingredientLabel(context, catalog, s.id)),
              onTap: () => _addIngredient(s),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                key: const Key('pantry_add_button'),
                onPressed: _addTyped,
                child: Text(l10n.addIngredient),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('pick_from_list_button'),
                onPressed: () => showIngredientPicker(context),
                child: Text(l10n.pickFromList),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.myIngredients,
            child: items.isEmpty
                ? Text(l10n.pantryEmpty)
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in items)
                        InputChip(
                          key: Key('pantry_chip_${item.ingredientId}'),
                          label: Text(
                            ingredientLabel(
                              context,
                              catalog,
                              item.ingredientId,
                              fallback: item.label,
                            ),
                          ),
                          onDeleted: () => pantry.remove(item.ingredientId),
                        ),
                    ],
                  ),
          ),
          _Section(
            title: l10n.appliancesTitle,
            child: AppliancePicker(
              selected: settings.appliances,
              onChanged: settings.setAppliances,
            ),
          ),
          _Section(
            title: l10n.cookingTimeTitle,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in kTimeChoices)
                  ChoiceChip(
                    key: Key('time_$m'),
                    label: Text(l10n.minutesShort(m)),
                    selected: settings.maxMinutes == m,
                    onSelected: (_) => settings.setMaxMinutes(m),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
