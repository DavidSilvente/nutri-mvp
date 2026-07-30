import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/hydration_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';

/// Production [HydrationSource] adapter backed by local `drift` (SQLite)
/// storage. Entries persist on disk and survive app restarts.
///
/// Reuses the SAME [NutritionDatabase] as [SqlNutritionSource] (one
/// physical database file, two independent tables) — see `hydration-log`
/// design. `drift` types (rows, tables, the generated database class) are
/// CONFINED to this file and [NutritionDatabase] — nothing here leaks into
/// the domain. This adapter NEVER produces [PermissionDenied]: that failure
/// is exclusive to platform-backed sources (e.g. a future HealthKit
/// adapter).
class SqlHydrationSource implements HydrationSource {
  SqlHydrationSource(this._db);

  final NutritionDatabase _db;

  @override
  Future<Result<void, NutritionFailure>> record(HydrationEntry entry) async {
    try {
      await _db
          .into(_db.hydrationEntries)
          .insert(_toCompanion(entry), mode: InsertMode.insertOrReplace);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<HydrationEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  ) async {
    try {
      final query = _db.select(_db.hydrationEntries)
        ..where((row) => row.dayEpoch.equals(day.epochDay))
        ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]);
      final rows = await query.get();
      return Ok(rows.map(_toEntity).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  HydrationEntriesCompanion _toCompanion(HydrationEntry entry) {
    return HydrationEntriesCompanion.insert(
      id: entry.id,
      recordedAt: entry.recordedAt,
      dayEpoch: NutritionDay.fromDateTime(entry.recordedAt).epochDay,
      waterMl: entry.volume.ml.toDouble(),
    );
  }

  HydrationEntry _toEntity(HydrationEntryRow row) {
    return HydrationEntry(
      id: row.id,
      recordedAt: row.recordedAt,
      volume: WaterVolume(ml: row.waterMl),
    );
  }
}
