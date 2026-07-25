import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('NutritionDatabase schema migration v1 -> v2', () {
    test('backfills water_ml > 0 into HydrationEntries and drops waterMl '
        'from NutritionEntries, leaving meal data intact', () async {
      // Hand-written v1 DDL: exactly what schemaVersion 1 produced,
      // including the since-removed `water_ml` column. We open this with
      // the raw `sqlite3` bindings (not drift) so nothing here depends on
      // the current (v2) generated schema.
      final raw = sqlite3.sqlite3.openInMemory();
      raw.execute('''
          CREATE TABLE nutrition_entries (
            id TEXT NOT NULL PRIMARY KEY,
            recorded_at INTEGER NOT NULL,
            day_epoch INTEGER NOT NULL,
            energy_kcal REAL NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL,
            water_ml REAL NOT NULL
          );
        ''');

      final day = DateTime.utc(2026, 7, 24);
      final dayEpoch =
          day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
      final recordedAtWithWater =
          DateTime.utc(2026, 7, 24, 9).millisecondsSinceEpoch ~/ 1000;
      final recordedAtNoWater =
          DateTime.utc(2026, 7, 24, 12).millisecondsSinceEpoch ~/ 1000;

      raw.execute(
        '''
          INSERT INTO nutrition_entries
            (id, recorded_at, day_epoch, energy_kcal, protein_g, carbs_g, fat_g, water_ml)
          VALUES
            ('meal-with-water', ?, ?, 500, 30, 40, 15, 250),
            ('meal-no-water', ?, ?, 300, 10, 20, 5, 0);
          ''',
        [recordedAtWithWater, dayEpoch, recordedAtNoWater, dayEpoch],
      );

      // Mark this raw connection as schema version 1, matching what a
      // real pre-migration app database on disk would carry.
      raw.execute('PRAGMA user_version = 1;');

      // Opening a `NutritionDatabase` (schemaVersion 2) against this raw
      // connection triggers `MigrationStrategy.onUpgrade(from: 1, to: 2)`
      // on first use.
      final database = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);

      // (1) HydrationEntries is populated ONLY from rows with
      // water_ml > 0.
      final hydrationRows = await database
          .select(database.hydrationEntries)
          .get();
      expect(hydrationRows, hasLength(1));
      final hydrationRow = hydrationRows.single;
      expect(hydrationRow.id, 'hydration-meal-with-water');
      expect(hydrationRow.waterMl, 250);
      expect(hydrationRow.dayEpoch, dayEpoch);
      expect(
        hydrationRow.recordedAt,
        DateTime.fromMillisecondsSinceEpoch(recordedAtWithWater * 1000),
      );

      // (2) NutritionEntries round-trip is intact: both meals survive the
      // table rebuild, with their original macro data, and the row shape
      // no longer exposes any water field at all (compile-time guarantee:
      // `NutritionEntryRow` has no `waterMl` getter after Fase 5).
      final nutritionRows = await database
          .select(database.nutritionEntries)
          .get();
      expect(nutritionRows, hasLength(2));

      final withWater = nutritionRows.firstWhere(
        (row) => row.id == 'meal-with-water',
      );
      expect(withWater.energyKcal, 500);
      expect(withWater.proteinG, 30);
      expect(withWater.carbsG, 40);
      expect(withWater.fatG, 15);

      final noWater = nutritionRows.firstWhere(
        (row) => row.id == 'meal-no-water',
      );
      expect(noWater.energyKcal, 300);
      expect(noWater.proteinG, 10);
      expect(noWater.carbsG, 20);
      expect(noWater.fatG, 5);

      // (3) The water_ml = 0 row must NOT have produced any hydration
      // entry (already implied by hasLength(1) above, asserted
      // explicitly for clarity of intent).
      expect(
        hydrationRows.any((row) => row.id == 'hydration-meal-no-water'),
        isFalse,
      );
    });

    test('a fresh database (no prior version) creates schema v2 directly '
        'without running any migration', () async {
      final database = NutritionDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final nutritionRows = await database
          .select(database.nutritionEntries)
          .get();
      final hydrationRows = await database
          .select(database.hydrationEntries)
          .get();

      expect(nutritionRows, isEmpty);
      expect(hydrationRows, isEmpty);
    });
  });
}
