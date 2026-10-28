import '../models/transaction_entry.dart';

/// Repository interface for Transactions (Income & Expense).
abstract class TransactionsRepository {
  /// Returns transactions matching optional filters.
  Future<List<TransactionEntry>> getTransactions({
    String? walletId,
    String? categoryId,
    TransactionType? type,
    String? monthKey, // e.g. "2026-10"
  });

  /// Watches all transactions as a stream.
  Stream<List<TransactionEntry>> watchTransactions();

  /// Gets a single transaction by ID.
  Future<TransactionEntry?> getTransactionById(String id);

  /// Returns recent transactions (e.g. limit 5 for dashboard).
  Future<List<TransactionEntry>> getRecentTransactions({int limit = 5});

  /// Adds a new transaction.
  Future<void> addTransaction(TransactionEntry transaction);

  /// Updates an existing transaction.
  Future<void> updateTransaction(TransactionEntry transaction);

  /// Soft-deletes a transaction.
  Future<void> deleteTransaction(String id);

  /// Deletes an income transaction and reverts any dependent outgoing
  /// transfers and expenses on that wallet so the wallet balance does not become negative.
  Future<void> deleteIncomeAndRevertDependent(String id);

  /// Calculates total expense for a specific month (e.g. "2026-10") in rupees.
  Future<int> getTotalExpenseForMonth(String monthKey);

  /// Calculates total income for a specific month (e.g. "2026-10") in rupees.
  Future<int> getTotalIncomeForMonth(String monthKey);

  /// Calculates total expense for a specific category in a month in rupees.
  Future<int> getCategoryExpenseForMonth(String categoryId, String monthKey);
}
