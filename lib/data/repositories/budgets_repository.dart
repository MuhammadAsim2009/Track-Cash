import '../models/budget.dart';

/// Repository interface for monthly budgets.
abstract class BudgetsRepository {
  /// Returns all budget entries for a given month ("YYYY-MM").
  Future<List<Budget>> getBudgetsForMonth(String monthKey);

  /// Watches all budget entries for a given month ("YYYY-MM").
  Stream<List<Budget>> watchBudgetsForMonth(String monthKey);

  /// Returns the overall total monthly budget for a month, if configured.
  Future<Budget?> getTotalBudgetForMonth(String monthKey);

  /// Sets or updates a budget entry.
  Future<void> setBudget(Budget budget);

  /// Soft-deletes a budget entry.
  Future<void> deleteBudget(String id);

  /// Copies all budgets from [fromMonth] to [toMonth].
  Future<void> copyBudgetsFromMonth({
    required String fromMonth,
    required String toMonth,
  });
}
