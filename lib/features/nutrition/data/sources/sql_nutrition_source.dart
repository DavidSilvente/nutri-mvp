import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/nutrition_health_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// Production [NutritionHealthSource] adapter backed by local `drift`
/// (SQLite) storage. Entries persist on disk and survive app restarts.
///
/// `drift` types (rows, tables, the generated database class) are CONFINED
/// to this file and [NutritionDatabase] — nothing here leaks into the
/// domain. This adapter NEVER produces [PermissionDenied]: that failure is
/// exclusive to platform-backed sources (e.g. a future HealthKit adapter).
class SqlNutritionSource implements NutritionHealthSource {
  SqlNutritionSource(this._db);

  final NutritionDatabase _db;

  @override
  Future<Result<void, NutritionFailure>> record(NutritionEntry entry) async {
    try {
      await _db
          .into(_db.nutritionEntries)
          .insert(_toCompanion(entry), mode: InsertMode.insertOrReplace);
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
      return Ok(rows.map(_toEntity).toList(growable: false));
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
    );
  }

  NutritionEntry _toEntity(NutritionEntryRow row) {
    return NutritionEntry(
      id: row.id,
      recordedAt: row.recordedAt,
      energy: Energy(kcal: row.energyKcal),
      macros: Macros(
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
      ),
    );
  }
}
