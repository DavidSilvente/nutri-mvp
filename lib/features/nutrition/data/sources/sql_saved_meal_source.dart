import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/saved_meal_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
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
class SqlSavedMealSource implements SavedMealSource {
  SqlSavedMealSource(this._db);

  final NutritionDatabase _db;

  @override
  Future<Result<List<SavedMeal>, NutritionFailure>> listSavedMeals() async {
    try {
      final query = _db.select(_db.savedMeals)
        ..orderBy([(row) => OrderingTerm.asc(row.name)]);
      final rows = await query.get();
      return Ok(rows.map(_toMeal).toList(growable: false));
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
      await (_db.delete(_db.savedMeals)..where((row) => row.id.equals(id)))
          .go();
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

  SavedMeal _toMeal(SavedMealRow row) {
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
    );
  }
}
