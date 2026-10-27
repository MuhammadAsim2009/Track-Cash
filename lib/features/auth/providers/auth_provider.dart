import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.email,
    this.name,
    this.hasCompletedSetup = true,
  });

  final bool isAuthenticated;
  final String? email;
  final String? name;
  final bool hasCompletedSetup;

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? name,
    bool? hasCompletedSetup,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      name: name ?? this.name,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
    );
  }
}

class FakeAuthNotifier extends StateNotifier<AuthState> {
  FakeAuthNotifier(this._ref)
      : super(const AuthState(
          isAuthenticated: true, // Default to true so app opens into dashboard
          email: 'demo@trackcash.app',
          name: 'Demo User',
          hasCompletedSetup: true,
        ));

  final Ref _ref;

  Future<void> login(String email, String password) async {
    // Phase 1 in-memory login simulation
    state = AuthState(
      isAuthenticated: true,
      email: email,
      name: email.split('@').first,
      hasCompletedSetup: true,
    );
  }

  Future<void> register(String name, String email, String password) async {
    // Phase 1 in-memory registration leading to opening balances setup
    state = AuthState(
      isAuthenticated: true,
      email: email,
      name: name,
      hasCompletedSetup: false,
    );
  }

  Future<void> completeOpeningBalancesSetup({
    required int cash,
    required int savings,
    required int mobileWallet,
  }) async {
    final walletsRepo = _ref.read(walletsRepositoryProvider);
    final wallets = await walletsRepo.getWallets();

    for (final wallet in wallets) {
      if (wallet.type == WalletType.cash) {
        await walletsRepo.updateWallet(wallet.copyWith(openingBalance: cash));
      } else if (wallet.type == WalletType.savings) {
        await walletsRepo.updateWallet(wallet.copyWith(openingBalance: savings));
      } else if (wallet.type == WalletType.mobileWallet) {
        await walletsRepo.updateWallet(wallet.copyWith(openingBalance: mobileWallet));
      }
    }

    state = state.copyWith(hasCompletedSetup: true);
  }

  Future<void> logout() async {
    state = const AuthState(
      isAuthenticated: false,
      email: null,
      name: null,
      hasCompletedSetup: false,
    );
  }
}

final authStateProvider =
    StateNotifierProvider<FakeAuthNotifier, AuthState>((ref) {
  return FakeAuthNotifier(ref);
});
