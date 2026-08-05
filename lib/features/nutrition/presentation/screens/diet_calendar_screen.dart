import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/theme/adherence_palette.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_month_adherence.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/calendar_month.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/apply_diet_sheet.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/day_plan_screen.dart';

const _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _weekdayInitials = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// A month grid showing, at a glance, which days the diet was followed.
///
/// The month being viewed is local state: the calendar is a browsing surface,
/// and which month you happen to be looking at is not something the rest of
/// the app needs to know.
class DietCalendarScreen extends ConsumerStatefulWidget {
  const DietCalendarScreen({super.key});

  @override
  ConsumerState<DietCalendarScreen> createState() => _DietCalendarScreenState();
}

class _DietCalendarScreenState extends ConsumerState<DietCalendarScreen> {
  CalendarMonth? _month;

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final month = _month ?? CalendarMonth.fromDay(today);
    final adherenceAsync = ref.watch(monthAdherenceProvider(month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            key: const Key('applyDietFromCalendarButton'),
            icon: const Icon(Icons.event_repeat_outlined),
            tooltip: 'Apply a diet',
            onPressed: () => showApplyDietSheet(
              context,
              anchorDay: anchorFor(ref, _anchorForMonth(month, today)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _MonthHeader(
              month: month,
              onPrevious: () => setState(() => _month = month.previous),
              onNext: () => setState(() => _month = month.next),
            ),
            const SizedBox(height: 16),
            adherenceAsync.when(
              data: (adherence) => _MonthBody(
                month: month,
                adherence: adherence,
                today: today,
                onDayTap: _openDay,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'Could not load the calendar.\n$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Applying from a month you are browsing should start at the beginning of
  /// THAT month, not at today — unless today falls inside it.
  NutritionDay _anchorForMonth(CalendarMonth month, NutritionDay today) {
    return month.contains(today) ? today : month.firstDay;
  }

  void _openDay(NutritionDay day) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => DayPlanScreen(day: day)));
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final CalendarMonth month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('previousMonthButton'),
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            '${_monthNames[month.month - 1]} ${month.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: const Key('nextMonthButton'),
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next month',
        ),
      ],
    );
  }
}

class _MonthBody extends StatelessWidget {
  const _MonthBody({
    required this.month,
    required this.adherence,
    required this.today,
    required this.onDayTap,
  });

  final CalendarMonth month;
  final MonthAdherence adherence;
  final NutritionDay today;
  final void Function(NutritionDay) onDayTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthSummary(adherence: adherence),
        const SizedBox(height: 20),
        const _WeekdayHeader(),
        const SizedBox(height: 8),
        _DayGrid(
          month: month,
          adherence: adherence,
          today: today,
          onDayTap: onDayTap,
        ),
        const SizedBox(height: 24),
        const _Legend(),
      ],
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.adherence});

  final MonthAdherence adherence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settled = adherence.settledDays;
    final complete = adherence.completeDays;
    final percent = (adherence.completionRatio * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settled == 0
                        ? 'Nothing to judge yet'
                        : '$complete of $settled days on plan',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Says out loud what the number excludes, so a low count
                    // early in the month is not read as failure.
                    'Days still to come are not counted.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (settled > 0) ...[
              const SizedBox(width: 16),
              Text(
                '$percent%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final initial in _weekdayInitials)
          Expanded(
            child: Center(
              child: Text(
                initial,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.adherence,
    required this.today,
    required this.onDayTap,
  });

  final CalendarMonth month;
  final MonthAdherence adherence;
  final NutritionDay today;
  final void Function(NutritionDay) onDayTap;

  @override
  Widget build(BuildContext context) {
    // Monday-first grid: a month starting on Wednesday needs two blanks.
    final leadingBlanks = month.firstWeekday - 1;
    final days = month.days;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: leadingBlanks + days.length,
      itemBuilder: (context, index) {
        if (index < leadingBlanks) return const SizedBox.shrink();

        final day = days[index - leadingBlanks];
        final dayAdherence = adherence.forDay(day);
        return _DayCell(
          day: day,
          adherence: dayAdherence,
          isToday: day == today,
          onTap: () => onDayTap(day),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.adherence,
    required this.isToday,
    required this.onTap,
  });

  final NutritionDay day;
  final DayAdherence? adherence;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AdherencePalette.of(context);
    final status = adherence?.status ?? DayAdherenceStatus.unplanned;
    final style = palette.forDay(status);
    final hasPlan = status != DayAdherenceStatus.unplanned;

    return Semantics(
      button: true,
      label:
          '${day.day} ${_monthNames[day.month - 1]}, '
          '${hasPlan ? style.label : 'no plan'}',
      child: InkWell(
        key: Key('calendarDay-${day.epochDay}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: style.container,
            borderRadius: BorderRadius.circular(14),
            border: isToday
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: hasPlan
                      ? style.onContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              // The dot repeats the state as shape, not just as background
              // tint, which keeps the cell readable at small sizes.
              if (hasPlan)
                Icon(style.icon, size: 12, color: style.onContainer)
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final palette = AdherencePalette.of(context);
    const statuses = [
      DayAdherenceStatus.complete,
      DayAdherenceStatus.partial,
      DayAdherenceStatus.missed,
      DayAdherenceStatus.upcoming,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final status in statuses)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                palette.forDay(status).icon,
                size: 14,
                color: palette.forDay(status).color,
              ),
              const SizedBox(width: 6),
              Text(
                palette.forDay(status).label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
      ],
    );
  }
}
