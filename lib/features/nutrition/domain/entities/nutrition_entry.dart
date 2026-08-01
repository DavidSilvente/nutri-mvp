import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';

/// A single nutrition intake record: energy and macros, at a point in time.
///
/// Water is NOT part of this entity — hydration is tracked as an independent
/// aggregate (see `HydrationEntry`).
///
/// [plannedMealId] is the OPTIONAL link back to the `PlannedMeal` this intake
/// was logged against. It is nullable on purpose: a user must be able to log
/// something that was never planned (an unplanned snack, a restaurant meal),
/// and those entries still count towards the daily totals while being
/// invisible to adherence. Adherence is computed only over entries that carry
/// this link — see `AdherenceEvaluator`.
///
/// Validation is fully delegated to its value objects ([Energy], [Macros])
/// — this entity does not duplicate their `>= 0` checks.
class NutritionEntry {
  NutritionEntry({
    required this.id,
    required this.recordedAt,
    required this.energy,
    required this.macros,
    this.plannedMealId,
  });

  final String id;
  final DateTime recordedAt;
  final Energy energy;
  final Macros macros;
  final String? plannedMealId;

  /// Whether this intake was logged against a planned meal.
  bool get isPlanned => plannedMealId != null;

  /// Returns a copy of this entry linked to [plannedMealId]. Passing `null`
  /// detaches the entry from its planned meal.
  NutritionEntry withPlannedMeal(String? plannedMealId) => NutritionEntry(
    id: id,
    recordedAt: recordedAt,
    energy: energy,
    macros: macros,
    plannedMealId: plannedMealId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionEntry &&
          other.id == id &&
          other.recordedAt == recordedAt &&
          other.energy == energy &&
          other.macros == macros &&
          other.plannedMealId == plannedMealId);

  @override
  int get hashCode =>
      Object.hash(id, recordedAt, energy, macros, plannedMealId);

  @override
  String toString() =>
      'NutritionEntry(id: $id, recordedAt: $recordedAt, energy: $energy, '
      'macros: $macros, plannedMealId: $plannedMealId)';
}
