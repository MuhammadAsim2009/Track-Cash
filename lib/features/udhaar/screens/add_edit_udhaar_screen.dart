import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/money_input_field.dart';

/// Screen for adding or editing an Udhaar record.
class AddEditUdhaarScreen extends ConsumerStatefulWidget {
  const AddEditUdhaarScreen({
    super.key,
    this.initialUdhaar,
    this.initialDirection,
  });

  final Udhaar? initialUdhaar;
  final UdhaarDirection? initialDirection;

  @override
  ConsumerState<AddEditUdhaarScreen> createState() =>
      _AddEditUdhaarScreenState();
}

class _AddEditUdhaarScreenState extends ConsumerState<AddEditUdhaarScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  static const _uuid = Uuid();

  late UdhaarDirection _direction;
  late DateTime _dueDate;
  int? _selectedPresetDays;
  String? _selectedWalletId;
  String? _nameError;
  String? _amountError;
  bool _isSaving = false;

  bool get _isEditing => widget.initialUdhaar != null;

  @override
  void initState() {
    super.initState();
    final u = widget.initialUdhaar;
    if (u != null) {
      _nameController.text = u.personName;
      _amountController.text = u.amount.toString();
      _direction = u.direction;
      _dueDate = u.dueDate;
      _noteController.text = u.note ?? '';
      _selectedWalletId = u.walletId;
    } else {
      _direction = widget.initialDirection ?? UdhaarDirection.take;
      _dueDate = DateTime.now().add(const Duration(days: 7));
      _selectedPresetDays = 7;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _selectedPresetDays = null;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Person name is required');
      return;
    }
    setState(() => _nameError = null);

    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      setState(() => _amountError = 'Amount must be greater than 0');
      return;
    }
    setState(() => _amountError = null);

    if (_selectedWalletId == null) {
      AppToast.warning(context, 'Please select a wallet');
      return;
    }

    // Validation for "I have to take" (lent money): money leaves wallet, cannot go negative
    if (_direction == UdhaarDirection.take) {
      final walletsRepo = ref.read(walletsRepositoryProvider);
      final currentBalance =
          await walletsRepo.getWalletBalance(_selectedWalletId!);
      // If editing existing 'take' udhaar from same wallet, add back previous amount
      final effectiveBalance = _isEditing &&
              widget.initialUdhaar?.direction == UdhaarDirection.take &&
              widget.initialUdhaar?.walletId == _selectedWalletId &&
              widget.initialUdhaar?.status == UdhaarStatus.pending
          ? currentBalance + widget.initialUdhaar!.amount
          : currentBalance;

      if (!mounted) return;
      if (amount > effectiveBalance) {
        final walletList = ref.read(walletsStreamProvider).value ?? [];
        final selectedWallet =
            walletList.where((w) => w.id == _selectedWalletId).firstOrNull;
        final walletName = selectedWallet?.name ?? 'Selected wallet';
        final errorMsg =
            'Insufficient balance in $walletName! Available: ${CurrencyFormatter.format(effectiveBalance)}';
        setState(() => _amountError = errorMsg);
        AppToast.error(context, errorMsg);
        return;
      }
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final repo = ref.read(udhaarRepositoryProvider);

    if (_isEditing) {
      final updated = widget.initialUdhaar!.copyWith(
        walletId: _selectedWalletId,
        personName: name,
        amount: amount,
        direction: _direction,
        dueDate: _dueDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        updatedAt: now,
      );
      await repo.updateUdhaar(updated);
    } else {
      final currentUserId = ref.read(currentUserIdProvider);
      final newUdhaar = Udhaar(
        id: _uuid.v4(),
        userId: currentUserId,
        walletId: _selectedWalletId,
        personName: name,
        amount: amount,
        direction: _direction,
        dueDate: _dueDate,
        status: UdhaarStatus.pending,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await repo.addUdhaar(newUdhaar);
    }

    if (!mounted) return;
    AppToast.success(
      context,
      _isEditing
          ? 'Udhaar updated successfully'
          : 'Udhaar added successfully',
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete Udhaar',
      message: 'Are you sure you want to delete this record?',
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(udhaarRepositoryProvider)
        .deleteUdhaar(widget.initialUdhaar!.id);

    if (!mounted) return;
    AppToast.info(context, 'Udhaar deleted');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Udhaar' : 'Add Udhaar'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Direction Toggle
              SegmentedButton<UdhaarDirection>(
                segments: [
                  ButtonSegment(
                    value: UdhaarDirection.take,
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'I have to take',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '(I am giving)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _direction == UdhaarDirection.take
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: _direction == UdhaarDirection.take
                                  ? Theme.of(context).colorScheme.onSecondaryContainer
                                  : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.call_received),
                  ),
                  ButtonSegment(
                    value: UdhaarDirection.give,
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'I have to give',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '(I am taking)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _direction == UdhaarDirection.give
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: _direction == UdhaarDirection.give
                                  ? Theme.of(context).colorScheme.onSecondaryContainer
                                  : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.call_made),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (set) {
                  setState(() => _direction = set.first);
                },
              ),
              const SizedBox(height: 20),

              // Person Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Person Name',
                  hintText: 'e.g. Bilal Ahmed',
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: _nameError,
                ),
                autofocus: !_isEditing,
              ),
              const SizedBox(height: 16),

              // Amount
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MoneyInputField(
                    controller: _amountController,
                    labelText: 'Amount',
                    errorText: _amountError,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Wallet Selector
              Text('Wallet', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ref.watch(walletsStreamProvider).when(
                data: (wallets) {
                  // For "take" (giving money out), exclude savings if countInDailyExpense=false
                  final selectableWallets = _direction == UdhaarDirection.take
                      ? wallets.where((w) =>
                          !(w.type == WalletType.savings && !w.countInDailyExpense)).toList()
                      : wallets;

                  if (_selectedWalletId != null &&
                      !selectableWallets.any((w) => w.id == _selectedWalletId)) {
                    _selectedWalletId = null;
                  }
                  if (_selectedWalletId == null && selectableWallets.isNotEmpty) {
                    _selectedWalletId = selectableWallets.first.id;
                  }

                  if (selectableWallets.isEmpty) {
                    return const Text(
                      'No wallets available.',
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

              // Due Date Picker
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date (for reminder)',
                    prefixIcon: Icon(Icons.alarm_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(DateFormatter.formatDate(_dueDate)),
                ),
              ),
              const SizedBox(height: 8),

              // Quick preset chips for due dates
              Wrap(
                spacing: 8,
                children: [
                  (label: 'Tomorrow', days: 1),
                  (label: 'In 3 days', days: 3),
                  (label: 'In 1 week', days: 7),
                  (label: 'In 1 month', days: 30),
                ].map((preset) {
                  final targetDate = DateTime.now().add(Duration(days: preset.days));
                  final isSelected = _selectedPresetDays == preset.days ||
                      _isSameDay(_dueDate, targetDate);

                  return ChoiceChip(
                    label: Text(preset.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _dueDate = DateTime.now().add(Duration(days: preset.days));
                        _selectedPresetDays = preset.days;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Lunch split / borrowed for bus',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Save Udhaar Record',
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
