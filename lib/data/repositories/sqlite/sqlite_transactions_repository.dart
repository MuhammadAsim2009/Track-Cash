import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../fake/fake_seed_data.dart';
import '../../local/app_database.dart';
import '../../models/transaction_entry.dart';
import '../../sync/firestore_sync_service.dart';
import '../transactions_repository.dart';

/// SQLite implementation of [TransactionsRepository].
class SqliteTransactionsRepository implements TransactionsRepository {
  SqliteTransactionsRepository({
    AppDatabase? db,
    String userId = kDemoUserId,
    void Function()? onDataChanged,
    void Function()? onTransfersChanged,
  })  : _db = db ?? AppDatabase.instance,
        _userId = userId,
        _onDataChanged = onDataChanged,
        _onTransfersChanged = onTransfersChanged,
        _sync = FirestoreSyncService(userId);

  final AppDatabase _db;
  final String _userId;
  final void Function()? _onDataChanged;
  final void Function()? _onTransfersChanged;
  final FirestoreSyncService _sync;
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
    unawaited(_sync.pushTransaction(transaction));
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
    unawaited(_sync.pushTransaction(transaction));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'transactions',
      {
        'is_deleted': 1,
        'updated_at': now,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    // Query without is_deleted filter to get the soft-deleted row for Firestore push
    final rows = await db.query('transactions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) unawaited(_sync.pushTransaction(TransactionEntry.fromMap(rows.first)));
  }

  @override
  Future<void> deleteIncomeAndRevertDependent(String id) async {
    final db = await _db.database;
    final nowIso = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Fetch the income transaction
      final txMaps = await txn.query(
        'transactions',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );
      if (txMaps.isEmpty) return;
      final tx = TransactionEntry.fromMap(txMaps.first);
      final walletId = tx.walletId;

      // 2. Soft-delete this income transaction
      await txn.update(
        'transactions',
        {'is_deleted': 1, 'updated_at': nowIso},
        where: 'id = ?',
        whereArgs: [id],
      );

      // 3. Helper to calculate any wallet's balance inside the transaction
      Future<int> computeWalletBalance(String wId) async {
        final wMaps = await txn.query(
          'wallets',
          columns: ['opening_balance'],
          where: 'id = ? AND is_deleted = 0',
          whereArgs: [wId],
        );
        final opening = wMaps.isNotEmpty
            ? (wMaps.first['opening_balance'] as num).toInt()
            : 0;

        final incRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(amount), 0) as total FROM transactions
          WHERE wallet_id = ? AND type = 'income' AND is_deleted = 0
        ''', [wId]);
        final inc = (incRes.first['total'] as num).toInt();

        final expRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(amount), 0) as total FROM transactions
          WHERE wallet_id = ? AND type = 'expense' AND is_deleted = 0
        ''', [wId]);
        final exp = (expRes.first['total'] as num).toInt();

        final tInRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(amount), 0) as total FROM transfers
          WHERE to_wallet_id = ? AND is_deleted = 0
        ''', [wId]);
        final tIn = (tInRes.first['total'] as num).toInt();

        final tOutRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(amount), 0) as total FROM transfers
          WHERE from_wallet_id = ? AND is_deleted = 0
        ''', [wId]);
        final tOut = (tOutRes.first['total'] as num).toInt();

        final uTakeRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(amount), 0) as total FROM udhaar
          WHERE wallet_id = ? AND direction = 'take' AND status = 'pending' AND is_deleted = 0
        ''', [wId]);
        final uTake = (uTakeRes.first['total'] as num).toInt();

        final uGiveRes = await txn.rawQuery('''
          SELECT COALESCE(SUM(amount), 0) as total FROM udhaar
          WHERE wallet_id = ? AND direction = 'give' AND status = 'pending' AND is_deleted = 0
        ''', [wId]);
        final uGive = (uGiveRes.first['total'] as num).toInt();

        return opening + inc - exp + tIn - tOut - uTake + uGive;
      }

      // 4. Resolve negative balances with cascading to affected wallets
      // When a transfer is reverted, the destination wallet loses that money and may become negative.
      final walletsToBalance = <String>{walletId};

      while (walletsToBalance.isNotEmpty) {
        final currentWId = walletsToBalance.first;
        walletsToBalance.remove(currentWId);

        int currentBal = await computeWalletBalance(currentWId);
        if (currentBal >= 0) continue;

        // A. Revert outgoing transfers from this wallet (LIFO)
        final outTransfers = await txn.query(
          'transfers',
          where: 'from_wallet_id = ? AND is_deleted = 0',
          whereArgs: [currentWId],
          orderBy: 'date DESC, created_at DESC',
        );

        for (final row in outTransfers) {
          if (currentBal >= 0) break;
          final transferId = row['id'] as String;
          final toWalletId = row['to_wallet_id'] as String;

          await txn.update(
            'transfers',
            {'is_deleted': 1, 'updated_at': nowIso},
            where: 'id = ?',
            whereArgs: [transferId],
          );

          // Destination wallet lost incoming transfer, check if it needs re-balancing
          walletsToBalance.add(toWalletId);
          currentBal = await computeWalletBalance(currentWId);
        }

        // B. If still negative, revert outgoing expenses on this wallet (LIFO)
        if (currentBal < 0) {
          final expenses = await txn.query(
            'transactions',
            where: "wallet_id = ? AND type = 'expense' AND is_deleted = 0",
            whereArgs: [currentWId],
            orderBy: 'date DESC, created_at DESC',
          );

          for (final row in expenses) {
            if (currentBal >= 0) break;
            final expId = row['id'] as String;
            await txn.update(
              'transactions',
              {'is_deleted': 1, 'updated_at': nowIso},
              where: 'id = ?',
              whereArgs: [expId],
            );
            currentBal = await computeWalletBalance(currentWId);
          }
        }
      }
    });

    notifyListeners();
    _onTransfersChanged?.call();
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

void unawaited(Future<void> future) {}
