import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state_view.dart';
import 'add_transfer_screen.dart';

/// Transfers and Transfer History screen matching docs/PRD.md and docs/app-flow.md.
class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  IconData _getWalletIcon(WalletType? type) => switch (type) {
        WalletType.cash => Icons.payments_outlined,
        WalletType.savings => Icons.account_balance_outlined,
        WalletType.mobileWallet => Icons.phone_android_outlined,
        null => Icons.account_balance_wallet_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final transfersAsync = ref.watch(transfersStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);

    final walletsMap = {
      for (final w in walletsAsync.value ?? <Wallet>[]) w.id: w
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers & History'),
      ),
      body: transfersAsync.when(
        data: (transfers) {
          if (transfers.isEmpty) {
            return EmptyStateView(
              icon: Icons.swap_horiz_rounded,
              title: 'No Transfers Recorded',
              description:
                  'Move money between cash, savings, and mobile wallets without affecting your budget.',
              actionLabel: 'New Transfer',
              onActionPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddTransferScreen()),
                );
              },
            );
          }

          final totalAmount =
              transfers.fold<int>(0, (sum, tr) => sum + tr.amount);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: transfers.length + 1,
            separatorBuilder: (_, index) =>
                index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Header Summary Card
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Transferred',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(totalAmount),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          '${transfers.length} transfers',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final tr = transfers[index - 1];
              final fromWallet = walletsMap[tr.fromWalletId];
              final toWallet = walletsMap[tr.toWalletId];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Wallets Path + Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Wallets path with icons
                          Expanded(
                            child: Row(
                              children: [
                                // From Wallet Pill
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getWalletIcon(fromWallet?.type),
                                          size: 14,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            fromWallet?.name ?? 'Wallet',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6.0),
                                  child: Icon(Icons.arrow_forward_rounded,
                                      size: 16, color: Colors.grey),
                                ),
                                // To Wallet Pill
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getWalletIcon(toWallet?.type),
                                          size: 14,
                                          color: colors.income,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            toWallet?.name ?? 'Wallet',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Amount
                          Text(
                            CurrencyFormatter.format(tr.amount),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Divider line
                      Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),
                      const SizedBox(height: 8),
                      // Bottom Row: Date + Notes + Delete
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 13, color: colors.textSecondary),
                              const SizedBox(width: 5),
                              Text(
                                DateFormatter.formatDate(tr.date),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 18, color: colors.expense.withValues(alpha: 0.8)),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Delete Transfer',
                            onPressed: () async {
                              final confirmed = await showConfirmDialog(
                                context: context,
                                title: 'Delete Transfer',
                                message:
                                    'Are you sure you want to delete this transfer of ${CurrencyFormatter.format(tr.amount)}?',
                              );
                              if (confirmed) {
                                await ref
                                    .read(transfersRepositoryProvider)
                                    .deleteTransfer(tr.id);
                              }
                            },
                          ),
                        ],
                      ),
                      if (tr.note != null && tr.note!.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 13, color: colors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  tr.note!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading transfers: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transfers_fab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransferScreen()),
          );
        },
        tooltip: 'New Transfer',
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('Transfer'),
      ),
    );
  }
}
