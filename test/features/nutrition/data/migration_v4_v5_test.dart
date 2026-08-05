import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('NutritionDatabase schema migration v4 -> v5', () {
    /// Hand-written v4 DDL: the schema exactly as it stood before imported diet
    /// plans and per-day alternative selections existed.
    sqlite3.Database openV4Raw() {
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
      return raw;
    }

    test(
      'creates the two new tables and leaves existing data intact',
      () async {
        final raw = openV4Raw();
        raw.execute('PRAGMA user_version = 4;');
        // A pre-existing intake row must survive the upgrade untouched: this is
        // what a real user's phone looks like before the update.
        raw.execute('''
          INSERT INTO nutrition_entries
            (id, recorded_at, day_epoch, energy_kcal, protein_g, carbs_g, fat_g,
             planned_meal_id)
          VALUES ('entry-1', 1750000000000, 20300, 500.0, 40.0, 50.0, 15.0, NULL);
        ''');
        raw.execute('''
          INSERT INTO hydration_entries
            (id, recorded_at, day_epoch, water_ml)
          VALUES ('hydration-1', 1750000000000, 20300, 750.0);
        ''');

        final db = NutritionDatabase(NativeDatabase.opened(raw));
        addTearDown(db.close);

        // Opening runs the migration.
        final entries = await db.select(db.nutritionEntries).get();
        expect(entries, hasLength(1));
        expect(entries.single.id, 'entry-1');
        expect(entries.single.energyKcal, 500.0);
        final hydration = await db.select(db.hydrationEntries).get();
        expect(hydration, hasLength(1));

        // Compared against the database's own schemaVersion rather than a
        // hardcoded number: a v4 database must land on whatever the CURRENT
        // schema is, so this keeps asserting the real property (the whole
        // migration chain ran) instead of needing an edit on every version
        // bump.
        final version = raw.select('PRAGMA user_version;').single.values.first;
        expect(version, db.schemaVersion);

        // The new tables exist and are empty.
        expect(await db.select(db.dietPlanRecords).get(), isEmpty);
        expect(await db.select(db.componentSelections).get(), isEmpty);
      },
    );

    test('the migrated database can store a plan and a selection', () async {
      final raw = openV4Raw();
      raw.execute('PRAGMA user_version = 4;');

      final db = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);
      final store = SqlDietPlanStore(db);

      final saved = await store.savePlan(
        StoredDietPlan(
          id: 'plan-1',
          name: 'Ajuste 2950',
          document: '{"schemaVersion":1}',
          importedAt: DateTime.utc(2026, 8, 1),
        ),
      );
      expect(saved, isA<Ok<StoredDietPlan, Object>>());

      final day = NutritionDay.fromDateTime(DateTime.utc(2026, 8, 1));
      await store.selectOption(
        day: day,
        componentId: 'plan-1:g0:m0:c0',
        optionId: 'plan-1:g0:m0:c0:o1',
      );

      final selections = await store.selectionsFor(day);
      expect(
        switch (selections) {
          Ok(value: final value) => value,
          Err() => fail('expected Ok'),
        },
        {'plan-1:g0:m0:c0': 'plan-1:g0:m0:c0:o1'},
      );
    });

    test('a fresh v5 database has both new tables from the start', () async {
      final db = NutritionDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      expect(await db.select(db.dietPlanRecords).get(), isEmpty);
      expect(await db.select(db.componentSelections).get(), isEmpty);
    });
  });
}
