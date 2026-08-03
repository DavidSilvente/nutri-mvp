import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/saved_meal_source.dart';

/// In-memory [SavedMealSource] test double.
///
/// Mirrors the contract the real SQL adapter MUST honor: names are unique
/// when compared via [SavedMeal.normalizedName], and saving under an
/// existing id (an edit) is never a conflict. This fake NEVER produces
/// [PermissionDenied]: that failure is exclusive to platform-backed sources.
class FakeSavedMealSource implements SavedMealSource {
  final Map<String, SavedMeal> _meals = {};

  @override
  Future<Result<List<SavedMeal>, NutritionFailure>> listSavedMeals() async {
    final values = _meals.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    return Ok(values);
  }

  @override
  Future<Result<SavedMeal, NutritionFailure>> saveMeal(SavedMeal meal) async {
    final duplicate = _meals.values.any(
      (m) => m.id != meal.id && m.normalizedName == meal.normalizedName,
    );
    if (duplicate) {
      return Err(
        ConflictFailure('Saved meal name "${meal.name}" already exists'),
      );
    }

    _meals[meal.id] = meal;
    return Ok(meal);
  }

  @override
  Future<Result<void, NutritionFailure>> deleteSavedMeal(String id) async {
    _meals.remove(id);
    return const Ok(null);
  }
}
