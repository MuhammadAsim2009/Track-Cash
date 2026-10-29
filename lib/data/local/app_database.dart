import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../fake/fake_seed_data.dart';

/// Database helper managing the local SQLite database.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // If running on desktop (Windows, Linux, macOS), initialize sqflite_common_ffi
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'track_cash.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Remove all dummy test data and reset wallet balances to 0
          await db.delete('transactions');
          await db.delete('transfers');
          await db.delete('budgets');
          await db.delete('udhaar');
          await db.update('wallets', {'opening_balance': 0});
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE wallets ADD COLUMN count_in_daily_expense INTEGER NOT NULL DEFAULT 1;');
          } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE udhaar ADD COLUMN wallet_id TEXT;');
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await db.execute('ALTER TABLE wallets ADD COLUMN current_balance INTEGER NOT NULL DEFAULT 0;');
            await db.execute('UPDATE wallets SET current_balance = opening_balance;');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        opening_balance INTEGER NOT NULL DEFAULT 0,
        current_balance INTEGER NOT NULL DEFAULT 0,
        count_in_daily_expense INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_hidden INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        wallet_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transfers (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        from_wallet_id TEXT NOT NULL,
        to_wallet_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        month TEXT NOT NULL,
        mode TEXT NOT NULL,
        category_id TEXT,
        amount INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE udhaar (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        wallet_id TEXT,
        person_name TEXT NOT NULL,
        amount INTEGER NOT NULL,
        direction TEXT NOT NULL,
        due_date TEXT NOT NULL,
        status TEXT NOT NULL,
        note TEXT,
        notification_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create performance indexes
    await db.execute('CREATE INDEX idx_transactions_user_date ON transactions(user_id, date);');
    await db.execute('CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id);');
    await db.execute('CREATE INDEX idx_budgets_user_month ON budgets(user_id, month);');
    await db.execute('CREATE INDEX idx_udhaar_user_status ON udhaar(user_id, status);');
    await db.execute('CREATE INDEX idx_udhaar_wallet ON udhaar(wallet_id);');

    // Seed default wallets and categories only (clean zero balances, no dummy transactions)
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final batch = db.batch();

    // Default Wallets (with 0 opening balance)
    for (final wallet in FakeSeedData.initialWallets) {
      batch.insert('wallets', wallet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Default Categories (standard expense and income categories)
    for (final category in FakeSeedData.initialCategories) {
      batch.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Clears all dummy transactions, transfers, budgets, and udhaar entries,
  /// and resets all wallet balances to 0 so the user can test on a clean slate.
  Future<void> resetToCleanState() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('transfers');
    await db.delete('budgets');
    await db.delete('udhaar');
    await db.update('wallets', {'opening_balance': 0});
  }

  /// Clears all local data when a user logs out.
  Future<void> clearLocalUserData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('transfers');
    await db.delete('budgets');
    await db.delete('udhaar');
    await db.delete('wallets');
    await db.delete('categories');
  }

  /// Seeds default wallets and categories for a specific user ID if they don't have them yet.
  Future<void> seedUserInitialData(String userId) async {
    final db = await database;
    final existingWallets = await db.query(
      'wallets',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (existingWallets.isEmpty) {
      final batch = db.batch();
      final now = DateTime.now();

      // Seed default wallets
      for (final wallet in FakeSeedData.initialWallets) {
        final userWallet = wallet.copyWith(
          id: '${wallet.id}_$userId',
          userId: userId,
          currentBalance: wallet.openingBalance,
          createdAt: now,
          updatedAt: now,
          synced: false,
        );
        batch.insert('wallets', userWallet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Seed default categories
      for (final category in FakeSeedData.initialCategories) {
        final userCat = category.copyWith(
          id: '${category.id}_$userId',
          userId: userId,
          createdAt: now,
          updatedAt: now,
        );
        batch.insert('categories', userCat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
    }
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
