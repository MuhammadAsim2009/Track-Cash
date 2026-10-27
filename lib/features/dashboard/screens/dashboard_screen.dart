import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/budget_progress_bar.dart';
import '../../../widgets/tab_screen_wrapper.dart';
import '../../../widgets/transaction_tile.dart';
import '../../../widgets/udhaar_tile.dart';
import '../../../widgets/wallet_card.dart';
import '../../transactions/screens/add_edit_transaction_screen.dart';
import '../../transfers/screens/add_transfer_screen.dart';

/// Complete Dashboard (Home tab) matching Phase 1 specifications.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
    this.onNavigateToTransactions,
    this.onNavigateToBudget,
    this.onNavigateToUdhaar,
  });

  final VoidCallback? onNavigateToTransactions;
  final VoidCallback? onNavigateToBudget;
  final VoidCallback? onNavigateToUdhaar;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);
    final currentMonthKey = DateFormatter.formatMonthKey(DateTime.now());
    final monthSpentAsync = ref.watch(monthExpensesProvider(currentMonthKey));
    final totalBudgetAsync = ref.watch(totalBudgetProvider(currentMonthKey));
    final recentTxAsync = ref.watch(recentTransactionsProvider);
    final upcomingUdhaarAsync = ref.watch(upcomingUdhaarProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(totalBalanceProvider);
        ref.invalidate(walletsStreamProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(upcomingUdhaarProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: TabScreenWrapper.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Balance Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Balance',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isBalanceVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            onPressed: () {
                              setState(() {
                                _isBalanceVisible = !_isBalanceVisible;
                              });
                            },
                            tooltip: _isBalanceVisible
                                ? 'Hide balance'
                                : 'Show balance',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      totalBalanceAsync.when(
                        data: (total) => Text(
                          _isBalanceVisible
                              ? CurrencyFormatter.format(total)
                              : '••••••••',
                          style: theme.textTheme.displayLarge,
                        ),
                        loading: () => const Text('Loading...'),
                        error: (_, _) => const Text('Error calculating balance'),
                      ),
                      const SizedBox(height: 20),

                      // Quick Action Buttons (Add Income, Add Expense, Transfer)
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              context: context,
                              icon: Icons.arrow_downward,
                              label: 'Income',
                              color: colors.income,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AddEditTransactionScreen(
                                      initialType: TransactionType.income,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              context: context,
                              icon: Icons.arrow_upward,
                              label: 'Expense',
                              color: colors.expense,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AddEditTransactionScreen(
                                      initialType: TransactionType.expense,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              context: context,
                              icon: Icons.swap_horiz,
                              label: 'Transfer',
                              color: theme.colorScheme.primary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AddTransferScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Wallets Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'My Wallets',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Wallets Horizontal List
            walletsAsync.when(
              data: (wallets) {
                return SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: wallets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      final balanceAsync =
                          ref.watch(walletBalanceProvider(wallet.id));
                      final balance = balanceAsync.value ?? wallet.openingBalance;

                      return SizedBox(
                        width: wallet.type == WalletType.savings ? 190 : 170,
                        child: WalletCard(
                          wallet: wallet,
                          balance: balance,
                          onTap: () {
                            _showWalletDetailsDialog(context, wallet, balance);
                          },
                          onToggleDailyExpense: wallet.type == WalletType.savings
                              ? (val) async {
                                  final updated =
                                      wallet.copyWith(countInDailyExpense: val);
                                  await ref
                                      .read(walletsRepositoryProvider)
                                      .updateWallet(updated);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(val
                                            ? 'Savings money will now count in daily expense'
                                            : 'Savings money excluded from daily expense'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading wallets: $e'),
              ),
            ),

            const SizedBox(height: 16),

            // Monthly Budget Progress Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: totalBudgetAsync.when(
                    data: (budget) {
                      final spent = monthSpentAsync.value ?? 0;
                      final budgetAmount = budget?.amount ?? 0;

                      if (budgetAmount == 0) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Budget',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No budget set for ${DateFormatter.formatMonthYear(DateTime.now())}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            FilledButton.tonal(
                              onPressed: widget.onNavigateToBudget,
                              child: const Text('Set Budget'),
                            ),
                          ],
                        );
                      }

                      return InkWell(
                        onTap: widget.onNavigateToBudget,
                        borderRadius: BorderRadius.circular(12),
                        child: BudgetProgressBar(
                          title: 'This Month (${DateFormatter.formatMonthYear(DateTime.now())})',
                          spent: spent,
                          budget: budgetAmount,
                          daysLeft: DateFormatter.daysLeftInMonth(),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const Text('Error loading budget'),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Upcoming Udhaar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Udhaar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.onNavigateToUdhaar != null)
                    TextButton(
                      onPressed: widget.onNavigateToUdhaar,
                      child: const Text('See all'),
                    ),
                ],
              ),
            ),
            upcomingUdhaarAsync.when(
              data: (udhaarList) {
                if (udhaarList.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'No pending udhaar. All settled!',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                final walletsList = walletsAsync.value ?? <Wallet>[];
                final walletsMap = {for (final w in walletsList) w.id: w.name};

                return Column(
                  children: udhaarList.take(2).map((u) {
                    return UdhaarTile(
                      udhaar: u,
                      walletName: u.walletId != null ? walletsMap[u.walletId] : null,
                      onSettle: () async {
                        await ref
                            .read(udhaarRepositoryProvider)
                            .markAsSettled(u.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Marked ${u.personName} as settled'),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading udhaar: $e'),
            ),

            const SizedBox(height: 20),

            // Recent Transactions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.onNavigateToTransactions != null)
                    TextButton(
                      onPressed: widget.onNavigateToTransactions,
                      child: const Text('See all'),
                    ),
                ],
              ),
            ),
            recentTxAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'No transactions recorded yet.',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }

                final categoriesAsync =
                    ref.watch(categoriesStreamProvider(null));
                final categoriesMap = {
                  for (final cat in categoriesAsync.value ?? <AppCategory>[])
                    cat.id: cat
                };
                final walletsMap = {
                  for (final w in walletsAsync.value ?? <Wallet>[]) w.id: w
                };

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return TransactionTile(
                        transaction: tx,
                        category: categoriesMap[tx.categoryId],
                        wallet: walletsMap[tx.walletId],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditTransactionScreen(
                                initialTransaction: tx,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading transactions: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletDetailsDialog(
    BuildContext context,
    Wallet wallet,
    int balance,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(wallet.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${wallet.type.displayName}'),
            const SizedBox(height: 8),
            Text('Opening Balance: ${CurrencyFormatter.format(wallet.openingBalance)}'),
            const SizedBox(height: 4),
            Text('Current Balance: ${CurrencyFormatter.format(balance)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (wallet.type == WalletType.savings) ...[
              const Divider(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Count in Daily Expense',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  wallet.countInDailyExpense
                      ? 'Savings money is counted in daily expense'
                      : 'Savings money is excluded from daily expense',
                  style: const TextStyle(fontSize: 12),
                ),
                value: wallet.countInDailyExpense,
                onChanged: (val) async {
                  final updated = wallet.copyWith(countInDailyExpense: val);
                  await ref.read(walletsRepositoryProvider).updateWallet(updated);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
