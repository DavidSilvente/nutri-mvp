import 'package:drift/drift.dart';

part 'nutrition_database.g.dart';

/// Local storage table for nutrition entries.
///
/// `drift` types are CONFINED to `data/` — the domain never sees this
/// table, its `DataClass`, or the generated database class. The row data
/// class is explicitly named [NutritionEntryRow] (instead of drift's
/// default `NutritionEntry`) to avoid colliding with the domain entity of
/// the same name.
@DataClassName('NutritionEntryRow')
class NutritionEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get recordedAt => dateTime()();

  /// Stable integer key for the calendar day, sourced from
  /// `NutritionDay.epochDay` — never recomputed inline here.
  IntColumn get dayEpoch => integer()();

  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local storage table for hydration (water) entries.
///
/// Hydration is an independent aggregate from [NutritionEntries] — see the
/// `hydration-log` design. This table was introduced by the schemaVersion
/// 1 -> 2 migration below, which also backfills any previously-recorded
/// water (`NutritionEntries.waterMl > 0`) into it before dropping that
/// column from [NutritionEntries].
@DataClassName('HydrationEntryRow')
class HydrationEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get recordedAt => dateTime()();

  /// Stable integer key for the calendar day, sourced from
  /// `NutritionDay.epochDay` — never recomputed inline here.
  IntColumn get dayEpoch => integer()();

  RealColumn get waterMl => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift database for the nutrition feature.
///
/// Production usage opens a file on disk (via `driftDatabase(name: ...)`);
/// tests open `NativeDatabase.memory()` — both share this same schema.
///
/// One physical database file, two tables ([NutritionEntries] for meals,
/// [HydrationEntries] for water) — see `hydration-log` design rationale for
/// why hydration isn't split into its own database file.
@DriftDatabase(tables: [NutritionEntries, HydrationEntries])
class NutritionDatabase extends _$NutritionDatabase {
  NutritionDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        // v1 -> v2: hydration becomes its own table. Preserve any
        // previously-recorded water as a standalone `HydrationEntry`
        // (prefixed id to avoid colliding with `NutritionEntries` ids),
        // then drop `waterMl` from `NutritionEntries` entirely. All three
        // steps run as a single atomic unit.
        await transaction(() async {
          await m.createTable(hydrationEntries);
          await customStatement('''
            INSERT INTO hydration_entries (id, recorded_at, day_epoch, water_ml)
            SELECT 'hydration-' || id, recorded_at, day_epoch, water_ml
            FROM nutrition_entries
            WHERE water_ml > 0;
          ''');
          // Portably drops `water_ml`: recreates `nutrition_entries` using
          // the current Dart table definition (which no longer declares
          // the column) instead of `ALTER TABLE ... DROP COLUMN`.
          await m.alterTable(TableMigration(nutritionEntries));
        });
      }
    },
  );
}
