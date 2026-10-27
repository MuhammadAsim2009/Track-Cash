import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../budget/screens/budget_screen.dart';
import '../../budget/screens/set_budget_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../transactions/screens/add_edit_transaction_screen.dart';
import '../../transactions/screens/transactions_screen.dart';
import '../../transfers/screens/transfers_screen.dart';
import '../../udhaar/screens/add_edit_udhaar_screen.dart';
import '../../udhaar/screens/udhaar_screen.dart';

enum MoreMenuAction {
  categories,
  transfers,
  theme,
  logout,
}

/// Root navigation screen featuring:
/// - App bar with title and "More" popup menu (Categories, Transfers, Theme, Logout)
/// - Material 3 NavigationBar with 4 tabs (Home, Transactions, Budget, Udhaar)
/// - Floating Action Button for quick add on Home and Transactions tabs
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'TrackCash',
    'Transactions',
    'Monthly Budget',
    'Udhaar',
  ];

  void _onMenuActionSelected(MoreMenuAction action) {
    switch (action) {
      case MoreMenuAction.categories:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CategoriesScreen()),
        );
        break;
      case MoreMenuAction.transfers:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransfersScreen()),
        );
        break;
      case MoreMenuAction.theme:
        _showThemeDialog();
        break;
      case MoreMenuAction.logout:
        _showLogoutDialog();
        break;
    }
  }

  void _showThemeDialog() {
    final currentMode = ref.read(themeModeProvider);
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context: ctx,
              title: 'System Default',
              mode: ThemeMode.system,
              currentMode: currentMode,
              primaryColor: theme.colorScheme.primary,
            ),
            _buildThemeOption(
              context: ctx,
              title: 'Light',
              mode: ThemeMode.light,
              currentMode: currentMode,
              primaryColor: theme.colorScheme.primary,
            ),
            _buildThemeOption(
              context: ctx,
              title: 'Dark',
              mode: ThemeMode.dark,
              currentMode: currentMode,
              primaryColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required Color primaryColor,
  }) {
    final isSelected = currentMode == mode;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? primaryColor : null,
      ),
      title: Text(title),
      selected: isSelected,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.of(context).pop();
      },
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text(
          'Are you sure you want to log out of TrackCash?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToTransactions: () => setState(() => _currentIndex = 1),
        onNavigateToBudget: () => setState(() => _currentIndex = 2),
        onNavigateToUdhaar: () => setState(() => _currentIndex = 3),
      ),
      const TransactionsScreen(),
      const BudgetScreen(),
      const UdhaarScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          PopupMenuButton<MoreMenuAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onSelected: _onMenuActionSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MoreMenuAction.categories,
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Categories'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MoreMenuAction.transfers,
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 20),
                    SizedBox(width: 12),
                    Text('Transfers & History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MoreMenuAction.theme,
                child: Row(
                  children: [
                    Icon(Icons.brightness_medium_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Theme Mode'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: MoreMenuAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Log out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: switch (_currentIndex) {
        0 || 1 => FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddEditTransactionScreen(),
                ),
              );
            },
            tooltip: 'Add Transaction',
            child: const Icon(Icons.add),
          ),
        2 => FloatingActionButton(
            heroTag: null,
            onPressed: () {
              final selectedDate = ref.read(selectedBudgetMonthProvider);
              final monthKey = DateFormatter.formatMonthKey(selectedDate);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SetBudgetScreen(monthKey: monthKey),
                ),
              );
            },
            tooltip: 'Set Budget',
            child: const Icon(Icons.add),
          ),
        3 => FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddEditUdhaarScreen(),
                ),
              );
            },
            tooltip: 'Add Udhaar',
            child: const Icon(Icons.add),
          ),
        _ => null,
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Udhaar',
          ),
        ],
      ),
    );
  }
}
