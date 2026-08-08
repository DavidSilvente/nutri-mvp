import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
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
///
/// [MealSubstitute.ingredients] is written to
/// [NutritionDatabase.mealSubstituteIngredients] as a DELETE-then-insert-all
/// pair, atomic with the owner row's upsert inside one transaction — a
/// substitute is an editable TEMPLATE like `SavedMeal`, so re-saving with an
/// edited composition must replace its rows, never append to them. Deleting
/// the owner row cascades to its ingredient rows via the FK; no explicit
/// cleanup is needed here. The read path rehydrates stored flat fields
/// verbatim — see the equivalent note on `SqlNutritionSource`. Planned meals
/// carry no composition (out of scope for this change) and are unaffected.
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
      final substitutes = await Future.wait(rows.map(_toSubstitute));
      return Ok(substitutes.toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<MealSubstitute, NutritionFailure>> saveSubstitute(
    MealSubstitute substitute,
  ) async {
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.mealSubstitutes)
            .insert(
              _toSubstituteCompanion(substitute),
              mode: InsertMode.insertOrReplace,
            );
        await _writeIngredients(substitute.id, substitute.ingredients);
      });
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

  Future<MealSubstitute> _toSubstitute(MealSubstituteRow row) async {
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
      ingredients: await _readIngredients(row.id),
    );
  }

  /// Replaces every ingredient row owned by [substituteId] with
  /// [ingredients], assigning `position` densely from list index. Callers
  /// MUST run this inside the same transaction as the owner row's write.
  Future<void> _writeIngredients(
    String substituteId,
    List<LoggedIngredient> ingredients,
  ) async {
    await (_db.delete(
      _db.mealSubstituteIngredients,
    )..where((row) => row.substituteId.equals(substituteId))).go();
    if (ingredients.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_db.mealSubstituteIngredients, [
        for (var i = 0; i < ingredients.length; i++)
          _toIngredientCompanion(substituteId, ingredients[i], i),
      ]);
    });
  }

  Future<List<LoggedIngredient>> _readIngredients(String substituteId) async {
    final query = _db.select(_db.mealSubstituteIngredients)
      ..where((row) => row.substituteId.equals(substituteId))
      ..orderBy([(row) => OrderingTerm.asc(row.position)]);
    final rows = await query.get();
    return rows.map(_toIngredient).toList(growable: false);
  }

  MealSubstituteIngredientsCompanion _toIngredientCompanion(
    String substituteId,
    LoggedIngredient ingredient,
    int position,
  ) {
    return MealSubstituteIngredientsCompanion.insert(
      substituteId: substituteId,
      foodId: ingredient.foodId,
      grams: ingredient.quantity.grams.toDouble(),
      count: Value(ingredient.quantity.count?.toDouble()),
      unit: Value(ingredient.quantity.unit),
      position: position,
    );
  }

  LoggedIngredient _toIngredient(MealSubstituteIngredientRow row) {
    return LoggedIngredient(
      foodId: row.foodId,
      quantity: FoodQuantity(grams: row.grams, count: row.count, unit: row.unit),
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
