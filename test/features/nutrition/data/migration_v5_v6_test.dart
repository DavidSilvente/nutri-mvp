import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('NutritionDatabase schema migration v5 -> v6', () {
    /// Hand-written v5 DDL: the schema exactly as it stood before the
    /// saved-meal catalogue existed.
    sqlite3.Database openV5Raw() {
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
            planned_meal_id TEXT REFERENCES planned_meals (id) ON DELETE SET NULL
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
      raw.execute('''
          CREATE TABLE diet_plan_records (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            document TEXT NOT NULL,
            declared_daily_energy_kcal REAL,
            is_default INTEGER NOT NULL DEFAULT 0,
            source_label TEXT,
            imported_at INTEGER NOT NULL
          );
        ''');
      raw.execute('''
          CREATE TABLE component_selections (
            day_epoch INTEGER NOT NULL,
            component_id TEXT NOT NULL,
            option_id TEXT NOT NULL,
            PRIMARY KEY (day_epoch, component_id)
          );
        ''');
      return raw;
    }

    test('creates saved_meals and leaves existing data intact', () async {
      final raw = openV5Raw();
      raw.execute('PRAGMA user_version = 5;');
      // A pre-existing intake row must survive the upgrade untouched: this is
      // what a real user's phone looks like before the update.
      raw.execute('''
          INSERT INTO nutrition_entries
            (id, recorded_at, day_epoch, energy_kcal, protein_g, carbs_g, fat_g,
             planned_meal_id)
          VALUES ('entry-1', 1750000000000, 20300, 500.0, 40.0, 50.0, 15.0, NULL);
        ''');
      raw.execute('''
          INSERT INTO diet_plan_records
            (id, name, document, declared_daily_energy_kcal, is_default,
             source_label, imported_at)
          VALUES ('plan-1', 'Ajuste 2950', '{"schemaVersion":1}', NULL, 1, NULL,
                  1750000000000);
        ''');

      final db = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      // Opening runs the migration.
      final entries = await db.select(db.nutritionEntries).get();
      expect(entries, hasLength(1));
      expect(entries.single.id, 'entry-1');
      expect(entries.single.energyKcal, 500.0);

      final plans = await db.select(db.dietPlanRecords).get();
      expect(plans, hasLength(1));
      expect(plans.single.id, 'plan-1');

      // The chain does not stop at v6: opening runs every step, all the way to
      // v8, which adds the (empty, for this test) component_defaults table.
      expect(db.schemaVersion, 9);

      // The new table exists and is empty.
      expect(await db.select(db.savedMeals).get(), isEmpty);
    });

    test(
      'a fresh v6 database has the saved_meals table from the start',
      () async {
        final db = NutritionDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        expect(await db.select(db.savedMeals).get(), isEmpty);
      },
    );

    test('a v1 -> v6 pass keeps nutrition_entries intact '
        '(guards the newColumns trap)', () async {
      // Hand-written v1 DDL: exactly what schemaVersion 1 produced, including
      // the since-removed `water_ml` column and no `planned_meal_id` column
      // at all. This exercises the FULL migration chain, so if a future
      // column added to `NutritionEntries` after v2 is missing from the
      // `TableMigration.newColumns` list in the v1 -> v2 step, this test
      // fails with "no such column" instead of a real user's phone silently
      // losing data on update.
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
      raw.execute('''
          INSERT INTO nutrition_entries
            (id, recorded_at, day_epoch, energy_kcal, protein_g, carbs_g,
             fat_g, water_ml)
          VALUES ('entry-1', 1750000000000, 20300, 500.0, 40.0, 50.0, 15.0, 0);
        ''');
      raw.execute('PRAGMA user_version = 1;');

      final db = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final entries = await db.select(db.nutritionEntries).get();
      expect(entries, hasLength(1));
      expect(entries.single.id, 'entry-1');
      expect(entries.single.energyKcal, 500.0);
      expect(entries.single.plannedMealId, isNull);

      // The chain does not stop at v6: opening runs every step, all the way to
      // v8, which adds the (empty, for this test) component_defaults table.
      expect(db.schemaVersion, 9);
      expect(await db.select(db.savedMeals).get(), isEmpty);
    });
  });
}
