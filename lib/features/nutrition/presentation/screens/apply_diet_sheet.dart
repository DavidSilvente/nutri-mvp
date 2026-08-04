import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/day_format.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/calendar_month.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// How many days a diet gets applied to in one go.
enum ApplyRange {
  singleDay,
  restOfWeek,
  restOfMonth;

  String get label => switch (this) {
    ApplyRange.singleDay => 'This day only',
    ApplyRange.restOfWeek => 'Rest of the week',
    ApplyRange.restOfMonth => 'Rest of the month',
  };
}

/// Picks one of the user's diets and drops it onto the calendar.
///
/// Planning a month one meal at a time is the kind of chore that kills the
/// habit, so the common cases — this day, this week, this month — are one tap.
///
/// Each day receives the menu the diet prescribes for ITS weekday, so a plan
/// with a different Sunday lands correctly rather than having one day's meals
/// stamped across the range.
class ApplyDietSheet extends ConsumerStatefulWidget {
  const ApplyDietSheet({super.key, required this.anchorDay});

  /// The day the range is measured from.
  final NutritionDay anchorDay;

  @override
  ConsumerState<ApplyDietSheet> createState() => _ApplyDietSheetState();
}

class _ApplyDietSheetState extends ConsumerState<ApplyDietSheet> {
  String? _selectedPlanId;
  ApplyRange _range = ApplyRange.singleDay;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plansAsync = ref.watch(storedDietPlansProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) return const _NoDiets();

            // Defaults to the active diet, which `storedDietPlansProvider`
            // returns first: applying anything else is the exception.
            final selected = plans.firstWhere(
              (plan) => plan.id == _selectedPlanId,
              orElse: () => plans.first,
            );
            final days = _daysFor(_range);

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Apply a diet', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Assigns its meals to the calendar, starting '
                    '${DayFormat.dayAndMonth(widget.anchorDay)}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DietPicker(
                    plans: plans,
                    selected: selected,
                    onChanged: (id) => setState(() => _selectedPlanId = id),
                  ),
                  const SizedBox(height: 20),
                  Text('Apply to', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<ApplyRange>(
                    segments: [
                      for (final range in ApplyRange.values)
                        ButtonSegment(
                          value: range,
                          label: Text(
                            range.label,
                            style: theme.textTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                    selected: {_range},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        setState(() => _range = selection.first),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${days.length} ${days.length == 1 ? 'day' : 'days'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      key: const Key('applyDietError'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('confirmApplyDietButton'),
                    onPressed: _saving ? null : () => _apply(selected, days),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Apply'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Could not load your diets.\n$error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  /// Ranges are inclusive of the anchor day and never reach into the past:
  /// back-filling a plan onto days already lived would invent adherence
  /// history that never happened.
  List<NutritionDay> _daysFor(ApplyRange range) {
    final anchor = widget.anchorDay;
    return switch (range) {
      ApplyRange.singleDay => [anchor],
      ApplyRange.restOfWeek => _untilEndOfWeek(anchor),
      ApplyRange.restOfMonth => CalendarMonth.fromDay(
        anchor,
      ).days.where((d) => d.epochDay >= anchor.epochDay).toList(),
    };
  }

  List<NutritionDay> _untilEndOfWeek(NutritionDay anchor) {
    final date = DateTime(anchor.year, anchor.month, anchor.day);
    final remaining = DateTime.daysPerWeek - date.weekday;
    return [
      for (var i = 0; i <= remaining; i++)
        NutritionDay.fromDateTime(date.add(Duration(days: i))),
    ];
  }

  Future<void> _apply(StoredDietPlan stored, List<NutritionDay> days) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    // Decoded here rather than held in state: the sheet only needs the plan at
    // the moment it applies it, and decoding every listed diet up front would
    // load the food table for diets the user never picks.
    final decoded = await ref.read(decodeStoredDietProvider)(stored);
    if (!mounted) return;

    switch (decoded) {
      case Err(failure: final failure):
        setState(() {
          _saving = false;
          _error = 'Could not read "${stored.name}": $failure';
        });
        return;
      case Ok(value: final diet):
        final outcome = await ref
            .read(dietPlanControllerProvider.notifier)
            .applyDiet(plan: diet.plan, days: days);
        if (!mounted) return;
        setState(() => _saving = false);

        if (outcome == null) {
          final state = ref.read(dietPlanControllerProvider);
          setState(() => _error = state.error?.toString() ?? 'Apply failed.');
          return;
        }

        Navigator.of(context).pop();
        _reportSkippedDays(outcome.skippedDays.length, stored.name);
    }
  }

  /// Says so when the diet had nothing for some of the days.
  ///
  /// A plan that only covers weekdays is normal; silently leaving those days
  /// empty after the user asked for a month is not.
  void _reportSkippedDays(int skipped, String dietName) {
    if (skipped == 0) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$skipped ${skipped == 1 ? 'day was' : 'days were'} left empty — '
            '"$dietName" says nothing about ${skipped == 1 ? 'that' : 'those'} '
            'weekday${skipped == 1 ? '' : 's'}.',
          ),
        ),
      );
  }
}

class _DietPicker extends StatelessWidget {
  const _DietPicker({
    required this.plans,
    required this.selected,
    required this.onChanged,
  });

  final List<StoredDietPlan> plans;
  final StoredDietPlan selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final plan in plans)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              key: Key('applyDietOption-${plan.id}'),
              onTap: () => onChanged(plan.id),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: plan.id == selected.id
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: plan.id == selected.id ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      plan.id == selected.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: plan.id == selected.id
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plan.name,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              if (plan.isDefault)
                                Text(
                                  'Current',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          if (plan.declaredDailyEnergyKcal
                              case final declared?) ...[
                            const SizedBox(height: 2),
                            Text(
                              NutritionFormat.kcal(declared),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NoDiets extends StatelessWidget {
  const _NoDiets();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('No diets to apply', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Import or write one in My diets first.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [ApplyDietSheet] as a modal bottom sheet.
Future<void> showApplyDietSheet(
  BuildContext context, {
  required NutritionDay anchorDay,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ApplyDietSheet(anchorDay: anchorDay),
  );
}

/// Convenience for screens that only know the reference day through Riverpod.
NutritionDay anchorFor(WidgetRef ref, NutritionDay day) {
  final today = ref.read(todayProvider);
  // Planning starts no earlier than today: a plan for a day already lived is
  // not a plan, it is a rewrite of history.
  return day.epochDay < today.epochDay ? today : day;
}
