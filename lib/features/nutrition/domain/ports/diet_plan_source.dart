import 'package:nutri_mvp/core/result.dart';

import '../entities/meal_substitute.dart';
import '../entities/planned_meal.dart';
import '../failures/nutrition_failure.dart';
import '../value_objects/nutrition_day.dart';
import 'diet_plan_store.dart';

/// Domain port for reading and writing planned meals and their substitutes —
/// the CALENDAR side of the diet.
///
/// What a diet prescribes is not here: that lives in one place, the plan
/// documents behind [DietPlanStore], and is read through `ResolveActiveDiet`.
/// This port owns only the commitments made against a calendar day, each one
/// carrying the slot it fulfils and the target it was frozen at.
///
/// Implementations are responsible for enforcing unique (slot, day)
/// planned-meal assignments. Violations MUST be reported as [ConflictFailure].
abstract interface class DietPlanSource {
  /// Returns planned meals, optionally filtered by [day].
  Future<Result<List<PlannedMeal>, NutritionFailure>> listPlannedMeals({
    NutritionDay? day,
  });

  /// Returns every planned meal assigned to a day between [from] and [to],
  /// BOTH INCLUSIVE.
  ///
  /// Meals with no day are EXCLUDED — they are templates-in-waiting, not
  /// calendar commitments. Exists so a calendar can load a whole month in one
  /// round trip. An inverted range MUST yield an empty list, not an error.
  Future<Result<List<PlannedMeal>, NutritionFailure>> plannedMealsBetween(
    NutritionDay from,
    NutritionDay to,
  );

  /// Persists [meal]. Returns [ConflictFailure] if the same slot is already
  /// planned for the same day.
  Future<Result<PlannedMeal, NutritionFailure>> savePlannedMeal(
    PlannedMeal meal,
  );

  /// Deletes the planned meal identified by [id] and its substitutes.
  Future<Result<void, NutritionFailure>> deletePlannedMeal(String id);

  /// Returns all substitutes for the planned meal identified by
  /// [plannedMealId].
  Future<Result<List<MealSubstitute>, NutritionFailure>> listSubstitutes(
    String plannedMealId,
  );

  /// Persists [substitute] scoped to its [plannedMealId].
  Future<Result<MealSubstitute, NutritionFailure>> saveSubstitute(
    MealSubstitute substitute,
  );

  /// Deletes the substitute identified by [id].
  Future<Result<void, NutritionFailure>> deleteSubstitute(String id);
}
