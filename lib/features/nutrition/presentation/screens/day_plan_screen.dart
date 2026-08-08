import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/day_format.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/core/theme/adherence_palette.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/resolved_component.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_day_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/apply_diet_sheet.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/component_options_sheet.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/hydration_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/meal_alternatives_sheet.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/record_intake_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/save_entry_as_meal_dialog.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/adherence_chip.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/macro_breakdown.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/section_dot.dart';

/// One day of the diet: what was planned, what was eaten, and how the two
/// line up.
///
/// Used both as the "today" tab and as the destination when tapping a day in
/// the calendar, so past days are reviewable with the exact same layout.
class DayPlanScreen extends ConsumerWidget {
  const DayPlanScreen({super.key, required this.day, this.showAppBar = true});

  final NutritionDay day;

  /// Off when embedded in a tab that supplies its own app bar.
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final planAsync = ref.watch(dayPlanProvider(day));
    final heading = DayFormat.heading(day, today);

    final body = planAsync.when(
      data: (plan) => _DayPlanBody(plan: plan, heading: heading, today: today),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load this day.\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              // No title: the body already opens with the day as a large
              // heading, and repeating it in the bar is noise.
              actions: [
                // Hydration is a separate aggregate with its own screen; it
                // gets its own entry point rather than being folded into the
                // meal flow.
                IconButton(
                  key: const Key('goToHydrationButton'),
                  icon: const Icon(Icons.water_drop_outlined),
                  tooltip: 'Water',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HydrationScreen(),
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: SafeArea(child: body),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('logUnplannedIntakeButton'),
        // Explicit tag: this screen shares a subtree with the template list's
        // FAB inside the home IndexedStack, and two default-tagged heroes in
        // one subtree is a runtime error.
        heroTag: 'logIntakeFab',
        onPressed: () => _openRecordIntake(context),
        icon: const Icon(Icons.add),
        label: const Text('Log intake'),
      ),
    );
  }

  void _openRecordIntake(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RecordIntakeScreen(day: day)),
    );
  }
}

class _DayPlanBody extends StatelessWidget {
  const _DayPlanBody({
    required this.plan,
    required this.heading,
    required this.today,
  });

  final DayPlan plan;
  final String heading;
  final NutritionDay today;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _DayHeader(plan: plan, heading: heading),
        const SizedBox(height: 16),
        _DayTotals(plan: plan, isToday: plan.day == today),
        const SizedBox(height: 24),
        if (plan.hasPlan) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Planned meals',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _ApplyDietButton(day: plan.day, isCompact: true),
            ],
          ),
          const SizedBox(height: 12),
          for (final meal in plan.meals) ...[
            _PlannedMealCard(detail: meal, day: plan.day),
            const SizedBox(height: 12),
          ],
        ] else
          _NoPlanCard(day: plan.day),
        if (plan.unplannedEntries.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Deliberately NOT "Over"/"Under": those are the day-status chip's
          // own wording, and the same word meaning two different things on
          // one screen is how a UI stops being readable.
          Text('Extras', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Logged but not attached to a planned meal. Still counts '
            "towards the day's total and its verdict above.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _UnplannedEntries(entries: plan.unplannedEntries),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.plan, required this.heading});

  final DayPlan plan;
  final String heading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(
                DayFormat.full(plan.day),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AdherenceChip.day(plan.status, entryCount: plan.entryCount),
      ],
    );
  }
}

class _DayTotals extends ConsumerWidget {
  const _DayTotals({required this.plan, required this.isToday});

  final DayPlan plan;

  /// Hydration is only tracked for the current day, so the row is omitted
  /// when reviewing a past day rather than showing a misleading zero.
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logged = plan.loggedTotal;
    final planned = plan.plannedTotal;
    final hasPlan = plan.hasPlan;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NutritionFormat.amount(logged.energy.kcal),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    hasPlan
                        ? 'of ${NutritionFormat.kcal(planned.energy.kcal)}'
                        : 'kcal',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                if (hasPlan)
                  Text(
                    '${plan.adherence.onTargetCount}/'
                    '${plan.adherence.plannedCount} meals',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (hasPlan) ...[
              const SizedBox(height: 20),
              MacroBreakdown(logged: logged, target: planned),
            ],
            if (isToday) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _HydrationRow(),
            ],
          ],
        ),
      ),
    );
  }
}

class _HydrationRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hydrationAsync = ref.watch(hydrationControllerProvider);

    return Row(
      children: [
        Icon(
          Icons.water_drop_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text('Water', style: theme.textTheme.labelLarge),
        const Spacer(),
        hydrationAsync.when(
          data: (entries) {
            final totalMl = entries.fold<num>(
              0,
              (sum, entry) => sum + entry.volume.ml,
            );
            return Text(
              '${NutritionFormat.amount(totalMl)} ml',
              style: theme.textTheme.bodyMedium,
            );
          },
          loading: () => Text('…', style: theme.textTheme.bodyMedium),
          error: (_, _) => Text(
            'unavailable',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlannedMealCard extends ConsumerWidget {
  const _PlannedMealCard({required this.detail, required this.day});

  final PlannedMealDetail detail;
  final NutritionDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = AdherencePalette.of(context);
    final style = palette.forMeal(detail.status);

    return Card(
      key: Key('plannedMealCard-${detail.meal.id}'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: style.container,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, size: 18, color: style.onContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail.label, style: theme.textTheme.titleMedium),
                      if (detail.timeOfDay != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail.timeOfDay!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AdherenceChip.meal(detail.status),
              ],
            ),
            // The food this meal is made of is the primary content: it
            // answers "what do I eat", which the label and macros alone do
            // not. Absent entirely when the slot no longer exists or never
            // carried components, so a hand-entered meal degrades to exactly
            // the layout it had before this existed.
            if (detail.components.isNotEmpty) ...[
              const SizedBox(height: 16),
              _MealFoodList(
                key: Key('mealFoodList-${detail.meal.id}'),
                components: detail.components,
                day: day,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              detail.status == MealAdherenceStatus.pending
                  ? 'Target ${NutritionFormat.kcal(detail.target.energy.kcal)}'
                  : NutritionFormat.kcalOf(
                      detail.logged.energy.kcal,
                      detail.target.energy.kcal,
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            MacroBreakdown(logged: detail.logged, target: detail.target),
            if (detail.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                key: Key('notes-${detail.meal.slotId}'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text('Notes', style: theme.textTheme.labelMedium),
                children: [
                  for (final note in detail.notes)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(note, style: theme.textTheme.bodySmall),
                      ),
                    ),
                ],
              ),
            ],
            if (detail.entries.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              for (final entry in detail.entries) _LoggedEntryRow(entry: entry),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: Key('alternativesButton-${detail.meal.id}'),
                    onPressed: () => _openAlternatives(context),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Swap meal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: Key('logMealButton-${detail.meal.id}'),
                    onPressed: () => _logMeal(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      detail.status == MealAdherenceStatus.pending
                          ? 'Log'
                          : 'Add more',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAlternatives(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MealAlternativesSheet(detail: detail, day: day),
    );
  }

  void _logMeal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecordIntakeScreen(day: day, plannedMeal: detail),
      ),
    );
  }
}

/// The food a meal is made of, one row per component.
///
/// A plain [Column], not a [ListView]: this always sits inside the day's
/// outer scrollable, and a nested unbounded list would either need its own
/// scroll physics or crash on layout.
class _MealFoodList extends StatelessWidget {
  const _MealFoodList({super.key, required this.components, required this.day});

  final List<ResolvedComponent> components;
  final NutritionDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final component in components)
          _PlannedComponentRow(component: component, day: day),
      ],
    );
  }
}

/// One resolved component of a meal: the plan's own wording, plus the
/// signals that make a deviation or an estimate visible without opening
/// anything.
///
/// Tappable when [ResolvedComponent.hasAlternatives], opening the same
/// "Options" sheet `diet_day_screen` reaches from its own per-item row —
/// [ComponentChoiceController]'s day-plan invalidation is what lets a write
/// made here show up there too.
class _PlannedComponentRow extends StatelessWidget {
  const _PlannedComponentRow({required this.component, required this.day});

  final ResolvedComponent component;
  final NutritionDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (component.sectionLabel != null) ...[
            SectionDot(label: component.sectionLabel!),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              component.chosen.rawText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (component.isDeviation) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.swap_horiz,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
          ],
          if (component.needsReview) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.info_outline,
              size: 14,
              color: theme.colorScheme.tertiary,
            ),
          ],
          if (component.hasAlternatives) ...[
            const SizedBox(width: 6),
            Text(
              '${component.options.length}',
              style: theme.textTheme.labelSmall,
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ],
      ),
    );

    if (!component.hasAlternatives) return row;

    return InkWell(
      key: Key('componentRow-${component.componentId}'),
      onTap: () => showComponentOptionsSheet(
        context: context,
        component: component,
        day: day,
      ),
      child: row,
    );
  }
}

class _UnplannedEntries extends StatelessWidget {
  const _UnplannedEntries({required this.entries});

  final List<NutritionEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _LoggedEntryRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

/// One logged [NutritionEntry], with a way to promote it into the saved-meal
/// catalogue.
///
/// Shared between the "Extras" list (unplanned entries) and each planned
/// meal's own logged entries — a `NutritionEntry` carries no label, so
/// naming it here is how it becomes reusable as a saved meal.
class _LoggedEntryRow extends StatelessWidget {
  const _LoggedEntryRow({required this.entry});

  final NutritionEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        Icons.local_dining_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        NutritionFormat.kcal(entry.energy.kcal),
        style: theme.textTheme.titleSmall,
      ),
      subtitle: MacroSummaryLine(
        target: NutritionTarget(energy: entry.energy, macros: entry.macros),
      ),
      trailing: IconButton(
        key: Key('saveEntryAsMealButton-${entry.id}'),
        icon: const Icon(Icons.bookmark_add_outlined),
        tooltip: 'Save as a meal',
        onPressed: () => _promoteEntry(context),
      ),
    );
  }

  void _promoteEntry(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => SaveEntryAsMealDialog(entry: entry),
    );
  }
}

/// Opens the "apply a diet" sheet, anchored on this day.
class _ApplyDietButton extends ConsumerWidget {
  const _ApplyDietButton({required this.day, this.isCompact = false});

  final NutritionDay day;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open() => showApplyDietSheet(context, anchorDay: anchorFor(ref, day));

    if (isCompact) {
      return TextButton.icon(
        key: const Key('applyDietCompactButton'),
        onPressed: open,
        icon: const Icon(Icons.event_repeat_outlined, size: 18),
        label: const Text('Apply diet'),
      );
    }

    return FilledButton.icon(
      key: const Key('applyDietButton'),
      onPressed: open,
      icon: const Icon(Icons.event_repeat_outlined, size: 18),
      label: const Text('Apply a diet'),
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard({required this.day});

  final NutritionDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('No meals planned', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Apply one of your diets to fill this day — or a whole week — '
              'with its meals.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _ApplyDietButton(day: day),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('goToDietsFromDayButton'),
              onPressed: () => Navigator.of(context).pushNamed('/diets'),
              child: const Text('Manage diets'),
            ),
          ],
        ),
      ),
    );
  }
}
