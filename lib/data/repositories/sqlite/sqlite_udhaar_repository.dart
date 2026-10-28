import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../fake/fake_seed_data.dart';
import '../../local/app_database.dart';
import '../../models/transfer.dart';
import '../../models/udhaar.dart';
import '../../sync/firestore_sync_service.dart';
import '../udhaar_repository.dart';

/// SQLite implementation of [UdhaarRepository].
class SqliteUdhaarRepository implements UdhaarRepository {
  SqliteUdhaarRepository({
    AppDatabase? db,
    String userId = kDemoUserId,
    void Function()? onDataChanged,
  })  : _db = db ?? AppDatabase.instance,
        _userId = userId,
        _onDataChanged = onDataChanged,
        _sync = FirestoreSyncService(userId);

  final AppDatabase _db;
  final String _userId;
  final void Function()? _onDataChanged;
  final FirestoreSyncService _sync;
  final _changeController = StreamController<void>.broadcast();

  void notifyListeners() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
    _onDataChanged?.call();
  }

  @override
  Future<List<Udhaar>> getUdhaarList({
    UdhaarDirection? direction,
    UdhaarStatus? status,
  }) async {
    final db = await _db.database;

    final whereClauses = <String>['user_id = ?', 'is_deleted = 0'];
    final whereArgs = <dynamic>[_userId];

    if (direction != null) {
      whereClauses.add('direction = ?');
      whereArgs.add(direction.name);
    }

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.name);
    }

    final maps = await db.query(
      'udhaar',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'status ASC, due_date ASC',
    );

    return maps.map(Udhaar.fromMap).toList();
  }

  @override
  Stream<List<Udhaar>> watchUdhaarList() async* {
    yield await getUdhaarList();
    yield* _changeController.stream.asyncMap((_) => getUdhaarList());
  }

  @override
  Future<Udhaar?> getUdhaarById(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      'udhaar',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Udhaar.fromMap(maps.first);
  }

  @override
  Future<List<Udhaar>> getUpcomingUdhaar({int limit = 5}) async {
    final db = await _db.database;
    final maps = await db.query(
      'udhaar',
      where: "user_id = ? AND status = 'pending' AND is_deleted = 0",
      whereArgs: [_userId],
      orderBy: 'due_date ASC',
      limit: limit,
    );
    return maps.map(Udhaar.fromMap).toList();
  }

  @override
  Future<void> addUdhaar(Udhaar udhaar) async {
    final db = await _db.database;
    await db.insert('udhaar', udhaar.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
    unawaited(_sync.pushUdhaar(udhaar));
  }

  @override
  Future<void> updateUdhaar(Udhaar udhaar) async {
    final db = await _db.database;
    await db.update(
      'udhaar',
      udhaar.toMap(),
      where: 'id = ?',
      whereArgs: [udhaar.id],
    );
    notifyListeners();
    unawaited(_sync.pushUdhaar(udhaar));
  }

  @override
  Future<void> markAsSettled(String id, {String? settleWalletId}) async {
    final db = await _db.database;
    final rowsBefore = await db.query('udhaar', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rowsBefore.isEmpty) return;

    final existingUdhaar = Udhaar.fromMap(rowsBefore.first);
    final originalWalletId = existingUdhaar.walletId;

    // If settled using a different wallet, we rebalance with a transfer record
    // so both wallets reflect the accurate cash flow.
    // E.g. Borrowed into Easypaisa, but paid back from Savings:
    // Money moved from Savings to Easypaisa to repay the borrowed amount.
    if (settleWalletId != null &&
        originalWalletId != null &&
        settleWalletId != originalWalletId) {
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      if (existingUdhaar.direction == UdhaarDirection.give) {
        // Paying back debt using settleWalletId -> transfer from settleWalletId to originalWalletId
        final transferId = 'transfer_settle_${id}_${now.millisecondsSinceEpoch}';
        await db.insert('transfers', {
          'id': transferId,
          'user_id': _userId,
          'from_wallet_id': settleWalletId,
          'to_wallet_id': originalWalletId,
          'amount': existingUdhaar.amount,
          'note': 'Repayment for udhaar (${existingUdhaar.personName})',
          'date': nowIso,
          'created_at': nowIso,
          'updated_at': nowIso,
          'is_deleted': 0,
          'synced': 0,
        });
        final transferRows = await db.query('transfers', where: 'id = ?', whereArgs: [transferId], limit: 1);
        if (transferRows.isNotEmpty) {
          unawaited(_sync.pushTransfer(Transfer.fromMap(transferRows.first)));
        }
      } else {
        // Collected owed money into settleWalletId -> transfer from originalWalletId to settleWalletId
        final transferId = 'transfer_settle_${id}_${now.millisecondsSinceEpoch}';
        await db.insert('transfers', {
          'id': transferId,
          'user_id': _userId,
          'from_wallet_id': originalWalletId,
          'to_wallet_id': settleWalletId,
          'amount': existingUdhaar.amount,
          'note': 'Settlement received for udhaar (${existingUdhaar.personName})',
          'date': nowIso,
          'created_at': nowIso,
          'updated_at': nowIso,
          'is_deleted': 0,
          'synced': 0,
        });
        final transferRows = await db.query('transfers', where: 'id = ?', whereArgs: [transferId], limit: 1);
        if (transferRows.isNotEmpty) {
          unawaited(_sync.pushTransfer(Transfer.fromMap(transferRows.first)));
        }
      }
    }

    await db.update(
      'udhaar',
      {
        'status': UdhaarStatus.settled.name,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    // Query directly (no status filter) to push settled state to Firestore
    final rows = await db.query('udhaar', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) unawaited(_sync.pushUdhaar(Udhaar.fromMap(rows.first)));
  }

  @override
  Future<void> deleteUdhaar(String id) async {
    final db = await _db.database;
    await db.update(
      'udhaar',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    // Query without is_deleted filter to push the deletion state to Firestore
    final rows = await db.query('udhaar', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) unawaited(_sync.pushUdhaar(Udhaar.fromMap(rows.first)));
  }
}

void unawaited(Future<void> future) {}
