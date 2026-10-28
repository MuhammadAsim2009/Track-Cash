import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';

/// Shows an intelligent settlement dialog that checks wallet balance.
/// If the linked wallet does not have enough balance to settle (for "I have to give" debts),
/// or if the user wants to choose a different wallet, it presents all wallets
/// (including savings even if daily expense toggle is off).
Future<void> showSettleUdhaarDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Udhaar udhaar,
}) async {
  final walletsRepo = ref.read(walletsRepositoryProvider);
  final allWallets = await walletsRepo.getWallets();

  // Pre-calculate balances for all wallets
  final Map<String, int> walletBalances = {};
  for (final w in allWallets) {
    walletBalances[w.id] = await walletsRepo.getWalletBalance(w.id);
  }

  if (!context.mounted) return;

  final isGive = udhaar.direction == UdhaarDirection.give;
  final linkedWalletId = udhaar.walletId;
  final linkedBalance = linkedWalletId != null ? (walletBalances[linkedWalletId] ?? 0) : 0;
  final isShortOnLinkedWallet = isGive && linkedBalance < udhaar.amount;

  // Initial selection: if linked wallet has sufficient balance, default to it;
  // otherwise default to a wallet with enough balance (or first available).
  String? selectedWalletId = linkedWalletId;
  if (isGive && isShortOnLinkedWallet) {
    final solventWallet = allWallets.where((w) => (walletBalances[w.id] ?? 0) >= udhaar.amount).firstOrNull;
    if (solventWallet != null) {
      selectedWalletId = solventWallet.id;
    }
  }

  final selectedWallet = await showDialog<String?>(
    context: context,
    builder: (ctx) {
      String? currentSelectedId = selectedWalletId;
      return StatefulBuilder(
        builder: (context, setState) {
          final currentBal = currentSelectedId != null ? (walletBalances[currentSelectedId] ?? 0) : 0;
          final isCurrentInsufficient = isGive && currentBal < udhaar.amount;

          return AlertDialog(
            title: Text(isGive ? 'Pay Back Udhaar' : 'Settle Udhaar'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGive
                        ? 'You are paying back ${CurrencyFormatter.format(udhaar.amount)} to ${udhaar.personName}.'
                        : 'Confirm receiving ${CurrencyFormatter.format(udhaar.amount)} from ${udhaar.personName}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  if (isGive && isShortOnLinkedWallet && linkedWalletId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Linked wallet has insufficient balance (${CurrencyFormatter.format(linkedBalance)}). Please choose another wallet to pay from.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    isGive ? 'Pay from wallet:' : 'Deposit into wallet:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  ...allWallets.map((wallet) {
                    final balance = walletBalances[wallet.id] ?? 0;
                    final isInsufficient = isGive && balance < udhaar.amount;
                    final isSelected = wallet.id == currentSelectedId;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 6),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          wallet.type == WalletType.cash
                              ? Icons.money_rounded
                              : wallet.type == WalletType.savings
                                  ? Icons.savings_rounded
                                  : Icons.account_balance_wallet_rounded,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Row(
                          children: [
                            Text(
                              wallet.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            if (wallet.type == WalletType.savings) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Savings',
                                  style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          'Available: ${CurrencyFormatter.format(balance)}',
                          style: TextStyle(
                            color: isInsufficient ? Colors.red.shade700 : null,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                        ),
                        onTap: () {
                          setState(() => currentSelectedId = wallet.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isCurrentInsufficient
                    ? null
                    : () => Navigator.of(ctx).pop(currentSelectedId ?? ''),
                child: const Text('Confirm Settlement'),
              ),
            ],
          );
        },
      );
    },
  );

  if (selectedWallet != null && selectedWallet.isNotEmpty && context.mounted) {
    await ref.read(udhaarRepositoryProvider).markAsSettled(
          udhaar.id,
          settleWalletId: selectedWallet,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked ${udhaar.personName} as settled successfully'),
        ),
      );
    }
  }
}
