import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../repositories/budgets_repository.dart';
import 'fake_seed_data.dart';

class FakeBudgetsRepository implements BudgetsRepository {
  FakeBudgetsRepository() {
    _budgets = List<Budget>.from(FakeSeedData.initialBudgets);
    _controller = StreamController<List<Budget>>.broadcast();
  }

  late final List<Budget> _budgets;
  late final StreamController<List<Budget>> _controller;
  static const _uuid = Uuid();

  List<Budget> get _active => _budgets.where((b) => !b.isDeleted).toList();

  void _notify() => _controller.add(List.unmodifiable(_active));

  @override
  Future<List<Budget>> getBudgetsForMonth(String monthKey) async {
    return _budgets.where((b) => b.month == monthKey && !b.isDeleted).toList();
  }

  @override
  Stream<List<Budget>> watchBudgetsForMonth(String monthKey) {
    return Stream.multi((controller) {
      controller.add(_active.where((b) => b.month == monthKey).toList());
      final sub = _controller.stream.map((list) {
        return list.where((b) => b.month == monthKey && !b.isDeleted).toList();
      }).listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<Budget?> getTotalBudgetForMonth(String monthKey) async {
    return _budgets
        .where((b) => b.month == monthKey && b.categoryId == null && !b.isDeleted)
        .firstOrNull;
  }

  @override
  Future<void> setBudget(Budget budget) async {
    final index = _budgets.indexWhere((b) =>
        b.month == budget.month &&
        b.categoryId == budget.categoryId &&
        !b.isDeleted);

    if (index != -1) {
      _budgets[index] = budget.copyWith(
        id: _budgets[index].id,
        updatedAt: DateTime.now(),
      );
    } else {
      _budgets.add(budget);
    }
    _notify();
  }

  @override
  Future<void> deleteBudget(String id) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      _budgets[index] = _budgets[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> copyBudgetsFromMonth({
    required String fromMonth,
    required String toMonth,
  }) async {
    final sourceBudgets = await getBudgetsForMonth(fromMonth);
    final now = DateTime.now();
    for (final src in sourceBudgets) {
      final copy = Budget(
        id: _uuid.v4(),
        userId: src.userId,
        month: toMonth,
        mode: src.mode,
        categoryId: src.categoryId,
        amount: src.amount,
        createdAt: now,
        updatedAt: now,
      );
      await setBudget(copy);
    }
    _notify();
  }
}
