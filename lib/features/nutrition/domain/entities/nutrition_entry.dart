import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
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
///
/// [ingredients] is the OPTIONAL food-first composition this entry was
/// logged from, mirroring `MealComponent.options`. It defaults to an empty
/// list — a hand-typed entry, or one logged before this change, is a valid,
/// legacy shape, not a degraded one. [energy]/[macros] remain the single
/// source of truth for every reader (adherence, totals): they are DERIVED
/// from [ingredients] at save time via [NutritionEntry.composed] and never
/// re-derived afterwards, so a later catalog correction cannot retroactively
/// rewrite already-logged history. The plain constructor used here accepts
/// [energy]/[macros]/[ingredients] independently and is intended for STORAGE
/// REHYDRATION (and hand-typed manual entry) only — the SQL read path must
/// rebuild a stored entry's flat macros verbatim, without re-deriving them
/// from [ingredients], or the snapshot rule above breaks.
class NutritionEntry {
  NutritionEntry({
    required this.id,
    required this.recordedAt,
    required this.energy,
    required this.macros,
    this.plannedMealId,
    List<LoggedIngredient> ingredients = const [],
  }) : ingredients = List.unmodifiable(ingredients);

  final String id;
  final DateTime recordedAt;
  final Energy energy;
  final Macros macros;
  final String? plannedMealId;
  final List<LoggedIngredient> ingredients;

  /// Builds an entry whose [energy]/[macros] are DERIVED from [composition],
  /// the only public entry point that pairs a composition with the target it
  /// produced. See the class doc for why the plain constructor still exists
  /// alongside this factory.
  factory NutritionEntry.composed({
    required String id,
    required DateTime recordedAt,
    required DerivedComposition composition,
    String? plannedMealId,
  }) => NutritionEntry(
    id: id,
    recordedAt: recordedAt,
    energy: composition.target.energy,
    macros: composition.target.macros,
    plannedMealId: plannedMealId,
    ingredients: composition.ingredients,
  );

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
    ingredients: ingredients,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NutritionEntry) return false;
    if (other.id != id ||
        other.recordedAt != recordedAt ||
        other.energy != energy ||
        other.macros != macros ||
        other.plannedMealId != plannedMealId ||
        other.ingredients.length != ingredients.length) {
      return false;
    }
    for (var i = 0; i < ingredients.length; i++) {
      if (other.ingredients[i] != ingredients[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordedAt,
    energy,
    macros,
    plannedMealId,
    Object.hashAll(ingredients),
  );

  @override
  String toString() =>
      'NutritionEntry(id: $id, recordedAt: $recordedAt, energy: $energy, '
      'macros: $macros, plannedMealId: $plannedMealId, '
      'ingredients: $ingredients)';
}
