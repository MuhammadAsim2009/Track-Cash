import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/fake/fake_seed_data.dart';
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
    } else {
      _direction = widget.initialDirection ?? UdhaarDirection.take;
      _dueDate = DateTime.now().add(const Duration(days: 7));
    }
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
      setState(() => _dueDate = picked);
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

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final repo = ref.read(udhaarRepositoryProvider);

    if (_isEditing) {
      final updated = widget.initialUdhaar!.copyWith(
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
      final newUdhaar = Udhaar(
        id: _uuid.v4(),
        userId: kDemoUserId,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Udhaar updated successfully'
            : 'Udhaar added successfully'),
      ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Udhaar deleted')),
    );
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
                segments: const [
                  ButtonSegment(
                    value: UdhaarDirection.take,
                    label: Text('I have to take'),
                    icon: Icon(Icons.call_received),
                  ),
                  ButtonSegment(
                    value: UdhaarDirection.give,
                    label: Text('I have to give'),
                    icon: Icon(Icons.call_made),
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
                  ActionChip(
                    label: const Text('Tomorrow'),
                    onPressed: () => setState(() =>
                        _dueDate = DateTime.now().add(const Duration(days: 1))),
                  ),
                  ActionChip(
                    label: const Text('In 3 days'),
                    onPressed: () => setState(() =>
                        _dueDate = DateTime.now().add(const Duration(days: 3))),
                  ),
                  ActionChip(
                    label: const Text('In 1 week'),
                    onPressed: () => setState(() =>
                        _dueDate = DateTime.now().add(const Duration(days: 7))),
                  ),
                  ActionChip(
                    label: const Text('In 1 month'),
                    onPressed: () => setState(() =>
                        _dueDate = DateTime.now().add(const Duration(days: 30))),
                  ),
                ],
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
