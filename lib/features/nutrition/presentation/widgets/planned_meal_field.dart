import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_day_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';

/// Lets the user choose which planned meal a logged intake counts towards,
/// or mark it "extra" (unplanned) — and, symmetrically, detach an already
/// attached entry back to extra.
///
/// The domain has always supported this: [PlannedMealDetail]'s underlying
/// entry has a nullable `plannedMealId` and `withPlannedMeal(null)` already
/// existed before this widget did. Only the UI never exposed the choice —
/// every call site hardcoded it (attach unconditionally, or never attach at
/// all). Each caller now SEEDS [selectedMealId] from its own prior default
/// (a free-standing log seeds `null`; an already-attached one seeds that
/// meal's id), so none of them need a signature change: the picker turns a
/// hardcoded choice into an overridable one, in-screen.
class PlannedMealField extends ConsumerWidget {
  const PlannedMealField({
    super.key,
    required this.day,
    required this.selectedMealId,
    required this.onChanged,
  });

  /// The day whose planned meals are offered as choices.
  final NutritionDay day;

  /// The currently chosen meal id, or `null` for "extra".
  final String? selectedMealId;

  final ValueChanged<String?> onChanged;

  static const extraLabel = 'Extra (not planned)';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(dayPlanProvider(day));

    return planAsync.when(
      data: (plan) => _field(plan.meals),
      loading: () => const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, _) => Text(
        'Could not load planned meals.\n$error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _field(List<PlannedMealDetail> meals) {
    // A stale [selectedMealId] (its meal vanished from the plan between
    // seeding and this build, e.g. deleted elsewhere) would violate
    // DropdownButtonFormField's "exactly one matching item" assertion, so it
    // is treated as "extra" here rather than crashing the screen.
    final validSelection = meals.any((meal) => meal.meal.id == selectedMealId)
        ? selectedMealId
        : null;

    return DropdownButtonFormField<String?>(
      key: const Key('plannedMealField'),
      initialValue: validSelection,
      decoration: const InputDecoration(labelText: 'Counts towards'),
      items: [
        const DropdownMenuItem(value: null, child: Text(extraLabel)),
        for (final meal in meals)
          DropdownMenuItem(value: meal.meal.id, child: Text(meal.label)),
      ],
      onChanged: onChanged,
    );
  }
}
