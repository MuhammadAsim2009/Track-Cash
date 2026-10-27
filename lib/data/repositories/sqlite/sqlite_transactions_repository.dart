import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../fake/fake_seed_data.dart';
import '../../local/app_database.dart';
import '../../models/transaction_entry.dart';
import '../transactions_repository.dart';

/// SQLite implementation of [TransactionsRepository].
class SqliteTransactionsRepository implements TransactionsRepository {
  SqliteTransactionsRepository({
    AppDatabase? db,
    String userId = kDemoUserId,
    void Function()? onDataChanged,
  })  : _db = db ?? AppDatabase.instance,
        _userId = userId,
        _onDataChanged = onDataChanged;

  final AppDatabase _db;
  final String _userId;
  final void Function()? _onDataChanged;
  final _changeController = StreamController<void>.broadcast();

  void notifyListeners() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
    _onDataChanged?.call();
  }

  @override
  Future<List<TransactionEntry>> getTransactions({
    String? walletId,
    String? categoryId,
    TransactionType? type,
    String? monthKey,
  }) async {
    final db = await _db.database;

    final whereClauses = <String>['user_id = ?', 'is_deleted = 0'];
    final whereArgs = <dynamic>[_userId];

    if (walletId != null) {
      whereClauses.add('wallet_id = ?');
      whereArgs.add(walletId);
    }

    if (categoryId != null) {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }

    if (monthKey != null) {
      whereClauses.add('date LIKE ?');
      whereArgs.add('$monthKey%');
    }

    final maps = await db.query(
      'transactions',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map(TransactionEntry.fromMap).toList();
  }

  @override
  Stream<List<TransactionEntry>> watchTransactions() async* {
    yield await getTransactions();
    yield* _changeController.stream.asyncMap((_) => getTransactions());
  }

  @override
  Future<TransactionEntry?> getTransactionById(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransactionEntry.fromMap(maps.first);
  }

  @override
  Future<List<TransactionEntry>> getRecentTransactions({int limit = 5}) async {
    final db = await _db.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [_userId],
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
    );
    return maps.map(TransactionEntry.fromMap).toList();
  }

  @override
  Future<void> addTransaction(TransactionEntry transaction) async {
    final db = await _db.database;
    await db.insert('transactions', transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
  }

  @override
  Future<void> updateTransaction(TransactionEntry transaction) async {
    final db = await _db.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    notifyListeners();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _db.database;
    await db.update(
      'transactions',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  @override
  Future<int> getTotalExpenseForMonth(String monthKey) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      INNER JOIN wallets w ON w.id = t.wallet_id
      WHERE t.user_id = ? AND t.type = 'expense' AND t.is_deleted = 0
        AND t.date LIKE ?
        AND NOT (w.type = 'savings' AND w.count_in_daily_expense = 0)
    ''', [_userId, '$monthKey%']);
    return (result.first['total'] as num).toInt();
  }

  @override
  Future<int> getTotalIncomeForMonth(String monthKey) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      INNER JOIN wallets w ON w.id = t.wallet_id
      WHERE t.user_id = ? AND t.type = 'income' AND t.is_deleted = 0
        AND t.date LIKE ?
        AND NOT (w.type = 'savings' AND w.count_in_daily_expense = 0)
    ''', [_userId, '$monthKey%']);
    return (result.first['total'] as num).toInt();
  }

  @override
  Future<int> getCategoryExpenseForMonth(
      String categoryId, String monthKey) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE user_id = ? AND type = 'expense' AND category_id = ? AND is_deleted = 0 AND date LIKE ?
    ''', [_userId, categoryId, '$monthKey%']);
    return (result.first['total'] as num).toInt();
  }
}
