import 'package:flutter/material.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// One macro rendered as a labelled progress bar of logged-against-target.
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.logged,
    required this.target,
    required this.color,
  });

  final String label;
  final num logged;
  final num target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A zero target cannot be "filled"; showing a full bar would imply the
    // meal was met when there was nothing to meet.
    final ratio = target <= 0
        ? 0.0
        : (logged / target).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            Text(
              '${NutritionFormat.amount(logged)}/'
              '${NutritionFormat.grams(target)}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// The three macros of a target, side by side.
class MacroBreakdown extends StatelessWidget {
  const MacroBreakdown({super.key, required this.logged, required this.target});

  final NutritionTarget logged;
  final NutritionTarget target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        MacroBar(
          label: 'Protein',
          logged: logged.macros.proteinG,
          target: target.macros.proteinG,
          color: scheme.primary,
        ),
        const SizedBox(height: 12),
        MacroBar(
          label: 'Carbs',
          logged: logged.macros.carbsG,
          target: target.macros.carbsG,
          color: scheme.tertiary,
        ),
        const SizedBox(height: 12),
        MacroBar(
          label: 'Fat',
          logged: logged.macros.fatG,
          target: target.macros.fatG,
          color: scheme.secondary,
        ),
      ],
    );
  }
}

/// A compact, single-line macro summary: "P 40 · C 60 · F 20".
class MacroSummaryLine extends StatelessWidget {
  const MacroSummaryLine({super.key, required this.target, this.style});

  final NutritionTarget target;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'P ${NutritionFormat.amount(target.macros.proteinG)} · '
      'C ${NutritionFormat.amount(target.macros.carbsG)} · '
      'F ${NutritionFormat.amount(target.macros.fatG)}',
      style:
          style ??
          theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
    );
  }
}
