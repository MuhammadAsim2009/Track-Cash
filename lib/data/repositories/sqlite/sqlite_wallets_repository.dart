import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../fake/fake_seed_data.dart';
import '../../local/app_database.dart';
import '../../models/wallet.dart';
import '../../sync/firestore_sync_service.dart';
import '../wallets_repository.dart';

/// SQLite implementation of [WalletsRepository].
class SqliteWalletsRepository implements WalletsRepository {
  SqliteWalletsRepository({
    AppDatabase? db,
    String userId = kDemoUserId,
  })  : _db = db ?? AppDatabase.instance,
        _userId = userId,
        _sync = FirestoreSyncService(userId);

  final AppDatabase _db;
  final String _userId;
  final FirestoreSyncService _sync;
  final _changeController = StreamController<void>.broadcast();

  void notifyListeners() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  @override
  Future<List<Wallet>> getWallets() async {
    final db = await _db.database;
    final maps = await db.query(
      'wallets',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [_userId],
      orderBy: "CASE type WHEN 'cash' THEN 0 WHEN 'mobileWallet' THEN 1 ELSE 2 END ASC",
    );
    return maps.map(Wallet.fromMap).toList();
  }

  @override
  Stream<List<Wallet>> watchWallets() async* {
    yield await getWallets();
    yield* _changeController.stream.asyncMap((_) => getWallets());
  }

  @override
  Future<Wallet?> getWalletById(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      'wallets',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Wallet.fromMap(maps.first);
  }

  @override
  Future<int> getWalletBalance(String walletId) async {
    final db = await _db.database;

    final walletMaps = await db.query(
      'wallets',
      columns: ['opening_balance'],
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [walletId],
    );
    if (walletMaps.isEmpty) return 0;
    final opening = (walletMaps.first['opening_balance'] as num).toInt();

    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE wallet_id = ? AND type = 'income' AND is_deleted = 0
    ''', [walletId]);
    final income = (incomeResult.first['total'] as num).toInt();

    final expenseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE wallet_id = ? AND type = 'expense' AND is_deleted = 0
    ''', [walletId]);
    final expense = (expenseResult.first['total'] as num).toInt();

    final transfersInResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transfers
      WHERE to_wallet_id = ? AND is_deleted = 0
    ''', [walletId]);
    final transfersIn = (transfersInResult.first['total'] as num).toInt();

    final transfersOutResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transfers
      WHERE from_wallet_id = ? AND is_deleted = 0
    ''', [walletId]);
    final transfersOut = (transfersOutResult.first['total'] as num).toInt();

    // Udhaar:
    // "I have to take" (direction='take') = lent money out -> deducts from wallet
    final udhaarTakeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM udhaar
      WHERE wallet_id = ? AND direction = 'take' AND status = 'pending' AND is_deleted = 0
    ''', [walletId]);
    final udhaarTake = (udhaarTakeResult.first['total'] as num).toInt();

    // "I have to give" (direction='give') = borrowed money in -> adds to wallet
    final udhaarGiveResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM udhaar
      WHERE wallet_id = ? AND direction = 'give' AND status = 'pending' AND is_deleted = 0
    ''', [walletId]);
    final udhaarGive = (udhaarGiveResult.first['total'] as num).toInt();

    return opening + income - expense + transfersIn - transfersOut - udhaarTake + udhaarGive;
  }

  @override
  Future<int> getTotalBalance() async {
    final db = await _db.database;

    // Fetch only wallets that count towards the total balance.
    // Savings wallets with count_in_daily_expense = 0 are excluded.
    final walletMaps = await db.query(
      'wallets',
      columns: ['id'],
      where: "user_id = ? AND is_deleted = 0 "
          "AND NOT (type = 'savings' AND count_in_daily_expense = 0)",
      whereArgs: [_userId],
    );

    // Sum each wallet's individual balance (correctly accounts for transfers).
    // A plain opening+income-expense aggregate ignores transfers, which causes
    // wrong totals when savings is excluded (transfers between wallets don't cancel).
    int total = 0;
    for (final row in walletMaps) {
      final walletId = row['id'] as String;
      total += await getWalletBalance(walletId);
    }
    return total;
  }

  @override
  Future<void> createWallet(Wallet wallet) async {
    final db = await _db.database;
    await db.insert('wallets', wallet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
    unawaited(_sync.pushWallet(wallet));
  }

  @override
  Future<void> updateWallet(Wallet wallet) async {
    final db = await _db.database;
    await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
    notifyListeners();
    unawaited(_sync.pushWallet(wallet));
  }

  @override
  Future<void> deleteWallet(String id) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'wallets',
      {'is_deleted': 1, 'updated_at': now, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    // Fetch the soft-deleted row to push deletion to Firestore
    final db2 = await _db.database;
    final rows = await db2.query('wallets', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) unawaited(_sync.pushWallet(Wallet.fromMap(rows.first)));
  }
}

void unawaited(Future<void> future) {}
