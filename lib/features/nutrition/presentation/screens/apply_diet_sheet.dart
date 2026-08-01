import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/day_format.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/calendar_month.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/macro_breakdown.dart';

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

/// Picks a diet template and drops it onto the calendar.
///
/// Planning a month one meal at a time is the kind of chore that kills the
/// habit, so the common cases — this day, this week, this month — are one tap.
class ApplyDietSheet extends ConsumerStatefulWidget {
  const ApplyDietSheet({super.key, required this.anchorDay});

  /// The day the range is measured from.
  final NutritionDay anchorDay;

  @override
  ConsumerState<ApplyDietSheet> createState() => _ApplyDietSheetState();
}

class _ApplyDietSheetState extends ConsumerState<ApplyDietSheet> {
  String? _selectedTemplateId;
  ApplyRange _range = ApplyRange.singleDay;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateAsync = ref.watch(dietPlanControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: stateAsync.when(
          data: (state) {
            final templates = state.templates;
            if (templates.isEmpty) return const _NoTemplates();

            final selected = templates.firstWhere(
              (t) => t.id == _selectedTemplateId,
              orElse: () => templates.first,
            );
            final days = _daysFor(_range);

            return Column(
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
                _TemplatePicker(
                  templates: templates,
                  selected: selected,
                  onChanged: (id) => setState(() => _selectedTemplateId = id),
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
                  '${days.length} '
                  '${days.length == 1 ? 'day' : 'days'} · '
                  '${days.length * selected.slots.length} meals',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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

  Future<void> _apply(DietTemplate template, List<NutritionDay> days) async {
    setState(() => _saving = true);

    await ref
        .read(dietPlanControllerProvider.notifier)
        .applyTemplate(template: template, days: days);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({
    required this.templates,
    required this.selected,
    required this.onChanged,
  });

  final List<DietTemplate> templates;
  final DietTemplate selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final template in templates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              key: Key('applyTemplateOption-${template.id}'),
              onTap: () => onChanged(template.id),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: template.id == selected.id
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: template.id == selected.id ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      template.id == selected.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: template.id == selected.id
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${NutritionFormat.kcal(template.dailyTarget.energy.kcal)}'
                            ' · ${template.slots.length} meals',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          MacroSummaryLine(target: template.dailyTarget),
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

class _NoTemplates extends StatelessWidget {
  const _NoTemplates();

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
            'Create one in the Diet tab first.',
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
