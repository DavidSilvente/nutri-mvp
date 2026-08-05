import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/saved_meal_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// Production [SavedMealSource] adapter backed by local `drift` (SQLite)
/// storage.
///
/// `drift` types stay CONFINED to this file and [NutritionDatabase]; nothing
/// here leaks into the domain. This adapter NEVER produces [PermissionDenied],
/// which is exclusive to platform-backed sources.
///
/// Duplicate-name uniqueness is enforced HERE, transactionally, comparing
/// [SavedMeal.normalizedName] — NOT through a schema `UNIQUE` constraint.
/// The rule is trim + Unicode-aware case folding, which drift's DSL cannot
/// express and SQLite `NOCASE` only approximates (ASCII-only). This mirrors
/// `SqlDietPlanStore`'s application-layer uniqueness check for
/// `DietPlanRecords.isDefault`.
///
/// [SavedMeal.ingredients] is written to
/// [NutritionDatabase.savedMealIngredients] as a DELETE-then-insert-all pair,
/// atomic with the owner row's upsert and the duplicate-name check inside one
/// transaction — a saved meal is a reusable TEMPLATE, so re-saving with an
/// edited composition must replace its rows, never append to them. Deleting
/// the owner row cascades to its ingredient rows via the FK (`PRAGMA
/// foreign_keys = ON`, set in `beforeOpen`); no explicit cleanup is needed
/// here. The read path rehydrates stored flat fields verbatim — see the
/// equivalent note on `SqlNutritionSource`.
class SqlSavedMealSource implements SavedMealSource {
  SqlSavedMealSource(this._db);

  final NutritionDatabase _db;

  @override
  Future<Result<List<SavedMeal>, NutritionFailure>> listSavedMeals() async {
    try {
      final query = _db.select(_db.savedMeals)
        ..orderBy([(row) => OrderingTerm.asc(row.name)]);
      final rows = await query.get();
      final meals = await Future.wait(rows.map(_toMeal));
      return Ok(meals.toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<SavedMeal, NutritionFailure>> saveMeal(SavedMeal meal) async {
    try {
      return await _db.transaction<Result<SavedMeal, NutritionFailure>>(
        () async {
          final rows = await _db.select(_db.savedMeals).get();
          final clash = rows.any(
            (row) =>
                row.id != meal.id &&
                row.name.trim().toLowerCase() == meal.normalizedName,
          );
          if (clash) {
            return Err(
              ConflictFailure('Saved meal name "${meal.name}" already exists'),
            );
          }

          await _db
              .into(_db.savedMeals)
              .insert(_toCompanion(meal), mode: InsertMode.insertOrReplace);
          await _writeIngredients(meal.id, meal.ingredients);

          return Ok(meal);
        },
      );
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> deleteSavedMeal(String id) async {
    try {
      await (_db.delete(
        _db.savedMeals,
      )..where((row) => row.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  SavedMealsCompanion _toCompanion(SavedMeal meal) {
    return SavedMealsCompanion.insert(
      id: meal.id,
      name: meal.name,
      portionNote: Value(meal.portionNote),
      energyKcal: meal.target.energy.kcal.toDouble(),
      proteinG: meal.target.macros.proteinG.toDouble(),
      carbsG: meal.target.macros.carbsG.toDouble(),
      fatG: meal.target.macros.fatG.toDouble(),
      createdAt: meal.createdAt,
    );
  }

  Future<SavedMeal> _toMeal(SavedMealRow row) async {
    return SavedMeal(
      id: row.id,
      name: row.name,
      target: NutritionTarget(
        energy: Energy(kcal: row.energyKcal),
        macros: Macros(
          proteinG: row.proteinG,
          carbsG: row.carbsG,
          fatG: row.fatG,
        ),
      ),
      portionNote: row.portionNote,
      createdAt: row.createdAt,
      ingredients: await _readIngredients(row.id),
    );
  }

  /// Replaces every ingredient row owned by [savedMealId] with
  /// [ingredients], assigning `position` densely from list index. Callers
  /// MUST run this inside the same transaction as the owner row's write.
  Future<void> _writeIngredients(
    String savedMealId,
    List<LoggedIngredient> ingredients,
  ) async {
    await (_db.delete(
      _db.savedMealIngredients,
    )..where((row) => row.savedMealId.equals(savedMealId))).go();
    if (ingredients.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_db.savedMealIngredients, [
        for (var i = 0; i < ingredients.length; i++)
          _toIngredientCompanion(savedMealId, ingredients[i], i),
      ]);
    });
  }

  Future<List<LoggedIngredient>> _readIngredients(String savedMealId) async {
    final query = _db.select(_db.savedMealIngredients)
      ..where((row) => row.savedMealId.equals(savedMealId))
      ..orderBy([(row) => OrderingTerm.asc(row.position)]);
    final rows = await query.get();
    return rows.map(_toIngredient).toList(growable: false);
  }

  SavedMealIngredientsCompanion _toIngredientCompanion(
    String savedMealId,
    LoggedIngredient ingredient,
    int position,
  ) {
    return SavedMealIngredientsCompanion.insert(
      savedMealId: savedMealId,
      foodId: ingredient.foodId,
      grams: ingredient.quantity.grams.toDouble(),
      count: Value(ingredient.quantity.count?.toDouble()),
      unit: Value(ingredient.quantity.unit),
      position: position,
    );
  }

  LoggedIngredient _toIngredient(SavedMealIngredientRow row) {
    return LoggedIngredient(
      foodId: row.foodId,
      quantity: FoodQuantity(grams: row.grams, count: row.count, unit: row.unit),
    );
  }
}
