import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/opening_balances_screen.dart';
import 'features/home/screens/main_navigation_screen.dart';
import 'features/splash/screens/splash_screen.dart';

/// Root TrackCash application widget with theme and authentication gate.
class TrackCashApp extends ConsumerWidget {
  const TrackCashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final splashComplete = ref.watch(splashCompleteProvider);

    return MaterialApp(
      title: 'TrackCash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _buildHome(authState, splashComplete),
      ),
    );
  }

  Widget _buildHome(AuthState authState, bool splashComplete) {
    if (!splashComplete) {
      return const SplashScreen(key: ValueKey('splash_screen'));
    }
    if (!authState.isAuthenticated) {
      return const LoginScreen(key: ValueKey('login_screen'));
    }
    if (!authState.hasCompletedSetup) {
      return const OpeningBalancesScreen(key: ValueKey('opening_balances_screen'));
    }
    return const MainNavigationScreen(key: ValueKey('main_navigation_screen'));
  }
}
