import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../fake/fake_seed_data.dart';
import '../../local/app_database.dart';
import '../../models/udhaar.dart';
import '../udhaar_repository.dart';

/// SQLite implementation of [UdhaarRepository].
class SqliteUdhaarRepository implements UdhaarRepository {
  SqliteUdhaarRepository({
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
  }

  @override
  Future<void> markAsSettled(String id) async {
    final db = await _db.database;
    await db.update(
      'udhaar',
      {
        'status': UdhaarStatus.settled.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  @override
  Future<void> deleteUdhaar(String id) async {
    final db = await _db.database;
    await db.update(
      'udhaar',
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
