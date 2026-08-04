import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// The v7 -> v8 migration only ADDS a table (`component_defaults`, the user's
/// standing per-component preference). Nothing existing is touched, so this
/// suite's job is narrower than the v6 -> v7 suite's: prove the new table
/// shows up empty and that every table that existed at v7 keeps its data
/// byte-for-byte.
void main() {
  /// Exactly the v7 DDL — every table [NutritionDatabase] declares today,
  /// hand-written so the test does not depend on the Dart schema it is meant
  /// to be an independent check on.
  sqlite3.Database openV7Raw() {
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
        planned_meal_id TEXT NULL REFERENCES planned_meals (id)
          ON DELETE SET NULL
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
      CREATE TABLE planned_meals (
        id TEXT NOT NULL PRIMARY KEY,
        slot_id TEXT NOT NULL,
        day_epoch INTEGER NULL,
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
        planned_meal_id TEXT NOT NULL REFERENCES planned_meals (id)
          ON DELETE CASCADE,
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
        declared_daily_energy_kcal REAL NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        source_label TEXT NULL,
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
    raw.execute('''
      CREATE TABLE saved_meals (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        portion_note TEXT NULL,
        energy_kcal REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    raw.execute('PRAGMA user_version = 7;');
    return raw;
  }

  /// Inserts one row per mutable table, so the "nothing lost" assertion has
  /// something to lose if the migration were wrong.
  void seedOneRowPerTable(sqlite3.Database raw) {
    raw.execute(
      'INSERT INTO planned_meals (id, slot_id, day_epoch, energy_kcal, '
      'protein_g, carbs_g, fat_g) '
      "VALUES ('pm-1', 'slot-1', 20500, 500.0, 30.0, 55.0, 15.0);",
    );
    raw.execute(
      'INSERT INTO nutrition_entries (id, recorded_at, day_epoch, '
      'energy_kcal, protein_g, carbs_g, fat_g, planned_meal_id) '
      "VALUES ('e-1', 1750000000000, 20500, 505.0, 31.0, 54.0, 15.0, 'pm-1');",
    );
    raw.execute(
      'INSERT INTO hydration_entries (id, recorded_at, day_epoch, water_ml) '
      "VALUES ('h-1', 1750000000000, 20500, 500.0);",
    );
    raw.execute(
      'INSERT INTO meal_substitutes (id, planned_meal_id, label, '
      'energy_kcal, protein_g, carbs_g, fat_g) '
      "VALUES ('sub-1', 'pm-1', 'Tofu bowl', 480.0, 32.0, 50.0, 14.0);",
    );
    raw.execute(
      'INSERT INTO menu_photos (id, local_uri, created_at) '
      "VALUES ('photo-1', 'file:///a.jpg', 1750000000000);",
    );
    raw.execute(
      'INSERT INTO menu_items (id, photo_id, label, energy_kcal, protein_g, '
      'carbs_g, fat_g) '
      "VALUES ('item-1', 'photo-1', 'Tostada', 200.0, 6.0, 30.0, 5.0);",
    );
    raw.execute(
      'INSERT INTO diet_plan_records (id, name, document, '
      'declared_daily_energy_kcal, is_default, source_label, imported_at) '
      'VALUES (\'plan-1\', \'Cut-A\', '
      '\'{"schemaVersion":1,"diet":{"name":"Cut-A","dayGroups":[]}}\', '
      '2950, 1, \'plan.pdf\', 1750000000000);',
    );
    raw.execute(
      'INSERT INTO component_selections (day_epoch, component_id, option_id) '
      "VALUES (20500, 'plan:g0:m0:c0', 'plan:g0:m0:c0:o1');",
    );
    raw.execute(
      'INSERT INTO saved_meals (id, name, portion_note, energy_kcal, '
      'protein_g, carbs_g, fat_g, created_at) '
      "VALUES ('saved-1', 'Batch bowl', NULL, 600.0, 40.0, 60.0, 20.0, "
      '1750000000000);',
    );
  }

  group('NutritionDatabase schema migration v7 -> v8', () {
    test(
      'adds an empty component_defaults table and keeps v7 data intact',
      () async {
        final raw = openV7Raw();
        seedOneRowPerTable(raw);

        final db = NutritionDatabase(NativeDatabase.opened(raw));
        addTearDown(db.close);

        // Opening runs the migration.
        expect(db.schemaVersion, 8);

        expect(await db.select(db.componentDefaults).get(), isEmpty);

        expect(await db.select(db.plannedMeals).get(), hasLength(1));
        expect(await db.select(db.nutritionEntries).get(), hasLength(1));
        expect(await db.select(db.hydrationEntries).get(), hasLength(1));
        expect(await db.select(db.mealSubstitutes).get(), hasLength(1));
        expect(await db.select(db.menuPhotos).get(), hasLength(1));
        expect(await db.select(db.menuItems).get(), hasLength(1));
        expect(await db.select(db.dietPlanRecords).get(), hasLength(1));
        expect(await db.select(db.componentSelections).get(), hasLength(1));
        expect(await db.select(db.savedMeals).get(), hasLength(1));

        final selection =
            (await db.select(db.componentSelections).get()).single;
        expect(selection.componentId, 'plan:g0:m0:c0');
        expect(selection.optionId, 'plan:g0:m0:c0:o1');
      },
    );

    test(
      'a fresh database is at v8 with an empty component_defaults',
      () async {
        final db = NutritionDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        expect(db.schemaVersion, 8);
        expect(await db.select(db.componentDefaults).get(), isEmpty);
      },
    );
  });
}
