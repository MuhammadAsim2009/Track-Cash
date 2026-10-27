import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standard input field for integer money amounts with "Rs" prefix.
class MoneyInputField extends StatelessWidget {
  const MoneyInputField({
    super.key,
    required this.controller,
    this.labelText = 'Amount',
    this.hintText = '0',
    this.errorText,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        prefixText: 'Rs  ',
        prefixStyle: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onChanged: onChanged,
    );
  }
}
