import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../fake/fake_seed_data.dart';
import '../../local/app_database.dart';
import '../../models/budget.dart';
import '../../sync/firestore_sync_service.dart';
import '../budgets_repository.dart';

/// SQLite implementation of [BudgetsRepository].
class SqliteBudgetsRepository implements BudgetsRepository {
  SqliteBudgetsRepository({
    AppDatabase? db,
    String userId = kDemoUserId,
  })  : _db = db ?? AppDatabase.instance,
        _userId = userId,
        _sync = FirestoreSyncService(userId);

  final AppDatabase _db;
  final String _userId;
  final FirestoreSyncService _sync;
  final _changeController = StreamController<void>.broadcast();
  static const _uuid = Uuid();

  void notifyListeners() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  @override
  Future<List<Budget>> getBudgetsForMonth(String monthKey) async {
    final db = await _db.database;
    final maps = await db.query(
      'budgets',
      where: 'user_id = ? AND month = ? AND is_deleted = 0',
      whereArgs: [_userId, monthKey],
      orderBy: 'created_at ASC',
    );
    return maps.map(Budget.fromMap).toList();
  }

  @override
  Stream<List<Budget>> watchBudgetsForMonth(String monthKey) async* {
    yield await getBudgetsForMonth(monthKey);
    yield* _changeController.stream
        .asyncMap((_) => getBudgetsForMonth(monthKey));
  }

  @override
  Future<Budget?> getTotalBudgetForMonth(String monthKey) async {
    final db = await _db.database;
    final maps = await db.query(
      'budgets',
      where:
          'user_id = ? AND month = ? AND category_id IS NULL AND is_deleted = 0',
      whereArgs: [_userId, monthKey],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  @override
  Future<void> setBudget(Budget budget) async {
    final db = await _db.database;

    // Check if an entry already exists for this month + category
    String where = 'user_id = ? AND month = ? AND is_deleted = 0 AND ';
    List<dynamic> whereArgs = [_userId, budget.month];
    if (budget.categoryId == null) {
      where += 'category_id IS NULL';
    } else {
      where += 'category_id = ?';
      whereArgs.add(budget.categoryId);
    }

    final existing = await db.query('budgets', where: where, whereArgs: whereArgs);

    final toSaveId = existing.isNotEmpty ? (existing.first['id'] as String) : budget.id;
    final budgetToSave = budget.copyWith(
      id: toSaveId,
      updatedAt: DateTime.now(),
      synced: false,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'budgets',
        budgetToSave.toMap(),
        where: 'id = ?',
        whereArgs: [toSaveId],
      );
    } else {
      await db.insert('budgets', budgetToSave.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    notifyListeners();
    // Push the EXACT budget that was upserted (overall or category budget)
    unawaited(_sync.pushBudget(budgetToSave));
  }

  @override
  Future<void> deleteBudget(String id) async {
    final db = await _db.database;
    await db.update(
      'budgets',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    // Fetch the soft-deleted row to push its isDeleted=true state
    final rows = await db.query('budgets', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) {
      final b = Budget.fromMap(rows.first);
      unawaited(_sync.pushBudget(b));
    }
  }

  @override
  Future<void> copyBudgetsFromMonth({
    required String fromMonth,
    required String toMonth,
  }) async {
    final source = await getBudgetsForMonth(fromMonth);
    if (source.isEmpty) return;

    final now = DateTime.now();
    for (final b in source) {
      final newBudget = Budget(
        id: _uuid.v4(),
        userId: _userId,
        month: toMonth,
        mode: b.mode,
        categoryId: b.categoryId,
        amount: b.amount,
        createdAt: now,
        updatedAt: now,
      );
      await setBudget(newBudget);
    }
    notifyListeners();
  }
}

void unawaited(Future<void> future) {}
