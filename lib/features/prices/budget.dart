/// How much of a weekly food budget a shopping list uses.
class BudgetStatus {
  const BudgetStatus({required this.budget, required this.spent});

  final double budget;
  final double spent;

  double get remaining => budget - spent;

  /// Share of the budget used, from 0 to 1 (a progress bar never goes past full).
  double get fraction => budget <= 0 ? 1.0 : (spent / budget).clamp(0.0, 1.0);

  bool get isOver => spent > budget;
}
