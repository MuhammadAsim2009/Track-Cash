import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../fake/fake_seed_data.dart';
import '../../local/app_database.dart';
import '../../models/category.dart';
import '../../sync/firestore_sync_service.dart';
import '../categories_repository.dart';

/// SQLite implementation of [CategoriesRepository].
class SqliteCategoriesRepository implements CategoriesRepository {
  SqliteCategoriesRepository({
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
  Future<List<AppCategory>> getCategories({
    CategoryType? type,
    bool includeHidden = false,
  }) async {
    final db = await _db.database;

    final whereClauses = <String>['user_id = ?', 'is_deleted = 0'];
    final whereArgs = <dynamic>[_userId];

    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }

    if (!includeHidden) {
      whereClauses.add('is_hidden = 0');
    }

    final maps = await db.query(
      'categories',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'is_default DESC, name ASC',
    );

    return maps.map(AppCategory.fromMap).toList();
  }

  @override
  Stream<List<AppCategory>> watchCategories({
    CategoryType? type,
    bool includeHidden = false,
  }) async* {
    yield await getCategories(type: type, includeHidden: includeHidden);
    yield* _changeController.stream
        .asyncMap((_) => getCategories(type: type, includeHidden: includeHidden));
  }

  @override
  Future<AppCategory?> getCategoryById(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      'categories',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AppCategory.fromMap(maps.first);
  }

  @override
  Future<void> createCategory(AppCategory category) async {
    final db = await _db.database;
    await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
    unawaited(_sync.pushCategory(category));
  }

  @override
  Future<void> updateCategory(AppCategory category) async {
    final db = await _db.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    notifyListeners();
    unawaited(_sync.pushCategory(category));
  }

  @override
  Future<void> hideCategory(String id, bool hide) async {
    final db = await _db.database;
    await db.update(
      'categories',
      {
        'is_hidden': hide ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    // Query without is_deleted/is_hidden filter so we can push the updated state
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) unawaited(_sync.pushCategory(AppCategory.fromMap(rows.first)));
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await _db.database;
    await db.update(
      'categories',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    // Query without is_deleted filter so we can push the is_deleted=true state to Firestore
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) unawaited(_sync.pushCategory(AppCategory.fromMap(rows.first)));
  }
}

void unawaited(Future<void> future) {}
