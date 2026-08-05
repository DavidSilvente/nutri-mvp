import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/nutrition_health_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// Production [NutritionHealthSource] adapter backed by local `drift`
/// (SQLite) storage. Entries persist on disk and survive app restarts.
///
/// `drift` types (rows, tables, the generated database class) are CONFINED
/// to this file and [NutritionDatabase] — nothing here leaks into the
/// domain. This adapter NEVER produces [PermissionDenied]: that failure is
/// exclusive to platform-backed sources (e.g. a future HealthKit adapter).
///
/// [entry.ingredients] is written to [NutritionDatabase.intakeIngredients]
/// as a DELETE-then-insert-all pair, atomic with the owner row's upsert
/// inside one transaction — this table has no update path today, but a
/// second `record` call with the same id (an insertOrReplace) must not
/// leave stale ingredient rows from a previous write behind. The read path
/// rehydrates the stored flat `energy`/`macros` verbatim via the plain
/// [NutritionEntry] constructor — it NEVER calls [DerivedTargets.compose],
/// which would silently violate the snapshot rule (a catalog correction
/// must not retroactively rewrite already-logged history).
class SqlNutritionSource implements NutritionHealthSource {
  SqlNutritionSource(this._db);

  final NutritionDatabase _db;

  @override
  Future<Result<void, NutritionFailure>> record(NutritionEntry entry) async {
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.nutritionEntries)
            .insert(_toCompanion(entry), mode: InsertMode.insertOrReplace);
        await _writeIngredients(entry.id, entry.ingredients);
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<NutritionEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  ) async {
    try {
      final query = _db.select(_db.nutritionEntries)
        ..where((row) => row.dayEpoch.equals(day.epochDay))
        ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]);
      final rows = await query.get();
      final entries = await Future.wait(rows.map(_toEntity));
      return Ok(entries.toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<NutritionEntry>, NutritionFailure>> entriesBetween(
    NutritionDay from,
    NutritionDay to,
  ) async {
    if (from.epochDay > to.epochDay) return const Ok([]);
    try {
      final query = _db.select(_db.nutritionEntries)
        ..where(
          (row) =>
              row.dayEpoch.isBiggerOrEqualValue(from.epochDay) &
              row.dayEpoch.isSmallerOrEqualValue(to.epochDay),
        )
        ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]);
      final rows = await query.get();
      final entries = await Future.wait(rows.map(_toEntity));
      return Ok(entries.toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  NutritionEntriesCompanion _toCompanion(NutritionEntry entry) {
    return NutritionEntriesCompanion.insert(
      id: entry.id,
      recordedAt: entry.recordedAt,
      dayEpoch: NutritionDay.fromDateTime(entry.recordedAt).epochDay,
      energyKcal: entry.energy.kcal.toDouble(),
      proteinG: entry.macros.proteinG.toDouble(),
      carbsG: entry.macros.carbsG.toDouble(),
      fatG: entry.macros.fatG.toDouble(),
      plannedMealId: Value(entry.plannedMealId),
    );
  }

  Future<NutritionEntry> _toEntity(NutritionEntryRow row) async {
    return NutritionEntry(
      id: row.id,
      recordedAt: row.recordedAt,
      energy: Energy(kcal: row.energyKcal),
      macros: Macros(
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
      ),
      plannedMealId: row.plannedMealId,
      ingredients: await _readIngredients(row.id),
    );
  }

  /// Replaces every ingredient row owned by [entryId] with [ingredients],
  /// assigning `position` densely from list index. Callers MUST run this
  /// inside the same transaction as the owner row's write.
  Future<void> _writeIngredients(
    String entryId,
    List<LoggedIngredient> ingredients,
  ) async {
    await (_db.delete(
      _db.intakeIngredients,
    )..where((row) => row.entryId.equals(entryId))).go();
    if (ingredients.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_db.intakeIngredients, [
        for (var i = 0; i < ingredients.length; i++)
          _toIngredientCompanion(entryId, ingredients[i], i),
      ]);
    });
  }

  Future<List<LoggedIngredient>> _readIngredients(String entryId) async {
    final query = _db.select(_db.intakeIngredients)
      ..where((row) => row.entryId.equals(entryId))
      ..orderBy([(row) => OrderingTerm.asc(row.position)]);
    final rows = await query.get();
    return rows.map(_toIngredient).toList(growable: false);
  }

  IntakeIngredientsCompanion _toIngredientCompanion(
    String entryId,
    LoggedIngredient ingredient,
    int position,
  ) {
    return IntakeIngredientsCompanion.insert(
      entryId: entryId,
      foodId: ingredient.foodId,
      grams: ingredient.quantity.grams.toDouble(),
      count: Value(ingredient.quantity.count?.toDouble()),
      unit: Value(ingredient.quantity.unit),
      position: position,
    );
  }

  LoggedIngredient _toIngredient(IntakeIngredientRow row) {
    return LoggedIngredient(
      foodId: row.foodId,
      quantity: FoodQuantity(grams: row.grams, count: row.count, unit: row.unit),
    );
  }
}
