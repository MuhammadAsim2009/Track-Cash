import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/tab_screen_wrapper.dart';
import '../../../widgets/udhaar_tile.dart';
import 'add_edit_udhaar_screen.dart';
import '../widgets/settle_udhaar_dialog.dart';

/// Complete Udhaar Screen with "I have to give" and "I have to take" tabs.
class UdhaarScreen extends ConsumerStatefulWidget {
  const UdhaarScreen({super.key});

  @override
  ConsumerState<UdhaarScreen> createState() => _UdhaarScreenState();
}

class _UdhaarScreenState extends ConsumerState<UdhaarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showSettled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final udhaarAsync = ref.watch(udhaarStreamProvider);

    return udhaarAsync.when(
      data: (allUdhaar) {
          // Separate by direction
          final giveList = allUdhaar
              .where((u) => u.direction == UdhaarDirection.give)
              .toList();
          final takeList = allUdhaar
              .where((u) => u.direction == UdhaarDirection.take)
              .toList();

          // Totals for pending
          final totalGive = giveList
              .where((u) => u.status == UdhaarStatus.pending)
              .fold<int>(0, (sum, u) => sum + u.amount);
          final totalTake = takeList
              .where((u) => u.status == UdhaarStatus.pending)
              .fold<int>(0, (sum, u) => sum + u.amount);

          return Column(
            children: [
              // Summary Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.expense.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I have to give',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(totalGive),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.expense,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.income.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I have to take',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.income,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(totalTake),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.income,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // TabBar and Filter
              Container(
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'To Give (Owed)'),
                          Tab(text: 'To Take (Lent)'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showSettled
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank,
                        size: 20,
                      ),
                      tooltip: _showSettled
                          ? 'Hide settled'
                          : 'Show settled records',
                      onPressed: () {
                        setState(() => _showSettled = !_showSettled);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // TabBarView for Give and Take
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUdhaarList(
                      list: giveList,
                      direction: UdhaarDirection.give,
                      emptyTitle: 'No debts to give',
                      emptyDescription:
                          'You have no pending borrowed amounts recorded.',
                    ),
                    _buildUdhaarList(
                      list: takeList,
                      direction: UdhaarDirection.take,
                      emptyTitle: 'No money to collect',
                      emptyDescription:
                          'You have no pending lent amounts recorded.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading udhaar: $e')),
      );
  }

  Widget _buildUdhaarList({
    required List<Udhaar> list,
    required UdhaarDirection direction,
    required String emptyTitle,
    required String emptyDescription,
  }) {
    final filtered = list.where((u) {
      if (!_showSettled && u.status == UdhaarStatus.settled) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyStateView(
        icon: Icons.handshake_outlined,
        title: emptyTitle,
        description: emptyDescription,
        actionLabel: 'Add Udhaar',
        onActionPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditUdhaarScreen(initialDirection: direction),
            ),
          );
        },
      );
    }

    final walletsMap = {
      for (final w in ref.watch(walletsStreamProvider).value ?? <Wallet>[]) w.id: w.name
    };

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: TabScreenWrapper.bottomPadding(context)),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final walletName = item.walletId != null ? walletsMap[item.walletId] : null;
        return UdhaarTile(
          udhaar: item,
          walletName: walletName,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditUdhaarScreen(initialUdhaar: item),
              ),
            );
          },
          onSettle: () async {
            await showSettleUdhaarDialog(
              context: context,
              ref: ref,
              udhaar: item,
            );
          },
          onDelete: () async {
            final confirmed = await showConfirmDialog(
              context: context,
              title: 'Delete Udhaar',
              message:
                  'Are you sure you want to delete this udhaar record with ${item.personName}?',
            );
            if (confirmed && context.mounted) {
              await ref.read(udhaarRepositoryProvider).deleteUdhaar(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Udhaar record deleted')),
                );
              }
            }
          },
        );
      },
    );
  }
}
