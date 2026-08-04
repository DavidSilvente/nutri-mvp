import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// In-memory [DietPlanSource] test double.
///
/// Mirrors the contract the real SQL adapter MUST honor: planned meals enforce
/// unique (slot, day) assignments, and deleting one removes its substitutes.
/// This fake NEVER produces [PermissionDenied]: that failure is exclusive to
/// platform-backed sources.
class FakeDietPlanSource implements DietPlanSource {
  final Map<String, PlannedMeal> _plannedMeals = {};
  final Map<String, MealSubstitute> _substitutes = {};

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> listPlannedMeals({
    NutritionDay? day,
  }) async {
    final matches = _plannedMeals.values
        .where((meal) => day == null || meal.day == day)
        .toList(growable: false);

    return Ok(matches);
  }

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> plannedMealsBetween(
    NutritionDay from,
    NutritionDay to,
  ) async {
    if (from.epochDay > to.epochDay) return const Ok([]);
    final matches = _plannedMeals.values
        .where((meal) {
          final day = meal.day;
          if (day == null) return false;
          return day.epochDay >= from.epochDay && day.epochDay <= to.epochDay;
        })
        .toList(growable: false);
    return Ok(matches);
  }

  @override
  Future<Result<PlannedMeal, NutritionFailure>> savePlannedMeal(
    PlannedMeal meal,
  ) async {
    if (meal.day != null) {
      final duplicate = _plannedMeals.values.any(
        (m) => m.id != meal.id && m.slotId == meal.slotId && m.day == meal.day,
      );
      if (duplicate) {
        return Err(
          ConflictFailure(
            'Slot ${meal.slotId} is already planned for ${meal.day}',
          ),
        );
      }
    }
    _plannedMeals[meal.id] = meal;
    return Ok(meal);
  }

  @override
  Future<Result<void, NutritionFailure>> deletePlannedMeal(String id) async {
    _plannedMeals.remove(id);
    _substitutes.removeWhere((_, sub) => sub.plannedMealId == id);
    return const Ok(null);
  }

  @override
  Future<Result<List<MealSubstitute>, NutritionFailure>> listSubstitutes(
    String plannedMealId,
  ) async {
    final matches = _substitutes.values
        .where((sub) => sub.plannedMealId == plannedMealId)
        .toList(growable: false);
    return Ok(matches);
  }

  @override
  Future<Result<MealSubstitute, NutritionFailure>> saveSubstitute(
    MealSubstitute substitute,
  ) async {
    _substitutes[substitute.id] = substitute;
    return Ok(substitute);
  }

  @override
  Future<Result<void, NutritionFailure>> deleteSubstitute(String id) async {
    _substitutes.remove(id);
    return const Ok(null);
  }
}
