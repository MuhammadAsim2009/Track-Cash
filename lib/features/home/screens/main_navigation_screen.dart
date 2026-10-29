import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/models.dart';
import '../../../widgets/floating_nav_bar.dart';
import '../../../widgets/tab_screen_wrapper.dart';
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
import '../providers/navigation_provider.dart';

enum MoreMenuAction {
  categories,
  transfers,
  theme,
  logout,
}

/// Root navigation screen featuring:
/// - App bar with dynamic title and "More" popup menu (Categories, Transfers, Theme, Logout)
/// - IndexedStack holding tab screens wrapped in TabScreenWrapper (retaining state & avoiding overlap)
/// - Custom FloatingNavBar with smooth cubic notch, 4 animated tabs, and center "+" button
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  static const List<String> _titles = [
    'Track Cash',
    'Transactions',
    'Monthly Budget',
    'Udhaar',
  ];

  /// Dispatches the "+" button action based on the currently selected tab.
  /// - Home / Transactions → Add Expense transaction (with Income toggle)
  /// - Budget (index 2)    → Set Budget for current month
  /// - Udhaar (index 3)    → Add Udhaar entry
  void _onAddPressed(BuildContext context, int tabIndex) {
    switch (tabIndex) {
      case 2: // Budget tab
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SetBudgetScreen(
              monthKey: DateFormatter.formatMonthKey(DateTime.now()),
            ),
          ),
        );
      case 3: // Udhaar tab
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditUdhaarScreen()),
        );
      default: // Home (0) & Transactions (1)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AddEditTransactionScreen(
              initialType: TransactionType.expense,
            ),
          ),
        );
    }
  }


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
          'Are you sure you want to log out of Track Cash?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(context, rootNavigator: true);
              Navigator.of(ctx).pop();
              await ref.read(authStateProvider.notifier).logout();
              // Pop all pushed routes back to root so the auth gate renders LoginScreen
              nav.popUntil((route) => route.isFirst);
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);

    // Tab screens wrapped in TabScreenWrapper to centrally provide bottom padding
    // so content and the last list item are never obscured behind the floating nav bar.
    final screens = [
      DashboardScreen(
        onNavigateToTransactions: () =>
            ref.read(navigationIndexProvider.notifier).state = 1,
        onNavigateToBudget: () =>
            ref.read(navigationIndexProvider.notifier).state = 2,
        onNavigateToUdhaar: () =>
            ref.read(navigationIndexProvider.notifier).state = 3,
      ),
      const TransactionsScreen(),
      const BudgetScreen(),
      const UdhaarScreen(),
    ].map((screen) => TabScreenWrapper(child: screen)).toList();

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_titles[currentIndex]),
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
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: FloatingNavBar(
          selectedIndex: currentIndex,
          onTabSelected: (index) {
            ref.read(navigationIndexProvider.notifier).state = index;
          },
          onAddPressed: () => _onAddPressed(context, currentIndex),
        ),
      ),
    );
  }
}
