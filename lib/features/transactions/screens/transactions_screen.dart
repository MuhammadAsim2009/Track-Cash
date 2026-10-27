import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/tab_screen_wrapper.dart';
import '../../../widgets/transaction_tile.dart';
import 'add_edit_transaction_screen.dart';

/// Transactions Screen with modern month selector, monthly summary strip,
/// popup-menu filter chips, date grouping, and deletion.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  DateTime _currentMonth = DateTime.now();
  String? _selectedWalletId;
  String? _selectedCategoryId;
  TransactionType? _selectedType;

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _resetToCurrentMonth() {
    setState(() {
      _currentMonth = DateTime.now();
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _currentMonth.year == now.year && _currentMonth.month == now.month;
  }

  bool get _hasActiveFilters =>
      _selectedType != null ||
      _selectedWalletId != null ||
      _selectedCategoryId != null;

  void _clearAllFilters() {
    setState(() {
      _selectedType = null;
      _selectedWalletId = null;
      _selectedCategoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final monthKey = DateFormatter.formatMonthKey(_currentMonth);
    final txsAsync = ref.watch(transactionsStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider(null));

    final walletsMap = {
      for (final w in walletsAsync.value ?? <Wallet>[]) w.id: w
    };
    final categoriesMap = {
      for (final c in categoriesAsync.value ?? <AppCategory>[]) c.id: c
    };

    // Calculate overall month totals for header summary
    final allMonthTxs = (txsAsync.value ?? <TransactionEntry>[])
        .where((tx) => DateFormatter.formatMonthKey(tx.date) == monthKey)
        .toList();

    int monthIncome = 0;
    int monthExpense = 0;
    for (final tx in allMonthTxs) {
      if (tx.type == TransactionType.income) {
        monthIncome += tx.amount;
      } else {
        monthExpense += tx.amount;
      }
    }
    final monthNet = monthIncome - monthExpense;

    return Column(
      children: [
          // ── Month Selector Header ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  onPressed: _previousMonth,
                  tooltip: 'Previous month',
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatMonthYear(_currentMonth),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isCurrentMonth)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Current',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: _resetToCurrentMonth,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.today_rounded,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Today',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  onPressed: _nextMonth,
                  tooltip: 'Next month',
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ],
            ),
          ),

          // ── Month Financial Summary Strip ──────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                // Income
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded,
                              size: 13, color: colors.income),
                          const SizedBox(width: 3),
                          Text(
                            'Income',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(monthIncome),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.income,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(height: 28, width: 1, color: colors.border),
                // Expense
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded,
                                size: 13, color: colors.expense),
                            const SizedBox(width: 3),
                            Text(
                              'Expense',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(monthExpense),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.expense,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 28, width: 1, color: colors.border),
                // Net
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              monthNet >= 0
                                  ? Icons.savings_outlined
                                  : Icons.warning_amber_rounded,
                              size: 13,
                              color: monthNet >= 0
                                  ? colors.income
                                  : colors.expense,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Net Balance',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(monthNet),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                monthNet >= 0 ? colors.income : colors.expense,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Filter Chips Bar ───────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // All Types
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedType == null,
                  onSelected: (_) => setState(() => _selectedType = null),
                ),
                const SizedBox(width: 6),
                // Income
                FilterChip(
                  avatar: Icon(Icons.arrow_downward_rounded,
                      size: 14,
                      color: _selectedType == TransactionType.income
                          ? Colors.white
                          : colors.income),
                  label: const Text('Income'),
                  selected: _selectedType == TransactionType.income,
                  selectedColor: colors.income,
                  labelStyle: TextStyle(
                    color: _selectedType == TransactionType.income
                        ? Colors.white
                        : null,
                    fontWeight: _selectedType == TransactionType.income
                        ? FontWeight.bold
                        : null,
                  ),
                  onSelected: (_) => setState(() {
                    _selectedType = _selectedType == TransactionType.income
                        ? null
                        : TransactionType.income;
                  }),
                ),
                const SizedBox(width: 6),
                // Expense
                FilterChip(
                  avatar: Icon(Icons.arrow_upward_rounded,
                      size: 14,
                      color: _selectedType == TransactionType.expense
                          ? Colors.white
                          : colors.expense),
                  label: const Text('Expense'),
                  selected: _selectedType == TransactionType.expense,
                  selectedColor: colors.expense,
                  labelStyle: TextStyle(
                    color: _selectedType == TransactionType.expense
                        ? Colors.white
                        : null,
                    fontWeight: _selectedType == TransactionType.expense
                        ? FontWeight.bold
                        : null,
                  ),
                  onSelected: (_) => setState(() {
                    _selectedType = _selectedType == TransactionType.expense
                        ? null
                        : TransactionType.expense;
                  }),
                ),
                const SizedBox(width: 8),

                // Wallet Filter Chip
                PopupMenuButton<String?>(
                  tooltip: 'Filter by Wallet',
                  initialValue: _selectedWalletId,
                  onSelected: (val) =>
                      setState(() => _selectedWalletId = val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.all_inclusive_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('All Wallets'),
                        ],
                      ),
                    ),
                    ...(walletsAsync.value ?? []).map((w) {
                      return PopupMenuItem<String?>(
                        value: w.id,
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                size: 18),
                            const SizedBox(width: 10),
                            Text(w.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  child: FilterChip(
                    avatar: const Icon(Icons.account_balance_wallet_outlined,
                        size: 14),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedWalletId != null
                              ? (walletsMap[_selectedWalletId]?.name ??
                                  'Wallet')
                              : 'Wallet',
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                    selected: _selectedWalletId != null,
                    onSelected: null,
                  ),
                ),
                const SizedBox(width: 6),

                // Category Filter Chip
                PopupMenuButton<String?>(
                  tooltip: 'Filter by Category',
                  initialValue: _selectedCategoryId,
                  onSelected: (val) =>
                      setState(() => _selectedCategoryId = val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.category_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('All Categories'),
                        ],
                      ),
                    ),
                    ...(categoriesAsync.value ?? []).map((c) {
                      final cColor = Color(c.color);
                      return PopupMenuItem<String?>(
                        value: c.id,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: cColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(c.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  child: FilterChip(
                    avatar: const Icon(Icons.category_outlined, size: 14),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCategoryId != null
                              ? (categoriesMap[_selectedCategoryId]?.name ??
                                  'Category')
                              : 'Category',
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                    selected: _selectedCategoryId != null,
                    onSelected: null,
                  ),
                ),

                // Clear Filters Reset Button
                if (_hasActiveFilters) ...[
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Reset'),
                    onPressed: _clearAllFilters,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 4),
          const Divider(height: 1),

          // ── Main Transactions List ────────────────────────────────
          Expanded(
            child: txsAsync.when(
              data: (allTxs) {
                // Apply month & criteria filters
                final filtered = allTxs.where((tx) {
                  if (DateFormatter.formatMonthKey(tx.date) != monthKey) {
                    return false;
                  }
                  if (_selectedType != null && tx.type != _selectedType) {
                    return false;
                  }
                  if (_selectedWalletId != null &&
                      tx.walletId != _selectedWalletId) {
                    return false;
                  }
                  if (_selectedCategoryId != null &&
                      tx.categoryId != _selectedCategoryId) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions found',
                    description:
                        'No transactions match your selected filters in ${DateFormatter.formatMonthYear(_currentMonth)}.',
                    actionLabel: 'Add Transaction',
                    onActionPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddEditTransactionScreen(),
                        ),
                      );
                    },
                  );
                }

                // Group transactions by date
                final Map<String, List<TransactionEntry>> grouped = {};
                for (final tx in filtered) {
                  final dateKey = DateFormatter.formatRelativeOrDate(tx.date);
                  grouped.putIfAbsent(dateKey, () => []).add(tx);
                }

                return ListView.builder(
                  padding: TabScreenWrapper.padding(context),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, groupIdx) {
                    final dateKey = grouped.keys.elementAt(groupIdx);
                    final dayTxs = grouped[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          child: Text(
                            dateKey,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                        Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colors.border),
                          ),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dayTxs.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, thickness: 1, color: colors.border),
                            itemBuilder: (context, idx) {
                              final tx = dayTxs[idx];
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
                                onLongPress: () async {
                                  final confirmed = await showConfirmDialog(
                                    context: context,
                                    title: 'Delete Transaction',
                                    message:
                                        'Are you sure you want to delete this transaction?',
                                  );
                                  if (confirmed && context.mounted) {
                                    await ref
                                        .read(transactionsRepositoryProvider)
                                        .deleteTransaction(tx.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Transaction deleted')),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      );
  }
}
