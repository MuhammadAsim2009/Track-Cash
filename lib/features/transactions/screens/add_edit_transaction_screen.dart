import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_resolver.dart';
import '../../../data/fake/fake_seed_data.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/money_input_field.dart';

/// Screen for creating or editing an Income/Expense transaction.
class AddEditTransactionScreen extends ConsumerStatefulWidget {
  const AddEditTransactionScreen({
    super.key,
    this.initialTransaction,
    this.initialType,
  });

  final TransactionEntry? initialTransaction;
  final TransactionType? initialType;

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  static const _uuid = Uuid();

  late TransactionType _selectedType;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  String? _amountError;
  bool _isSaving = false;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;
    if (tx != null) {
      _selectedType = tx.type;
      _amountController.text = tx.amount.toString();
      _selectedWalletId = tx.walletId;
      _selectedCategoryId = tx.categoryId;
      _selectedDate = tx.date;
      _noteController.text = tx.note ?? '';
    } else {
      _selectedType = widget.initialType ?? TransactionType.expense;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      setState(() => _amountError = 'Please enter an amount greater than 0');
      return;
    }
    setState(() => _amountError = null);

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    // Strictly validate that an expense does not make the wallet balance negative
    if (_selectedType == TransactionType.expense) {
      final walletList = ref.read(walletsStreamProvider).value ?? [];
      final selectedWallet =
          walletList.where((w) => w.id == _selectedWalletId).firstOrNull;

      // Block expense on a savings wallet that is excluded from daily expense
      if (selectedWallet != null &&
          selectedWallet.type == WalletType.savings &&
          !selectedWallet.countInDailyExpense) {
        const errorMsg =
            'Savings wallet is excluded from daily expense. Enable the Daily toggle to use it.';
        setState(() => _amountError = errorMsg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(errorMsg),
            backgroundColor: Colors.orange.shade700,
          ),
        );
        return;
      }

      final walletsRepo = ref.read(walletsRepositoryProvider);
      final currentBalance =
          await walletsRepo.getWalletBalance(_selectedWalletId!);
      // If editing an existing expense from the same wallet, add back its previous amount
      final effectiveBalance = _isEditing &&
              widget.initialTransaction?.type == TransactionType.expense &&
              widget.initialTransaction?.walletId == _selectedWalletId
          ? currentBalance + widget.initialTransaction!.amount
          : currentBalance;

      if (!mounted) return;
      if (amount > effectiveBalance) {
        final walletName = selectedWallet?.name ?? 'Selected wallet';
        final errorMsg =
            'Insufficient balance in $walletName! Available: ${CurrencyFormatter.format(effectiveBalance)}';
        setState(() => _amountError = errorMsg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final txRepo = ref.read(transactionsRepositoryProvider);

    if (_isEditing) {
      final updated = widget.initialTransaction!.copyWith(
        walletId: _selectedWalletId,
        categoryId: _selectedCategoryId,
        type: _selectedType,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: _selectedDate,
        updatedAt: now,
      );
      await txRepo.updateTransaction(updated);
    } else {
      final newTx = TransactionEntry(
        id: _uuid.v4(),
        userId: kDemoUserId,
        walletId: _selectedWalletId!,
        categoryId: _selectedCategoryId!,
        type: _selectedType,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: _selectedDate,
        createdAt: now,
        updatedAt: now,
      );
      await txRepo.addTransaction(newTx);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Transaction updated successfully'
            : 'Transaction added successfully'),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final tx = widget.initialTransaction;
    if (tx == null) return;

    // Check if deleting this income would cause the wallet balance to go negative
    if (tx.type == TransactionType.income) {
      final walletsRepo = ref.read(walletsRepositoryProvider);
      final currentBalance = await walletsRepo.getWalletBalance(tx.walletId);
      final newBalance = currentBalance - tx.amount;

      if (newBalance < 0) {
        if (!mounted) return;
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'Warning: Balance Would Go Negative',
          message:
              'Deleting this income of ${CurrencyFormatter.format(tx.amount)} will cause the wallet balance to drop below 0 (short by ${CurrencyFormatter.format(newBalance.abs())}) because money was already transferred or spent.\n\nDo you want to delete this income and automatically revert dependent transfers/expenses so the balance does not become negative?',
          confirmLabel: 'Delete & Revert',
          cancelLabel: 'Cancel',
        );

        if (!confirmed || !mounted) return;

        await ref
            .read(transactionsRepositoryProvider)
            .deleteIncomeAndRevertDependent(tx.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income deleted and dependent transfers/expenses reverted'),
          ),
        );
        Navigator.of(context).pop();
        return;
      }
    }

    if (!mounted) return;
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete this transaction?',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(transactionsRepositoryProvider)
        .deleteTransaction(tx.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final walletsAsync = ref.watch(walletsStreamProvider);
    final categoryType = _selectedType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    final categoriesAsync = ref.watch(categoriesStreamProvider(categoryType));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Income / Expense Toggle
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedType = set.first;
                    // Reset selected category if type changes
                    _selectedCategoryId = null;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Amount Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MoneyInputField(
                        controller: _amountController,
                        labelText: _selectedType == TransactionType.income
                            ? 'Income Amount'
                            : 'Expense Amount',
                        errorText: _amountError,
                        autofocus: !_isEditing,
                      ),
                      const SizedBox(height: 12),
                      // Quick Amount Chips
                      Wrap(
                        spacing: 8,
                        children: [500, 1000, 2000, 5000].map((quick) {
                          return ActionChip(
                            label: Text('+${CurrencyFormatter.format(quick)}'),
                            onPressed: () {
                              final current = CurrencyFormatter.parse(
                                  _amountController.text);
                              _amountController.text =
                                  (current + quick).toString();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Wallet Selector
              Text('Wallet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              walletsAsync.when(
                data: (wallets) {
                  // For expense, exclude savings wallets with countInDailyExpense=false
                  final selectableWallets = _selectedType == TransactionType.expense
                      ? wallets.where((w) =>
                          !(w.type == WalletType.savings && !w.countInDailyExpense)).toList()
                      : wallets;

                  // Reset selection if the current wallet is no longer selectable
                  if (_selectedWalletId != null &&
                      !selectableWallets.any((w) => w.id == _selectedWalletId)) {
                    _selectedWalletId = null;
                  }
                  if (_selectedWalletId == null && selectableWallets.isNotEmpty) {
                    _selectedWalletId = selectableWallets.first.id;
                  }

                  if (selectableWallets.isEmpty) {
                    return const Text(
                      'No wallets available for this transaction type.',
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: selectableWallets.map((w) {
                        final isSelected = _selectedWalletId == w.id;
                        final balance = ref.watch(walletBalanceProvider(w.id)).value ?? w.openingBalance;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text('${w.name} (${CurrencyFormatter.format(balance)})'),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedWalletId = w.id;
                                _amountError = null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load wallets: $e'),
              ),
              const SizedBox(height: 16),

              // Category Selector
              Text('Category', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Text('No categories available.');
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      final icon = IconResolver.getIcon(cat.icon);
                      final catColor = Color(cat.color);

                      return FilterChip(
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : catColor.withValues(alpha: 0.2),
                          child: Icon(
                            icon,
                            size: 14,
                            color: isSelected ? Colors.white : catColor,
                          ),
                        ),
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedCategoryId = cat.id);
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load categories: $e'),
              ),
              const SizedBox(height: 16),

              // Date Picker Field
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    DateFormatter.formatDate(_selectedDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note Field
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Biryani with friends',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _selectedType == TransactionType.income
                      ? colors.income
                      : theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Save Transaction',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
