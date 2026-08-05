import 'package:flutter/material.dart';

/// A compact marker for the plan's own section grouping (`PRIMER PLATO`,
/// `POSTRE`), shown instead of repeating the words on every row.
///
/// Shared between the diet day screen and the day plan screen: both list
/// per-component rows that need the same grouping cue.
class SectionDot extends StatelessWidget {
  const SectionDot({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDessert = label.toUpperCase().contains('POSTRE');
    return Tooltip(
      message: label,
      child: Icon(
        isDessert ? Icons.icecream_outlined : Icons.dinner_dining_outlined,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
