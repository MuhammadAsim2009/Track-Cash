import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/sqlite/sqlite_wallets_repository.dart';
import '../../../data/sync/firestore_sync_service.dart';

export '../../../data/sync/firestore_sync_service.dart' show SyncStatus;

/// Incremented every time a full Firestore → SQLite pull completes.
/// Stream providers watch this so they re-query SQLite after sync finishes.
final syncTickProvider = StateProvider<int>((ref) => 0);

/// True once the initial Firebase Auth state and initial data pull have completed on startup.
final isAuthInitializedProvider = StateProvider<bool>((ref) => false);

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.synced);

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.name,
    this.hasCompletedSetup = true,
  });

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? name;
  final bool hasCompletedSetup;

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? email,
    String? name,
    bool? hasCompletedSetup,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
    );
  }
}

class FirebaseAuthNotifier extends StateNotifier<AuthState> {
  FirebaseAuthNotifier(this._ref)
      : _auth = FirebaseAuth.instance,
        super(const AuthState(isAuthenticated: false)) {
    // Defer _init() until after the Riverpod provider tree finishes building.
    // Without this, _applyUser() would call _ref.read(syncStatusProvider...)
    // while this provider is still being constructed — a Riverpod violation.
    Future.microtask(_init);
  }

  final Ref _ref;
  final FirebaseAuth _auth;
  StreamSubscription<User?>? _sub;

  void _init() async {
    FirestoreSyncService.syncStatusNotifier.addListener(() {
      if (mounted) {
        _ref.read(syncStatusProvider.notifier).state =
            FirestoreSyncService.currentSyncStatus;
      }
    });

    final current = _auth.currentUser;
    if (current != null) {
      await _applyUser(current);
    }
    if (mounted) {
      _ref.read(isAuthInitializedProvider.notifier).state = true;
    }

    _sub = _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        if (state.userId != user.uid) {
          await _applyUser(user);
        }
      } else {
        FirestoreSyncService.stopAutoSync();
        state = const AuthState(
          isAuthenticated: false,
          userId: null,
          email: null,
          name: null,
          hasCompletedSetup: false,
        );
      }
      if (mounted) {
        _ref.read(isAuthInitializedProvider.notifier).state = true;
      }
    });
  }

  Future<void> _applyUser(User user) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final hasSetup = prefs.getBool('setup_completed_${user.uid}') ?? true;

    // Show syncing badge in the UI immediately
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    FirestoreSyncService.setSyncStatus(SyncStatus.syncing);

    final sync = FirestoreSyncService(user.uid);

    // 1. Pull existing user data from Firestore first into SQLite!
    await sync.pullAll();

    // 2. Seed default wallets & categories for this user in SQLite if not yet present
    await AppDatabase.instance.seedUserInitialData(user.uid);

    // 3. Recalculate all wallet balances to ensure current_balance is up-to-date
    final walletsRepo = SqliteWalletsRepository(userId: user.uid);
    await walletsRepo.recalculateAllWallets();

    // 4. Start auto-sync watcher
    FirestoreSyncService.startAutoSync(user.uid);

    // Increment the sync tick so any already-mounted stream providers
    // re-query SQLite immediately
    _ref.read(syncTickProvider.notifier).update((t) => t + 1);

    // Check if any unsynced rows remain
    final hasPending = await sync.hasUnsyncedRows();
    final status = hasPending ? SyncStatus.pending : SyncStatus.synced;
    _ref.read(syncStatusProvider.notifier).state = status;
    FirestoreSyncService.setSyncStatus(status);

    // Push any rows that were written offline while we were logged out.
    unawaited(
      sync.pushAllUnsynced().then((_) async {
        final pending = await sync.hasUnsyncedRows();
        if (mounted) {
          _ref.read(syncStatusProvider.notifier).state =
              pending ? SyncStatus.pending : SyncStatus.synced;
        }
      }).catchError((_) {
        if (mounted) _ref.read(syncStatusProvider.notifier).state = SyncStatus.pending;
      }),
    );

    state = AuthState(
      isAuthenticated: true,
      userId: user.uid,
      email: user.email,
      name: user.displayName ?? (user.email != null ? user.email!.split('@').first : 'User'),
      hasCompletedSetup: hasSetup,
    );
  }

  /// Sign in with email and password
  Future<void> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _applyUser(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  /// Register new user with email, password, and display name
  Future<void> register(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name);

        final prefs = _ref.read(sharedPreferencesProvider);
        await prefs.setBool('setup_completed_${user.uid}', false);

        await AppDatabase.instance.seedUserInitialData(user.uid);

        state = AuthState(
          isAuthenticated: true,
          userId: user.uid,
          email: email,
          name: name,
          hasCompletedSetup: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  /// Complete initial opening balances setup
  Future<void> completeOpeningBalancesSetup({
    required int cash,
    required int savings,
    required int mobileWallet,
  }) async {
    final uid = state.userId ?? 'anonymous_user';
    final walletsRepo = SqliteWalletsRepository(userId: uid);
    final wallets = await walletsRepo.getWallets();
    final now = DateTime.now();

    for (final wallet in wallets) {
      int amount = 0;
      if (wallet.type == WalletType.cash) {
        amount = cash;
      } else if (wallet.type == WalletType.savings) {
        amount = savings;
      } else if (wallet.type == WalletType.mobileWallet) {
        amount = mobileWallet;
      }
      await walletsRepo.updateWallet(
        wallet.copyWith(
          openingBalance: amount,
          currentBalance: amount,
          updatedAt: now,
          synced: false,
        ),
      );
    }

    final sync = FirestoreSyncService(uid);
    await sync.pushAllUnsynced();

    if (state.userId != null) {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setBool('setup_completed_${state.userId}', true);
    }

    state = state.copyWith(hasCompletedSetup: true);
  }

  /// Logout and clear local SQLite data to prevent cross-user data leaks
  Future<void> logout() async {
    FirestoreSyncService.stopAutoSync();
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.synced;
    FirestoreSyncService.setSyncStatus(SyncStatus.synced);
    await _auth.signOut();
    await AppDatabase.instance.clearLocalUserData();
    state = const AuthState(
      isAuthenticated: false,
      userId: null,
      email: null,
      name: null,
      hasCompletedSetup: false,
    );
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'This email is already in use. Try logging in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authStateProvider =
    StateNotifierProvider<FirebaseAuthNotifier, AuthState>((ref) {
  return FirebaseAuthNotifier(ref);
});

final currentUserIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.userId ?? 'anonymous_user';
});
