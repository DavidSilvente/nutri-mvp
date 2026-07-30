import 'package:nutri_mvp/core/result.dart';

import '../entities/diet_template.dart';
import '../entities/meal_substitute.dart';
import '../entities/planned_meal.dart';
import '../failures/nutrition_failure.dart';
import '../value_objects/nutrition_day.dart';

/// Domain port for reading and writing diet templates, planned meals, and
/// per-meal substitutes.
///
/// Implementations are responsible for enforcing unique template names and
/// unique (slot, day) planned-meal assignments. Violations MUST be reported as
/// [ConflictFailure].
abstract interface class DietPlanSource {
  /// Returns all diet templates, ordered by name.
  Future<Result<List<DietTemplate>, NutritionFailure>> listTemplates();

  /// Persists [template]. Returns [ConflictFailure] if a template with the
  /// same name already exists for a different [id].
  Future<Result<DietTemplate, NutritionFailure>> saveTemplate(
    DietTemplate template,
  );

  /// Deletes the template identified by [id] and its dependent slots.
  Future<Result<void, NutritionFailure>> deleteTemplate(String id);

  /// Returns planned meals, optionally filtered by [templateId] and/or [day].
  Future<Result<List<PlannedMeal>, NutritionFailure>> listPlannedMeals({
    String? templateId,
    NutritionDay? day,
  });

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
