import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// Production [DietPlanSource] adapter backed by local `drift` (SQLite)
/// storage. Planned meals and substitutes persist on disk and survive app
/// restarts.
///
/// `drift` types (rows, tables, the generated database class) are CONFINED
/// to this file and [NutritionDatabase] — nothing here leaks into the
/// domain. This adapter NEVER produces [PermissionDenied]: that failure is
/// exclusive to platform-backed sources.
class SqlDietPlanSource implements DietPlanSource {
  SqlDietPlanSource(this._db);

  final NutritionDatabase _db;

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> listPlannedMeals({
    NutritionDay? day,
  }) async {
    try {
      final query = _db.select(_db.plannedMeals);
      if (day != null) {
        query.where((row) => row.dayEpoch.equals(day.epochDay));
      }
      final rows = await query.get();

      return Ok(rows.map(_toPlannedMeal).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> plannedMealsBetween(
    NutritionDay from,
    NutritionDay to,
  ) async {
    if (from.epochDay > to.epochDay) return const Ok([]);
    try {
      // `isBetweenValues` on a nullable column already excludes NULL days,
      // which is the documented contract: unscheduled meals are not calendar
      // commitments.
      final query = _db.select(_db.plannedMeals)
        ..where(
          (row) =>
              row.dayEpoch.isBiggerOrEqualValue(from.epochDay) &
              row.dayEpoch.isSmallerOrEqualValue(to.epochDay),
        );
      final rows = await query.get();
      return Ok(rows.map(_toPlannedMeal).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<PlannedMeal, NutritionFailure>> savePlannedMeal(
    PlannedMeal meal,
  ) async {
    try {
      final result = await _db
          .transaction<Result<PlannedMeal, NutritionFailure>>(() async {
            if (meal.day != null) {
              final existing =
                  await (_db.select(_db.plannedMeals)..where(
                        (row) =>
                            row.slotId.equals(meal.slotId) &
                            row.dayEpoch.equals(meal.day!.epochDay),
                      ))
                      .getSingleOrNull();
              if (existing != null && existing.id != meal.id) {
                return Err(
                  ConflictFailure(
                    'Slot ${meal.slotId} is already planned for ${meal.day}',
                  ),
                );
              }
            }

            await _db
                .into(_db.plannedMeals)
                .insert(
                  _toPlannedMealCompanion(meal),
                  mode: InsertMode.insertOrReplace,
                );

            return Ok(meal);
          });
      return result;
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> deletePlannedMeal(String id) async {
    try {
      await (_db.delete(
        _db.plannedMeals,
      )..where((row) => row.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<MealSubstitute>, NutritionFailure>> listSubstitutes(
    String plannedMealId,
  ) async {
    try {
      final rows = await (_db.select(
        _db.mealSubstitutes,
      )..where((row) => row.plannedMealId.equals(plannedMealId))).get();
      return Ok(rows.map(_toSubstitute).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<MealSubstitute, NutritionFailure>> saveSubstitute(
    MealSubstitute substitute,
  ) async {
    try {
      await _db
          .into(_db.mealSubstitutes)
          .insert(
            _toSubstituteCompanion(substitute),
            mode: InsertMode.insertOrReplace,
          );
      return Ok(substitute);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> deleteSubstitute(String id) async {
    try {
      await (_db.delete(
        _db.mealSubstitutes,
      )..where((row) => row.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  PlannedMealsCompanion _toPlannedMealCompanion(PlannedMeal meal) {
    final target = _targetValues(meal.targetSnapshot);
    return PlannedMealsCompanion.insert(
      id: meal.id,
      slotId: meal.slotId,
      dayEpoch: Value(meal.day?.epochDay),
      energyKcal: target.energyKcal,
      proteinG: target.proteinG,
      carbsG: target.carbsG,
      fatG: target.fatG,
    );
  }

  PlannedMeal _toPlannedMeal(PlannedMealRow row) {
    return PlannedMeal(
      id: row.id,
      slotId: row.slotId,
      day: _toDay(row.dayEpoch),
      targetSnapshot: _toTarget(
        energyKcal: row.energyKcal,
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
      ),
    );
  }

  MealSubstitutesCompanion _toSubstituteCompanion(MealSubstitute substitute) {
    final target = _targetValues(substitute.target);
    return MealSubstitutesCompanion.insert(
      id: substitute.id,
      plannedMealId: substitute.plannedMealId,
      label: substitute.label,
      energyKcal: target.energyKcal,
      proteinG: target.proteinG,
      carbsG: target.carbsG,
      fatG: target.fatG,
    );
  }

  MealSubstitute _toSubstitute(MealSubstituteRow row) {
    return MealSubstitute(
      id: row.id,
      plannedMealId: row.plannedMealId,
      label: row.label,
      target: _toTarget(
        energyKcal: row.energyKcal,
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
      ),
    );
  }

  NutritionTarget _toTarget({
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) {
    return NutritionTarget(
      energy: Energy(kcal: energyKcal),
      macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
    );
  }

  ({double energyKcal, double proteinG, double carbsG, double fatG})
  _targetValues(NutritionTarget target) {
    return (
      energyKcal: target.energy.kcal.toDouble(),
      proteinG: target.macros.proteinG.toDouble(),
      carbsG: target.macros.carbsG.toDouble(),
      fatG: target.macros.fatG.toDouble(),
    );
  }

  NutritionDay? _toDay(int? dayEpoch) {
    if (dayEpoch == null) return null;
    return NutritionDay.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(
        dayEpoch * Duration.millisecondsPerDay,
        isUtc: true,
      ),
    );
  }
}
