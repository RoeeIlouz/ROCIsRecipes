import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/prices/budget.dart';
import 'package:rocis_recipes/features/prices/ui/price_summary.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';
import 'package:rocis_recipes/shared/ui/widgets/glass_container.dart';

/// How much of the weekly budget the shopping list uses at the cheapest chain, with a way to set it.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key});

  Future<void> _edit(BuildContext context, int? current) async {
    final settings = context.read<SettingsRepository>();
    final result = await showDialog<_BudgetEdit>(
      context: context,
      builder: (_) => _BudgetDialog(current: current),
    );
    if (result == null) return;
    await settings.setWeeklyBudget(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final budget = context.watch<SettingsRepository>().weeklyBudget;
    final money = currencyFormat(context);

    if (budget == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('budget_edit_button'),
            onPressed: () => _edit(context, null),
            icon: const Icon(Icons.savings_outlined),
            label: Text(l10n.budgetSet),
          ),
        ),
      );
    }

    final spent = PriceViewData.of(context).cheapest?.total ?? 0.0;
    final status = BudgetStatus(budget: budget.toDouble(), spent: spent);
    final color = status.isOver
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        key: const Key('budget_card'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.budgetTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('budget_edit_button'),
                  tooltip: l10n.budgetEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context, budget),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: status.fraction,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.budgetUsed(money.format(spent), money.format(budget)),
              style: theme.textTheme.bodyMedium,
            ),
            if (status.isOver)
              Text(
                l10n.budgetOver(money.format(-status.remaining)),
                key: const Key('budget_over'),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              )
            else
              Text(
                l10n.budgetLeft(money.format(status.remaining)),
                key: const Key('budget_remaining'),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}

/// The dialog's answer: a new budget, or null to remove it.
class _BudgetEdit {
  const _BudgetEdit(this.value);
  final int? value;
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.current});

  final int? current;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final _field = TextEditingController(
    text: widget.current == null ? '' : '${widget.current}',
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.budgetTitle),
      content: TextField(
        key: const Key('budget_field'),
        controller: _field,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: l10n.budgetFieldLabel),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            key: const Key('budget_clear'),
            onPressed: () => Navigator.of(context).pop(const _BudgetEdit(null)),
            child: Text(l10n.budgetClear),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('budget_save'),
          onPressed: _save,
          child: Text(l10n.budgetSave),
        ),
      ],
    );
  }

  void _save() {
    final value = int.tryParse(_field.text.trim());
    if (value == null || value <= 0) return;
    Navigator.of(context).pop(_BudgetEdit(value));
  }
}
