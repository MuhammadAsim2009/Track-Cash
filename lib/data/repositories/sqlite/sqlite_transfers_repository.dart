import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../fake/fake_seed_data.dart';
import '../../local/app_database.dart';
import '../../models/transfer.dart';
import '../transfers_repository.dart';

/// SQLite implementation of [TransfersRepository].
class SqliteTransfersRepository implements TransfersRepository {
  SqliteTransfersRepository({
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
  }

  @override
  Future<void> deleteTransfer(String id) async {
    final db = await _db.database;
    await db.update(
      'transfers',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }
}
