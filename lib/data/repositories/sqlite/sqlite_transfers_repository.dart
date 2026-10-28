import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../fake/fake_seed_data.dart';
import '../../local/app_database.dart';
import '../../models/transfer.dart';
import '../../sync/firestore_sync_service.dart';
import '../transfers_repository.dart';

/// SQLite implementation of [TransfersRepository].
class SqliteTransfersRepository implements TransfersRepository {
  SqliteTransfersRepository({
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
  Future<List<Transfer>> getTransfers() async {
    final db = await _db.database;
    final maps = await db.query(
      'transfers',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [_userId],
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map(Transfer.fromMap).toList();
  }

  @override
  Stream<List<Transfer>> watchTransfers() async* {
    yield await getTransfers();
    yield* _changeController.stream.asyncMap((_) => getTransfers());
  }

  @override
  Future<Transfer?> getTransferById(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      'transfers',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Transfer.fromMap(maps.first);
  }

  @override
  Future<void> addTransfer(Transfer transfer) async {
    final db = await _db.database;
    await db.insert('transfers', transfer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
    unawaited(_sync.pushTransfer(transfer));
  }

  @override
  Future<void> deleteTransfer(String id) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'transfers',
      {
        'is_deleted': 1,
        'updated_at': now,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    // Fetch the soft-deleted row (without is_deleted filter) to push deletion to Firestore
    final rows = await db.query('transfers', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) unawaited(_sync.pushTransfer(Transfer.fromMap(rows.first)));
  }
}

void unawaited(Future<void> future) {}
