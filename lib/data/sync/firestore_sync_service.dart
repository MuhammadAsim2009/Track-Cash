import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../local/app_database.dart';
import '../models/models.dart';

/// Firestore collection name constants (sub-collections of users/{uid}/).
class _Col {
  static const wallets = 'wallets';
  static const categories = 'categories';
  static const transactions = 'transactions';
  static const transfers = 'transfers';
  static const budgets = 'budgets';
  static const udhaar = 'udhaar';
}

/// Bidirectional field mapper: SQLite snake_case <-> Firestore camelCase.
/// The local synced flag is never stored in Firestore.
class _Mapper {
  // ── Wallet ──────────────────────────────────────────────────────────────
  static Map<String, dynamic> walletToFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'userId': m['user_id'],
        'name': m['name'],
        'type': m['type'],
        'openingBalance': m['opening_balance'],
        'countInDailyExpense': m['count_in_daily_expense'] == 1,
        'isDeleted': m['is_deleted'] == 1,
        'createdAt': m['created_at'],
        'updatedAt': m['updated_at'],
      };

  static Map<String, dynamic> walletFromFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'user_id': m['userId'],
        'name': m['name'],
        'type': m['type'],
        'opening_balance': m['openingBalance'] ?? 0,
        'count_in_daily_expense': (m['countInDailyExpense'] == true) ? 1 : 0,
        'is_deleted': (m['isDeleted'] == true) ? 1 : 0,
        'created_at': m['createdAt'],
        'updated_at': m['updatedAt'],
        'synced': 1,
      };

  // ── Category ─────────────────────────────────────────────────────────────
  static Map<String, dynamic> categoryToFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'userId': m['user_id'],
        'name': m['name'],
        'type': m['type'],
        'icon': m['icon'],
        'color': m['color'],
        'isDefault': m['is_default'] == 1,
        'isHidden': m['is_hidden'] == 1,
        'isDeleted': m['is_deleted'] == 1,
        'createdAt': m['created_at'],
        'updatedAt': m['updated_at'],
      };

  static Map<String, dynamic> categoryFromFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'user_id': m['userId'],
        'name': m['name'],
        'type': m['type'],
        'icon': m['icon'],
        'color': m['color'] ?? 0,
        'is_default': (m['isDefault'] == true) ? 1 : 0,
        'is_hidden': (m['isHidden'] == true) ? 1 : 0,
        'is_deleted': (m['isDeleted'] == true) ? 1 : 0,
        'created_at': m['createdAt'],
        'updated_at': m['updatedAt'],
        'synced': 1,
      };

  // ── Transaction ───────────────────────────────────────────────────────────
  static Map<String, dynamic> txToFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'userId': m['user_id'],
        'walletId': m['wallet_id'],
        'categoryId': m['category_id'],
        'type': m['type'],
        'amount': m['amount'],
        'note': m['note'],
        'date': m['date'],
        'isDeleted': m['is_deleted'] == 1,
        'createdAt': m['created_at'],
        'updatedAt': m['updated_at'],
      };

  static Map<String, dynamic> txFromFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'user_id': m['userId'],
        'wallet_id': m['walletId'],
        'category_id': m['categoryId'],
        'type': m['type'],
        'amount': m['amount'] ?? 0,
        'note': m['note'],
        'date': m['date'],
        'is_deleted': (m['isDeleted'] == true) ? 1 : 0,
        'created_at': m['createdAt'],
        'updated_at': m['updatedAt'],
        'synced': 1,
      };

  // ── Transfer ──────────────────────────────────────────────────────────────
  static Map<String, dynamic> transferToFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'userId': m['user_id'],
        'fromWalletId': m['from_wallet_id'],
        'toWalletId': m['to_wallet_id'],
        'amount': m['amount'],
        'note': m['note'],
        'date': m['date'],
        'isDeleted': m['is_deleted'] == 1,
        'createdAt': m['created_at'],
        'updatedAt': m['updated_at'],
      };

  static Map<String, dynamic> transferFromFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'user_id': m['userId'],
        'from_wallet_id': m['fromWalletId'],
        'to_wallet_id': m['toWalletId'],
        'amount': m['amount'] ?? 0,
        'note': m['note'],
        'date': m['date'],
        'is_deleted': (m['isDeleted'] == true) ? 1 : 0,
        'created_at': m['createdAt'],
        'updated_at': m['updatedAt'],
        'synced': 1,
      };

  // ── Budget ────────────────────────────────────────────────────────────────
  static Map<String, dynamic> budgetToFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'userId': m['user_id'],
        'month': m['month'],
        'mode': m['mode'],
        'categoryId': m['category_id'],
        'amount': m['amount'],
        'isDeleted': m['is_deleted'] == 1,
        'createdAt': m['created_at'],
        'updatedAt': m['updated_at'],
      };

  static Map<String, dynamic> budgetFromFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'user_id': m['userId'],
        'month': m['month'],
        'mode': m['mode'],
        'category_id': m['categoryId'],
        'amount': m['amount'] ?? 0,
        'is_deleted': (m['isDeleted'] == true) ? 1 : 0,
        'created_at': m['createdAt'],
        'updated_at': m['updatedAt'],
        'synced': 1,
      };

  // ── Udhaar ────────────────────────────────────────────────────────────────
  static Map<String, dynamic> udhaarToFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'userId': m['user_id'],
        'walletId': m['wallet_id'],
        'personName': m['person_name'],
        'amount': m['amount'],
        'direction': m['direction'],
        'dueDate': m['due_date'],
        'status': m['status'],
        'note': m['note'],
        'notificationId': m['notification_id'],
        'isDeleted': m['is_deleted'] == 1,
        'createdAt': m['created_at'],
        'updatedAt': m['updated_at'],
      };

  static Map<String, dynamic> udhaarFromFs(Map<String, dynamic> m) => {
        'id': m['id'],
        'user_id': m['userId'],
        'wallet_id': m['walletId'],
        'person_name': m['personName'],
        'amount': m['amount'] ?? 0,
        'direction': m['direction'],
        'due_date': m['dueDate'],
        'status': m['status'],
        'note': m['note'],
        'notification_id': m['notificationId'],
        'is_deleted': (m['isDeleted'] == true) ? 1 : 0,
        'created_at': m['createdAt'],
        'updated_at': m['updatedAt'],
        'synced': 1,
      };
}

/// Synchronises local SQLite data with Firestore.
///
/// Architecture:
/// - **Local-first**: SQLite is the source of truth for all reads.
/// - **Push on write**: After every SQLite mutation, call the relevant
///   push*() method. On success the row is marked synced = 1.
/// - **Pull on login**: [pullAll] downloads all Firestore records and
///   merges them using last-write-wins (updated_at comparison).
/// - **Offline catch-up**: [pushAllUnsynced] re-pushes any rows where
///   synced = 0 (written while offline).
class FirestoreSyncService {
  FirestoreSyncService(this._userId)
      : _fs = FirebaseFirestore.instance,
        _db = AppDatabase.instance;

  final String _userId;
  final FirebaseFirestore _fs;
  final AppDatabase _db;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _fs.collection('users').doc(_userId).collection(name);

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Set a Firestore document and mark the local row synced.
  Future<void> _pushDoc(
    String collection,
    String docId,
    Map<String, dynamic> fsData,
    String sqlTable,
  ) async {
    // ignore: avoid_print
    print('[FirestoreSyncService] Pushing to users/$_userId/$collection/$docId: $fsData');
    await _col(collection).doc(docId).set(fsData, SetOptions(merge: true));
    final db = await _db.database;
    await db.update(
      sqlTable,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [docId],
    );
    // ignore: avoid_print
    print('[FirestoreSyncService] Successfully pushed and marked synced: $collection/$docId');
  }

  /// Batch-push every row in [sqlTable] where synced = 0.
  Future<void> _pushUnsyncedRows(
    String sqlTable,
    String collection,
    Map<String, dynamic> Function(Map<String, dynamic>) toFs,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      sqlTable,
      where: 'user_id = ? AND synced = 0',
      whereArgs: [_userId],
    );
    if (rows.isEmpty) return;

    final batch = _fs.batch();
    for (final row in rows) {
      final ref = _col(collection).doc(row['id'] as String);
      batch.set(ref, toFs(row), SetOptions(merge: true));
    }
    await batch.commit();

    await db.update(
      sqlTable,
      {'synced': 1},
      where: 'user_id = ? AND synced = 0',
      whereArgs: [_userId],
    );
  }

  // ── Public push (call after every SQLite write) ───────────────────────────

  Future<void> pushWallet(Wallet w) async {
    try {
      await _pushDoc(_Col.wallets, w.id, _Mapper.walletToFs(w.toMap()), 'wallets');
    } catch (e, st) {
      // ignore: avoid_print
      print('[FirestoreSyncService] pushWallet error for user $_userId: $e\n$st');
    }
  }

  Future<void> pushCategory(AppCategory c) async {
    try {
      await _pushDoc(_Col.categories, c.id, _Mapper.categoryToFs(c.toMap()), 'categories');
    } catch (e, st) {
      // ignore: avoid_print
      print('[FirestoreSyncService] pushCategory error for user $_userId: $e\n$st');
    }
  }

  Future<void> pushTransaction(TransactionEntry tx) async {
    try {
      await _pushDoc(_Col.transactions, tx.id, _Mapper.txToFs(tx.toMap()), 'transactions');
    } catch (e, st) {
      // ignore: avoid_print
      print('[FirestoreSyncService] pushTransaction error for user $_userId: $e\n$st');
    }
  }

  Future<void> pushTransfer(Transfer t) async {
    try {
      await _pushDoc(_Col.transfers, t.id, _Mapper.transferToFs(t.toMap()), 'transfers');
    } catch (e, st) {
      // ignore: avoid_print
      print('[FirestoreSyncService] pushTransfer error for user $_userId: $e\n$st');
    }
  }

  Future<void> pushBudget(Budget b) async {
    try {
      await _pushDoc(_Col.budgets, b.id, _Mapper.budgetToFs(b.toMap()), 'budgets');
    } catch (e, st) {
      // ignore: avoid_print
      print('[FirestoreSyncService] pushBudget error for user $_userId: $e\n$st');
    }
  }

  Future<void> pushUdhaar(Udhaar u) async {
    try {
      await _pushDoc(_Col.udhaar, u.id, _Mapper.udhaarToFs(u.toMap()), 'udhaar');
    } catch (e, st) {
      // ignore: avoid_print
      print('[FirestoreSyncService] pushUdhaar error for user $_userId: $e\n$st');
    }
  }

  // ── Pull on login ─────────────────────────────────────────────────────────

  /// Download all Firestore data for this user and merge into SQLite.
  /// Uses last-write-wins: remote wins only when its updatedAt is strictly
  /// newer than the local row's updated_at string (ISO-8601 lexicographic).
  Future<void> pullAll() async {
    try {
      // ignore: avoid_print
      print('[FirestoreSyncService] Starting pullAll for user $_userId');
      await Future.wait([
        _pullCollection(_Col.wallets, 'wallets', _Mapper.walletFromFs),
        _pullCollection(_Col.categories, 'categories', _Mapper.categoryFromFs),
        _pullCollection(_Col.transactions, 'transactions', _Mapper.txFromFs),
        _pullCollection(_Col.transfers, 'transfers', _Mapper.transferFromFs),
        _pullCollection(_Col.budgets, 'budgets', _Mapper.budgetFromFs),
        _pullCollection(_Col.udhaar, 'udhaar', _Mapper.udhaarFromFs),
      ]);
      // ignore: avoid_print
      print('[FirestoreSyncService] Completed pullAll for user $_userId');
    } catch (e, st) {
      // ignore: avoid_print
      print('[FirestoreSyncService] pullAll error for user $_userId: $e\n$st');
    }
  }

  Future<void> _pullCollection(
    String collection,
    String sqlTable,
    Map<String, dynamic> Function(Map<String, dynamic>) fromFs,
  ) async {
    final snapshot = await _col(collection).get();
    if (snapshot.docs.isEmpty) return;

    final db = await _db.database;
    final dbBatch = db.batch();

    for (final doc in snapshot.docs) {
      final remote = fromFs(doc.data());
      final id = remote['id'] as String;
      final remoteUpdated = remote['updated_at'] as String? ?? '';

      final localRows = await db.query(
        sqlTable,
        columns: ['updated_at'],
        where: 'id = ?',
        whereArgs: [id],
      );

      if (localRows.isEmpty) {
        // Brand-new record from another device — insert it
        dbBatch.insert(sqlTable, remote,
            conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        final localUpdated = localRows.first['updated_at'] as String? ?? '';
        // Remote wins only if strictly newer
        if (remoteUpdated.compareTo(localUpdated) > 0) {
          dbBatch.insert(sqlTable, remote,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }

    await dbBatch.commit(noResult: true);
  }

  // ── Catch-up push (call when coming back online) ───────────────────────────

  Future<void> pushAllUnsynced() async {
    try {
      // ignore: avoid_print
      print('[FirestoreSyncService] Starting pushAllUnsynced for user $_userId');
      await Future.wait([
        _pushUnsyncedRows('wallets', _Col.wallets, _Mapper.walletToFs),
        _pushUnsyncedRows('categories', _Col.categories, _Mapper.categoryToFs),
        _pushUnsyncedRows('transactions', _Col.transactions, _Mapper.txToFs),
        _pushUnsyncedRows('transfers', _Col.transfers, _Mapper.transferToFs),
        _pushUnsyncedRows('budgets', _Col.budgets, _Mapper.budgetToFs),
        _pushUnsyncedRows('udhaar', _Col.udhaar, _Mapper.udhaarToFs),
      ]);
      // ignore: avoid_print
      print('[FirestoreSyncService] Completed pushAllUnsynced for user $_userId');
    } catch (e, st) {
      // ignore: avoid_print
      print('[FirestoreSyncService] pushAllUnsynced error for user $_userId: $e\n$st');
    }
  }
}
