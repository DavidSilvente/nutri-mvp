// `drift` also exports an `isNull` (a SQL expression builder), which would
// shadow the matcher of the same name from `flutter_test`.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('NutritionDatabase schema migration v3 -> v4', () {
    /// Hand-written v3 DDL: the schema exactly as it stood before
    /// `nutrition_entries.planned_meal_id` existed.
    sqlite3.Database openV3Raw() {
      final raw = sqlite3.sqlite3.openInMemory();
      raw.execute('''
          CREATE TABLE nutrition_entries (
            id TEXT NOT NULL PRIMARY KEY,
            recorded_at INTEGER NOT NULL,
            day_epoch INTEGER NOT NULL,
            energy_kcal REAL NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL
          );
        ''');
      raw.execute('''
          CREATE TABLE hydration_entries (
            id TEXT NOT NULL PRIMARY KEY,
            recorded_at INTEGER NOT NULL,
            day_epoch INTEGER NOT NULL,
            water_ml REAL NOT NULL
          );
        ''');
      raw.execute('''
          CREATE TABLE diet_templates (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            energy_kcal REAL NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
      raw.execute('''
          CREATE TABLE diet_meal_slots (
            id TEXT NOT NULL PRIMARY KEY,
            template_id TEXT NOT NULL REFERENCES diet_templates (id) ON DELETE CASCADE,
            label TEXT NOT NULL,
            position INTEGER NOT NULL,
            energy_kcal REAL NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL,
            UNIQUE (template_id, position)
          );
        ''');
      raw.execute('''
          CREATE TABLE planned_meals (
            id TEXT NOT NULL PRIMARY KEY,
            slot_id TEXT NOT NULL REFERENCES diet_meal_slots (id) ON DELETE CASCADE,
            day_epoch INTEGER,
            energy_kcal REAL NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL,
            UNIQUE (slot_id, day_epoch)
          );
        ''');
      raw.execute('''
          CREATE TABLE meal_substitutes (
            id TEXT NOT NULL PRIMARY KEY,
            planned_meal_id TEXT NOT NULL REFERENCES planned_meals (id) ON DELETE CASCADE,
            label TEXT NOT NULL,
            energy_kcal REAL NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL
          );
        ''');
      raw.execute('''
          CREATE TABLE menu_photos (
            id TEXT NOT NULL PRIMARY KEY,
            local_uri TEXT NOT NULL,
            created_at INTEGER NOT NULL
          );
        ''');
      raw.execute('''
          CREATE TABLE menu_items (
            id TEXT NOT NULL PRIMARY KEY,
            photo_id TEXT NOT NULL REFERENCES menu_photos (id) ON DELETE CASCADE,
            label TEXT NOT NULL,
            energy_kcal REAL NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL
          );
        ''');
      return raw;
    }

    test(
      'adds planned_meal_id to nutrition_entries and backfills it as NULL',
      () async {
        final raw = openV3Raw();
        raw.execute('PRAGMA user_version = 3;');
        raw.execute('''
            INSERT INTO nutrition_entries
              (id, recorded_at, day_epoch, energy_kcal, protein_g, carbs_g, fat_g)
            VALUES ('legacy-1', 1000, 20000, 500.0, 30.0, 40.0, 15.0);
          ''');

        final database = NutritionDatabase(NativeDatabase.opened(raw));
        addTearDown(database.close);

        // Trigger the migration by running a query.
        final rows = await database.select(database.nutritionEntries).get();

        expect(rows, hasLength(1));
        expect(rows.single.id, 'legacy-1');
        // Intake logged before planning existed is not retroactively
        // attributable to any meal.
        expect(rows.single.plannedMealId, isNull);
        expect(rows.single.energyKcal, 500.0);
      },
    );

    test('reports schema version 4 after migrating', () async {
      final raw = openV3Raw();
      raw.execute('PRAGMA user_version = 3;');

      final database = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);
      await database.select(database.nutritionEntries).get();

      final version = raw.select('PRAGMA user_version;').single.values.first;
      expect(version, 4);
    });

    test('accepts a new entry that carries a planned meal link', () async {
      final raw = openV3Raw();
      raw.execute('PRAGMA user_version = 3;');
      raw.execute('''
          INSERT INTO diet_templates
            (id, name, energy_kcal, protein_g, carbs_g, fat_g, created_at, updated_at)
          VALUES ('t1', 'Plan', 2000.0, 150.0, 200.0, 60.0, 0, 0);
        ''');
      raw.execute('''
          INSERT INTO diet_meal_slots
            (id, template_id, label, position, energy_kcal, protein_g, carbs_g, fat_g)
          VALUES ('s1', 't1', 'Lunch', 0, 600.0, 40.0, 60.0, 20.0);
        ''');
      raw.execute('''
          INSERT INTO planned_meals
            (id, slot_id, day_epoch, energy_kcal, protein_g, carbs_g, fat_g)
          VALUES ('pm1', 's1', 20000, 600.0, 40.0, 60.0, 20.0);
        ''');

      final database = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);

      await database
          .into(database.nutritionEntries)
          .insert(
            NutritionEntriesCompanion.insert(
              id: 'e1',
              recordedAt: DateTime(2026, 7, 24, 13),
              dayEpoch: 20000,
              energyKcal: 600,
              proteinG: 40,
              carbsG: 60,
              fatG: 20,
              plannedMealId: const Value('pm1'),
            ),
          );

      final row = await (database.select(
        database.nutritionEntries,
      )..where((r) => r.id.equals('e1'))).getSingle();
      expect(row.plannedMealId, 'pm1');
    });

    test(
      'deleting a planned meal nulls the link instead of deleting the intake',
      () async {
        final raw = openV3Raw();
        raw.execute('PRAGMA user_version = 3;');
        raw.execute('''
            INSERT INTO diet_templates
              (id, name, energy_kcal, protein_g, carbs_g, fat_g, created_at, updated_at)
            VALUES ('t1', 'Plan', 2000.0, 150.0, 200.0, 60.0, 0, 0);
          ''');
        raw.execute('''
            INSERT INTO diet_meal_slots
              (id, template_id, label, position, energy_kcal, protein_g, carbs_g, fat_g)
            VALUES ('s1', 't1', 'Lunch', 0, 600.0, 40.0, 60.0, 20.0);
          ''');
        raw.execute('''
            INSERT INTO planned_meals
              (id, slot_id, day_epoch, energy_kcal, protein_g, carbs_g, fat_g)
            VALUES ('pm1', 's1', 20000, 600.0, 40.0, 60.0, 20.0);
          ''');

        final database = NutritionDatabase(NativeDatabase.opened(raw));
        addTearDown(database.close);

        await database
            .into(database.nutritionEntries)
            .insert(
              NutritionEntriesCompanion.insert(
                id: 'e1',
                recordedAt: DateTime(2026, 7, 24, 13),
                dayEpoch: 20000,
                energyKcal: 600,
                proteinG: 40,
                carbsG: 60,
                fatG: 20,
                plannedMealId: const Value('pm1'),
              ),
            );

        await (database.delete(
          database.plannedMeals,
        )..where((r) => r.id.equals('pm1'))).go();

        // The historical fact that food was eaten MUST survive un-planning.
        final row = await (database.select(
          database.nutritionEntries,
        )..where((r) => r.id.equals('e1'))).getSingle();
        expect(row.plannedMealId, isNull);
        expect(row.energyKcal, 600.0);
      },
    );
  });
}
