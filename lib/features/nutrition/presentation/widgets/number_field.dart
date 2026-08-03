import 'package:flutter/material.dart';

/// A numeric text field shared by every macro/energy input form in this
/// feature: the "add an alternative" dialog and the saved-meal create/edit
/// dialog both need the same decimal keyboard and the same "required,
/// non-negative number" validation. Hoisted here so those forms can't drift
/// into three slightly different rules for what counts as a valid gram or
/// kcal amount.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.label,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final parsed = num.tryParse(value);
        if (parsed == null || parsed < 0) return 'Must be a number >= 0';
        return null;
      },
    );
  }
}
