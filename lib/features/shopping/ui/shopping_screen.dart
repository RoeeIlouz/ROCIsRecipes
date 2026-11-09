import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/catalog/ingredient_catalog.dart';
import 'package:rocis_recipes/features/catalog/ingredient_label.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';
import 'package:rocis_recipes/features/shopping/shopping_repository.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final catalog = context.read<IngredientCatalog>();
    final repo = context.read<ShoppingRepository>();
    final known = catalog.resolve(text);
    await repo.addIfNew(ShoppingItem(
      id: 'man_${DateTime.now().microsecondsSinceEpoch}',
      ingredientId: known?.id,
      label: known == null ? text : ingredientLabel(context, catalog, known.id),
    ));
    if (!mounted) return;
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = context.watch<ShoppingRepository>();
    final items = repo.items;
    final open = items.where((e) => !e.checked).toList();
    final done = items.where((e) => e.checked).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shoppingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('shopping_input'),
                  controller: _controller,
                  decoration: InputDecoration(hintText: l10n.shoppingInputHint),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('shopping_add_button'),
                onPressed: _add,
                child: Text(l10n.addIngredient),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty) Text(l10n.shoppingEmpty),
          for (final item in open) ShoppingItemTile(item: item),
          if (done.isNotEmpty)
            Column(
              key: const Key('done_section'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(l10n.doneSection, style: Theme.of(context).textTheme.titleMedium),
                for (final item in done) ShoppingItemTile(item: item),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    key: const Key('clear_checked_button'),
                    onPressed: repo.clearChecked,
                    child: Text(l10n.clearChecked),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One shopping list row. [priceLabel] is shown only when a price is known
/// (prices arrive in a later plan).
class ShoppingItemTile extends StatelessWidget {
  ShoppingItemTile({super.key, required this.item, this.priceLabel}) : _tileKey = Key('shopping_item_${item.id}');

  final ShoppingItem item;
  final String? priceLabel;
  final Key _tileKey;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: _tileKey,
      value: item.checked,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (_) => context.read<ShoppingRepository>().toggle(item.id),
      title: Text(
        item.label,
        style: item.checked ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
      ),
      subtitle: priceLabel == null ? null : Text(priceLabel!),
    );
  }
}
