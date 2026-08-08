import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/day_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_day_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/intake_form.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/planned_meal_field.dart';

/// Screen to register a nutrition intake: food-first by default, hand-typed
/// macros as a one-tap-away secondary path. Water is NOT part of this flow —
/// hydration has its own dedicated screen.
///
/// Three ways in, all the same form:
/// * free-standing (no [day], no [plannedMeal]) — an unplanned intake today;
/// * attached to a [day] — the same, but backdated to that day;
/// * attached to a [plannedMeal] — the intake counts towards that meal's
///   adherence by default, and the Macros tab starts pre-filled with its
///   target.
///
/// Which planned meal the entry counts towards is always an in-screen
/// choice via [PlannedMealField], SEEDED from [plannedMeal] — every call
/// site's prior hardcoded attach/no-attach behaviour becomes an overridable
/// default rather than a permanent choice.
class RecordIntakeScreen extends ConsumerStatefulWidget {
  const RecordIntakeScreen({
    super.key,
    this.day,
    this.plannedMeal,
    this.prefill,
    this.prefillLabel,
  });

  /// The day this intake belongs to. Defaults to today.
  final NutritionDay? day;

  /// The planned meal this intake fulfils, if any.
  final PlannedMealDetail? plannedMeal;

  /// Values to start from. Defaults to the planned meal's target when a meal
  /// is given; used to carry a chosen alternative's macros over.
  final NutritionTarget? prefill;

  /// Name of the alternative the prefill came from, shown as confirmation of
  /// what is being logged.
  final String? prefillLabel;

  @override
  ConsumerState<RecordIntakeScreen> createState() => _RecordIntakeScreenState();
}

class _RecordIntakeScreenState extends ConsumerState<RecordIntakeScreen> {
  final _intakeFormKey = GlobalKey<IntakeFormState>();
  late String? _plannedMealId;

  @override
  void initState() {
    super.initState();
    _plannedMealId = widget.plannedMeal?.meal.id;
  }

  Future<void> _submit() async {
    final form = _intakeFormKey.currentState!;
    if (!form.validate()) return;

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final recordedAt = _recordedAt();
    final entry = switch (form.value) {
      ComposedIntakeFormValue(composition: final composition) =>
        NutritionEntry.composed(
          id: id,
          recordedAt: recordedAt,
          composition: composition,
          plannedMealId: _plannedMealId,
        ),
      ManualIntakeFormValue(target: final target) => NutritionEntry(
        id: id,
        recordedAt: recordedAt,
        energy: target.energy,
        macros: target.macros,
        plannedMealId: _plannedMealId,
      ),
    };

    await ref.read(nutritionControllerProvider.notifier).record(entry);

    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Entries are grouped by the calendar DAY of [NutritionEntry.recordedAt],
  /// so an intake logged into a given day must carry that day's date —
  /// otherwise it would silently land on whatever day the clock says.
  ///
  /// The time of day still comes from the clock, which keeps entries ordered
  /// within the day. The date is taken from [widget.day] unconditionally
  /// rather than "only when it is not today": deriving it from a comparison
  /// makes the result depend on two sources of truth instead of one.
  DateTime _recordedAt() {
    final day = widget.day;
    final now = DateTime.now();
    if (day == null) return now;
    return DateTime(
      day.year,
      day.month,
      day.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meal = widget.plannedMeal;
    final day = widget.day;
    final NutritionDay pickerDay = day ?? ref.watch(todayProvider);
    // A known target (a planned meal, or a chosen alternative) means the
    // Macros tab should open pre-filled instead of Food: re-deriving numbers
    // the caller already handed over would defeat the entire point of a
    // prefill — see the class doc's "one tap, not four numbers" contract.
    final prefill = widget.prefill ?? widget.plannedMeal?.target;

    return Scaffold(
      appBar: AppBar(
        title: Text(meal == null ? 'Registrar ingesta' : 'Log ${meal.label}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (meal != null || day != null) ...[
              _ContextCard(
                mealLabel: meal?.label,
                day: day,
                prefillLabel: widget.prefillLabel,
              ),
              const SizedBox(height: 20),
            ],
            PlannedMealField(
              day: pickerDay,
              selectedMealId: _plannedMealId,
              onChanged: (mealId) => setState(() => _plannedMealId = mealId),
            ),
            const SizedBox(height: 20),
            IntakeForm(
              key: _intakeFormKey,
              initialTarget: prefill,
              foodFirstByDefault: prefill == null,
            ),
            if (meal != null) ...[
              const SizedBox(height: 12),
              Text(
                'Adjust these to what you actually ate — the plan is met '
                'as long as you land close.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('submitButton'),
              onPressed: _submit,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.mealLabel,
    required this.day,
    required this.prefillLabel,
  });

  final String? mealLabel;
  final NutritionDay? day;
  final String? prefillLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              prefillLabel != null
                  ? Icons.swap_horiz_rounded
                  : Icons.restaurant_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prefillLabel ?? mealLabel ?? 'Unplanned intake',
                    style: theme.textTheme.titleSmall,
                  ),
                  if (day != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DayFormat.full(day!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (prefillLabel != null && mealLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Counts towards $mealLabel',
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
    );
  }
}
