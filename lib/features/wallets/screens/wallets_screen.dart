import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/money_input_field.dart';

/// Screen for managing all wallets: listing, creating, renaming, editing opening balance,
/// toggling daily expense participation, and safely deleting.
class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  static const _uuid = Uuid();

  IconData _getWalletIcon(WalletType type) => switch (type) {
        WalletType.cash => Icons.payments_outlined,
        WalletType.savings => Icons.account_balance_outlined,
        WalletType.mobileWallet => Icons.phone_android_outlined,
      };

  Color _getWalletColor(WalletType type, ThemeData theme) => switch (type) {
        WalletType.cash => const Color(0xFF10B981), // Emerald
        WalletType.savings => const Color(0xFF8B5CF6), // Purple
        WalletType.mobileWallet => const Color(0xFF3B82F6), // Blue
      };

  void _showAddEditWalletDialog([Wallet? walletToEdit]) {
    final isEditing = walletToEdit != null;
    final nameController = TextEditingController(text: walletToEdit?.name ?? '');
    final openingBalanceController = TextEditingController(
      text: isEditing ? walletToEdit.openingBalance.toString() : '0',
    );
    var selectedType = walletToEdit?.type ?? WalletType.cash;
    var countInDaily = walletToEdit?.countInDailyExpense ?? true;

    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);

            return AlertDialog(
              title: Text(isEditing ? 'Edit Wallet' : 'Add New Wallet'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wallet Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Wallet Name',
                          hintText: 'e.g., Main Cash, Meezan Bank, JazzCash',
                          prefixIcon: Icon(Icons.wallet_outlined, size: 20),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a wallet name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Wallet Type Selector
                      Text(
                        'Wallet Type',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: WalletType.values.map((type) {
                          final isSelected = selectedType == type;
                          final typeColor = _getWalletColor(type, theme);

                          return ChoiceChip(
                            avatar: Icon(
                              _getWalletIcon(type),
                              size: 16,
                              color: isSelected ? Colors.white : typeColor,
                            ),
                            label: Text(type.displayName),
                            selected: isSelected,
                            selectedColor: typeColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedType = type;
                                  // Default savings to false for daily expense if desired
                                  if (type == WalletType.savings && !isEditing) {
                                    countInDaily = false;
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Opening Balance
                      MoneyInputField(
                        controller: openingBalanceController,
                        labelText: 'Opening Balance',
                      ),
                      const SizedBox(height: 16),

                      // Count In Daily Expense Toggle (Especially useful for savings)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Count in Daily Balance',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          countInDaily
                              ? 'Included in total available balance'
                              : 'Excluded from total available balance',
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: countInDaily,
                        onChanged: (val) {
                          setModalState(() => countInDaily = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final name = nameController.text.trim();
                    final opening = CurrencyFormatter.parse(openingBalanceController.text);
                    final now = DateTime.now();
                    final userId = ref.read(currentUserIdProvider);

                    Navigator.of(ctx).pop();

                    final repo = ref.read(walletsRepositoryProvider);

                    if (isEditing) {
                      final updated = walletToEdit.copyWith(
                        name: name,
                        type: selectedType,
                        openingBalance: opening,
                        countInDailyExpense: countInDaily,
                        updatedAt: now,
                        synced: false,
                      );
                      await repo.updateWallet(updated);
                      if (context.mounted) {
                        AppToast.success(context, 'Wallet updated successfully');
                      }
                    } else {
                      final newWallet = Wallet(
                        id: _uuid.v4(),
                        userId: userId,
                        name: name,
                        type: selectedType,
                        openingBalance: opening,
                        currentBalance: opening,
                        countInDailyExpense: countInDaily,
                        createdAt: now,
                        updatedAt: now,
                      );
                      await repo.createWallet(newWallet);
                      if (context.mounted) {
                        AppToast.success(context, 'Wallet created successfully');
                      }
                    }

                    ref.invalidate(walletsStreamProvider);
                    ref.invalidate(totalBalanceProvider);
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Create Wallet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteWallet(Wallet wallet) async {
    // Guard 1: Cannot delete the only wallet
    final wallets = ref.read(walletsStreamProvider).value ?? [];
    if (wallets.length <= 1) {
      AppToast.warning(context, 'Cannot delete the only wallet in your account');
      return;
    }

    // Guard 2: Balance must be 0 before deletion
    final balance =
        await ref.read(walletsRepositoryProvider).getWalletBalance(wallet.id);
    if (!mounted) return;
    if (balance != 0) {
      AppToast.error(
        context,
        'Cannot delete "${wallet.name}" — balance must be 0 first.\n'
        'Current balance: ${CurrencyFormatter.format(balance)}',
      );
      return;
    }

    // Confirm then soft-delete
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete Wallet',
      message:
          'Are you sure you want to delete "${wallet.name}"? Past transactions and transfers will remain visible with this wallet\'s name.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;

    await ref.read(walletsRepositoryProvider).deleteWallet(wallet.id);

    ref.invalidate(walletsStreamProvider);
    ref.invalidate(totalBalanceProvider);
    ref.invalidate(allWalletsMapProvider);

    if (mounted) {
      AppToast.info(context, '"${wallet.name}" deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletsAsync = ref.watch(walletsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Wallet',
            onPressed: () => _showAddEditWalletDialog(),
          ),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return EmptyStateView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Wallets Found',
              description: 'Add a wallet to start tracking your cash, bank, or mobile balances.',
              actionLabel: 'Add Wallet',
              onActionPressed: () => _showAddEditWalletDialog(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: wallets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));
              final balance = balanceAsync.value ?? wallet.openingBalance;
              final walletColor = _getWalletColor(wallet.type, theme);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Icon + Name + Balance
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: walletColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getWalletIcon(wallet.type),
                              color: walletColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        wallet.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: walletColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        wallet.type.displayName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: walletColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Opening: ${CurrencyFormatter.format(wallet.openingBalance)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(balance),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: balance < 0
                                      ? theme.colorScheme.error
                                      : null,
                                ),
                              ),
                              Text(
                                'Current Balance',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Bottom Action Strip: Toggle Daily + Edit + Delete
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Daily Expense Toggle
                          Row(
                            children: [
                              Switch.adaptive(
                                value: wallet.countInDailyExpense,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) async {
                                  final updated = wallet.copyWith(countInDailyExpense: val);
                                  await ref.read(walletsRepositoryProvider).updateWallet(updated);
                                  ref.invalidate(totalBalanceProvider);
                                  if (context.mounted) {
                                    AppToast.info(
                                      context,
                                      val
                                          ? '${wallet.name} counts towards daily balance'
                                          : '${wallet.name} excluded from daily balance',
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              Text(
                                wallet.countInDailyExpense ? 'Included in Daily' : 'Excluded',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: wallet.countInDailyExpense
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),

                          // Edit & Delete Buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _showAddEditWalletDialog(wallet),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: theme.colorScheme.error,
                                ),
                                tooltip: 'Delete',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _deleteWallet(wallet),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditWalletDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Wallet'),
      ),
    );
  }
}

