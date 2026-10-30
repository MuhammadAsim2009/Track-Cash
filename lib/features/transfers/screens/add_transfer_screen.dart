import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/money_input_field.dart';

/// Screen for recording a money transfer between two wallets.
class AddTransferScreen extends ConsumerStatefulWidget {
  const AddTransferScreen({super.key});

  @override
  ConsumerState<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends ConsumerState<AddTransferScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  static const _uuid = Uuid();

  String? _fromWalletId;
  String? _toWalletId;
  DateTime _selectedDate = DateTime.now();
  String? _errorText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  IconData _getWalletIcon(WalletType? type) => switch (type) {
        WalletType.cash => Icons.payments_outlined,
        WalletType.savings => Icons.account_balance_outlined,
        WalletType.mobileWallet => Icons.phone_android_outlined,
        null => Icons.account_balance_wallet_outlined,
      };

  void _swapWallets() {
    setState(() {
      final temp = _fromWalletId;
      _fromWalletId = _toWalletId;
      _toWalletId = temp;
    });
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
      setState(() => _errorText = 'Amount must be greater than 0');
      return;
    }
    setState(() => _errorText = null);

    if (_fromWalletId == null || _toWalletId == null) {
      AppToast.warning(context, 'Please select both source and destination wallets');
      return;
    }

    if (_fromWalletId == _toWalletId) {
      AppToast.warning(context, 'From and To wallets must be different');
      return;
    }

    // Strictly validate that source wallet has sufficient balance
    final walletsRepo = ref.read(walletsRepositoryProvider);
    final sourceBalance = await walletsRepo.getWalletBalance(_fromWalletId!);
    if (!mounted) return;
    if (amount > sourceBalance) {
      final walletList = ref.read(walletsStreamProvider).value ?? [];
      final fromWallet =
          walletList.where((w) => w.id == _fromWalletId).firstOrNull;
      final walletName = fromWallet?.name ?? 'Source wallet';
      final errorMsg =
          'Insufficient balance in $walletName! Available: ${CurrencyFormatter.format(sourceBalance)}';
      setState(() => _errorText = errorMsg);
      AppToast.error(context, errorMsg);
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final currentUserId = ref.read(currentUserIdProvider);
    final transfer = Transfer(
      id: _uuid.v4(),
      userId: currentUserId,
      fromWalletId: _fromWalletId!,
      toWalletId: _toWalletId!,
      amount: amount,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      date: _selectedDate,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(transfersRepositoryProvider).addTransfer(transfer);

    if (!mounted) return;
    AppToast.success(context, 'Transfer recorded successfully');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final walletsAsync = ref.watch(walletsStreamProvider);
    final parsedAmount = CurrencyFormatter.parse(_amountController.text);

    final walletsMap = {
      for (final w in walletsAsync.value ?? <Wallet>[]) w.id: w
    };
    final fromWallet = walletsMap[_fromWalletId];
    final toWallet = walletsMap[_toWalletId];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Money'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Hero Card
              Card(
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
                      Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Transfer Amount',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MoneyInputField(
                        controller: _amountController,
                        labelText: 'Amount (PKR)',
                        hintText: '0',
                        errorText: _errorText,
                        autofocus: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Source and Destination Wallets Card
              walletsAsync.when(
                data: (wallets) {
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
                          // Header with Swap button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select Accounts',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_fromWalletId != null && _toWalletId != null)
                                TextButton.icon(
                                  onPressed: _swapWallets,
                                  icon: const Icon(Icons.swap_vert_rounded,
                                      size: 16),
                                  label: const Text('Swap'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // From Wallet
                          Text(
                            'From (Source)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: wallets.map((w) {
                                final isSelected = _fromWalletId == w.id;
                                final bal = ref.watch(walletBalanceProvider(w.id)).value ?? w.openingBalance;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    avatar: Icon(_getWalletIcon(w.type),
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : theme.colorScheme.primary),
                                    label: Text('${w.name} (${CurrencyFormatter.format(bal)})'),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() {
                                        _fromWalletId = w.id;
                                        _errorText = null;
                                        if (_toWalletId == w.id) {
                                          _toWalletId = null;
                                        }
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // To Wallet
                          Text(
                            'To (Destination)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: wallets.map((w) {
                                final isSelected = _toWalletId == w.id;
                                final isSame = _fromWalletId == w.id;
                                final bal = ref.watch(walletBalanceProvider(w.id)).value ?? w.openingBalance;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    avatar: Icon(_getWalletIcon(w.type),
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : colors.income),
                                    label: Text('${w.name} (${CurrencyFormatter.format(bal)})'),
                                    selected: isSelected,
                                    onSelected: isSame
                                        ? null
                                        : (_) {
                                            setState(() => _toWalletId = w.id);
                                          },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading wallets: $e'),
              ),
              const SizedBox(height: 16),

              // Live Flow Preview Banner
              if (fromWallet != null && toWallet != null && parsedAmount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sync_alt_rounded,
                          color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Transferring ${CurrencyFormatter.format(parsedAmount)} from ${fromWallet.name} to ${toWallet.name}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Date & Note Details
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Transfer Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(DateFormatter.formatDate(_selectedDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _noteController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          hintText: 'e.g. ATM withdrawal, savings transfer',
                          prefixIcon: Icon(Icons.edit_note_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _isSaving ? 'Processing...' : 'Confirm Transfer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
