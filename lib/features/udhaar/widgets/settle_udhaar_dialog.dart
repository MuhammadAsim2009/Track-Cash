import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/money_input_field.dart';

/// Shows an intelligent partial or full settlement dialog for an [udhaar] record.
/// Allows the user to settle the full remaining amount or enter a partial payment,
/// and choose which wallet the payment should come from or go into.
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
  final remaining = udhaar.remainingAmount;
  final linkedWalletId = udhaar.walletId;

  // Initial selection: prefer linked wallet if solvent, or pick first wallet
  String? selectedWalletId = linkedWalletId ?? allWallets.firstOrNull?.id;
  if (isGive && selectedWalletId != null) {
    final balance = walletBalances[selectedWalletId] ?? 0;
    if (balance <= 0) {
      final solvent = allWallets.where((w) => (walletBalances[w.id] ?? 0) > 0).firstOrNull;
      if (solvent != null) selectedWalletId = solvent.id;
    }
  }

  final result = await showDialog<({String walletId, int amount})?>(
    context: context,
    builder: (ctx) {
      String? currentSelectedId = selectedWalletId;
      bool isFullSettlement = true;
      final amountController = TextEditingController(text: remaining.toString());
      String? customAmountError;

      return StatefulBuilder(
        builder: (context, setState) {
          final currentBal = currentSelectedId != null ? (walletBalances[currentSelectedId] ?? 0) : 0;
          final parsedAmount = isFullSettlement
              ? remaining
              : CurrencyFormatter.parse(amountController.text);

          final isInsufficient = isGive && currentBal < parsedAmount;

          return AlertDialog(
            title: Text(isGive ? 'Pay Back Udhaar' : 'Receive Udhaar Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total & Remaining summary banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Udhaar:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              CurrencyFormatter.format(udhaar.amount),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (udhaar.paidAmount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Already Settled:',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green.shade700,
                                    ),
                              ),
                              Text(
                                CurrencyFormatter.format(udhaar.paidAmount),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remaining Balance:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              CurrencyFormatter.format(remaining),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isGive ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Settlement Type Toggle (Full vs Partial)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Full Settlement')),
                          selected: isFullSettlement,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                isFullSettlement = true;
                                amountController.text = remaining.toString();
                                customAmountError = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Partial Payment')),
                          selected: !isFullSettlement,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                isFullSettlement = false;
                                customAmountError = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  // If Partial, show Money Input Field
                  if (!isFullSettlement) ...[
                    const SizedBox(height: 14),
                    MoneyInputField(
                      controller: amountController,
                      labelText: isGive ? 'Repayment Amount' : 'Received Amount',
                      errorText: customAmountError,
                      onChanged: (_) {
                        final val = CurrencyFormatter.parse(amountController.text);
                        setState(() {
                          if (val <= 0) {
                            customAmountError = 'Enter an amount > 0';
                          } else if (val > remaining) {
                            customAmountError = 'Cannot exceed remaining ${CurrencyFormatter.format(remaining)}';
                          } else {
                            customAmountError = null;
                          }
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  Text(
                    isGive ? 'Pay from wallet:' : 'Deposit into wallet:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  ...allWallets.map((wallet) {
                    final balance = walletBalances[wallet.id] ?? 0;
                    final isWalletInsufficient = isGive && balance < parsedAmount;
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
                            Flexible(
                              child: Text(
                                wallet.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
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
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          'Available: ${CurrencyFormatter.format(balance)}',
                          style: TextStyle(
                            color: isWalletInsufficient ? Colors.red.shade700 : null,
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
                onPressed: (isInsufficient ||
                        parsedAmount <= 0 ||
                        parsedAmount > remaining ||
                        currentSelectedId == null)
                    ? null
                    : () {
                        Navigator.of(ctx).pop((
                          walletId: currentSelectedId!,
                          amount: parsedAmount,
                        ));
                      },
                child: Text(isFullSettlement
                    ? 'Confirm Settlement'
                    : 'Pay ${CurrencyFormatter.format(parsedAmount)}'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != null && context.mounted) {
    final payAmount = result.amount;
    final settleWalletId = result.walletId;

    await ref.read(udhaarRepositoryProvider).recordPartialPayment(
          udhaar.id,
          amount: payAmount,
          settleWalletId: settleWalletId,
        );

    if (context.mounted) {
      final isNowFullySettled = (udhaar.paidAmount + payAmount) >= udhaar.amount;
      if (isNowFullySettled) {
        AppToast.success(
          context,
          'Udhaar with ${udhaar.personName} fully settled! ✓',
        );
      } else {
        final left = udhaar.amount - (udhaar.paidAmount + payAmount);
        AppToast.success(
          context,
          'Paid ${CurrencyFormatter.format(payAmount)}. Remaining: ${CurrencyFormatter.format(left)}',
        );
      }
    }
  }
}
