import 'dart:async';
import 'package:intl/intl.dart';
import '../models/transaction_entry.dart';
import '../repositories/transactions_repository.dart';
import 'fake_seed_data.dart';

class FakeTransactionsRepository implements TransactionsRepository {
  FakeTransactionsRepository() {
    _transactions = List<TransactionEntry>.from(FakeSeedData.initialTransactions);
    _controller = StreamController<List<TransactionEntry>>.broadcast();
  }

  late final List<TransactionEntry> _transactions;
  late final StreamController<List<TransactionEntry>> _controller;
  static final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');

  List<TransactionEntry> get _sorted =>
      _transactions.where((t) => !t.isDeleted).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  void _notify() => _controller.add(List.unmodifiable(_sorted));

  @override
  Future<List<TransactionEntry>> getTransactions({
    String? walletId,
    String? categoryId,
    TransactionType? type,
    String? monthKey,
  }) async {
    return _transactions.where((t) {
      if (t.isDeleted) return false;
      if (walletId != null && t.walletId != walletId) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (type != null && t.type != type) return false;
      if (monthKey != null && _monthKeyFormat.format(t.date) != monthKey) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Stream<List<TransactionEntry>> watchTransactions() {
    return Stream.multi((controller) {
      controller.add(List.unmodifiable(_sorted));
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<TransactionEntry?> getTransactionById(String id) async {
    return _transactions.where((t) => t.id == id && !t.isDeleted).firstOrNull;
  }

  @override
  Future<List<TransactionEntry>> getRecentTransactions({int limit = 5}) async {
    final active = _transactions.where((t) => !t.isDeleted).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return active.take(limit).toList();
  }

  @override
  Future<void> addTransaction(TransactionEntry transaction) async {
    _transactions.add(transaction);
    _notify();
  }

  @override
  Future<void> updateTransaction(TransactionEntry transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction.copyWith(updatedAt: DateTime.now());
      _notify();
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<int> getTotalExpenseForMonth(String monthKey) async {
    final monthExpenses = await getTransactions(
      type: TransactionType.expense,
      monthKey: monthKey,
    );
    int total = 0;
    for (final tx in monthExpenses) {
      total += tx.amount;
    }
    return total;
  }

  @override
  Future<int> getTotalIncomeForMonth(String monthKey) async {
    final monthIncome = await getTransactions(
      type: TransactionType.income,
      monthKey: monthKey,
    );
    int total = 0;
    for (final tx in monthIncome) {
      total += tx.amount;
    }
    return total;
  }

  @override
  Future<int> getCategoryExpenseForMonth(String categoryId, String monthKey) async {
    final catExpenses = await getTransactions(
      categoryId: categoryId,
      type: TransactionType.expense,
      monthKey: monthKey,
    );
    int total = 0;
    for (final tx in catExpenses) {
      total += tx.amount;
    }
    return total;
  }
}
