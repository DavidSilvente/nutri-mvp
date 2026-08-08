import 'package:flutter/material.dart';
import 'package:nutri_mvp/core/theme/adherence_palette.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';

/// A small status pill for a meal or a day.
///
/// Always pairs colour with an icon and a word: colour alone would exclude
/// colour-blind users and would be unreadable in a screenshot.
class AdherenceChip extends StatelessWidget {
  const AdherenceChip.meal(MealAdherenceStatus status, {super.key})
    : _mealStatus = status,
      _dayStatus = null,
      _entryCount = null;

  const AdherenceChip.day(
    DayAdherenceStatus status, {
    super.key,
    int? entryCount,
  }) : _dayStatus = status,
       _mealStatus = null,
       _entryCount = entryCount;

  final MealAdherenceStatus? _mealStatus;
  final DayAdherenceStatus? _dayStatus;

  /// How many entries (linked or not) were logged for the day. Only
  /// meaningful alongside [_dayStatus]; `null` when unknown, which existing
  /// call sites keep passing and render exactly as before.
  final int? _entryCount;

  @override
  Widget build(BuildContext context) {
    final palette = AdherencePalette.of(context);
    final mealStatus = _mealStatus;
    final dayStatus = _dayStatus;

    final style = mealStatus != null
        ? palette.forMeal(mealStatus)
        : palette.forDay(dayStatus!);
    final isEmptyUnder =
        dayStatus == DayAdherenceStatus.under && _entryCount == 0;
    final label = mealStatus != null
        ? palette.mealLabel(mealStatus)
        : isEmptyUnder
        ? '${style.label} · nothing logged'
        : style.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.container,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.onContainer),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: style.onContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
