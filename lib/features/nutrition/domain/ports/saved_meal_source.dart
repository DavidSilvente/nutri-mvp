import 'package:nutri_mvp/core/result.dart';

import '../entities/saved_meal.dart';
import '../failures/nutrition_failure.dart';

/// Domain port for the user's saved-meal catalogue.
///
/// Implementations MUST enforce unique names, compared trimmed and
/// case-insensitively via [SavedMeal.normalizedName]. A conflicting create or
/// rename MUST be reported as [ConflictFailure] — the SAME failure used for
/// duplicate diet template names and slot clashes elsewhere in this feature.
/// There is no dedicated duplicate-name failure case.
abstract interface class SavedMealSource {
  /// Returns every saved meal, ordered by name.
  Future<Result<List<SavedMeal>, NutritionFailure>> listSavedMeals();

  /// Persists [meal]. Returns [ConflictFailure] when another meal already
  /// uses the same normalized name under a DIFFERENT id. Saving a meal under
  /// its own existing id (e.g. an edit that keeps the name) is not a
  /// conflict.
  Future<Result<SavedMeal, NutritionFailure>> saveMeal(SavedMeal meal);

  /// Deletes the saved meal identified by [id]. A hard delete with no
  /// cascade: logged `NutritionEntry` records are independent snapshot
  /// copies and remain unaffected.
  Future<Result<void, NutritionFailure>> deleteSavedMeal(String id);
}
