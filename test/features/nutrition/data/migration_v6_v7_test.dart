import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/save_manual_diet.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// The v6 -> v7 migration is the one that DELETES a table the user's data lived
/// in, so it gets the most pointed tests in this suite.
///
/// Two things must hold, or a real phone loses history on update:
///
/// * every hand-built template comes back as a plan document, with its slot ids
///   byte-identical — the calendar's planned meals reference them;
/// * `planned_meals` survives losing its foreign key to `diet_meal_slots`.
void main() {
  /// Exactly the v6 DDL, including the two tables v7 drops and the foreign key
  /// v7 removes. Hand-written on purpose: the Dart schema no longer describes
  /// this shape, so it cannot be derived from it.
  sqlite3.Database openV6Raw() {
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
        template_id TEXT NOT NULL REFERENCES diet_templates (id)
          ON DELETE CASCADE,
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
        slot_id TEXT NOT NULL REFERENCES diet_meal_slots (id)
          ON DELETE CASCADE,
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
    raw.execute('PRAGMA user_version = 6;');
    return raw;
  }

  /// Adds a v6 hand-built template with two meal slots.
  void seedTemplate(
    sqlite3.Database raw, {
    String id = 't1',
    String name = 'Cut-A',
  }) {
    raw.execute(
      'INSERT INTO diet_templates (id, name, energy_kcal, protein_g, '
      'carbs_g, fat_g, created_at, updated_at) '
      'VALUES (?, ?, 1200, 70, 130, 35, 0, 0);',
      [id, name],
    );
    raw.execute(
      'INSERT INTO diet_meal_slots (id, template_id, label, position, '
      'energy_kcal, protein_g, carbs_g, fat_g) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?);',
      ['$id-slot-breakfast', id, 'Breakfast', 0, 500.0, 30.0, 55.0, 15.0],
    );
    raw.execute(
      'INSERT INTO diet_meal_slots (id, template_id, label, position, '
      'energy_kcal, protein_g, carbs_g, fat_g) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?);',
      ['$id-slot-lunch', id, 'Lunch', 1, 700.0, 40.0, 75.0, 20.0],
    );
  }

  group('NutritionDatabase schema migration v6 -> v7', () {
    test('rewrites a hand-built template as a plan document', () async {
      final raw = openV6Raw();
      seedTemplate(raw);

      final db = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      // Opening runs the migration.
      final plans = await db.select(db.dietPlanRecords).get();

      // The chain does not stop at v7: opening runs every step, and v8 adds
      // the (empty, for this test) component_defaults table.
      expect(db.schemaVersion, 8);
      expect(plans, hasLength(1));
      final plan = plans.single;
      expect(plan.id, 't1');
      expect(plan.name, 'Cut-A');
      // Migrated diets are editable in the app, so they carry the same marker a
      // diet written there does.
      expect(plan.sourceLabel, SaveManualDiet.manualSourceLabel);
      // The only diet, so it becomes the active one.
      expect(plan.isDefault, isTrue);

      final document = jsonDecode(plan.document) as Map<String, Object?>;
      final diet = document['diet'] as Map<String, Object?>;
      final groups = diet['dayGroups'] as List<Object?>;
      expect(groups, hasLength(1));

      final group = groups.single as Map<String, Object?>;
      // A v3 template said nothing about weekdays, so the faithful reading is
      // that it applies to all of them.
      expect(group['weekdays'], [1, 2, 3, 4, 5, 6, 7]);

      final meals = (group['meals'] as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(meals.map((m) => m['label']), ['Breakfast', 'Lunch']);
      // THE critical assertion: slot ids carry over verbatim, because the
      // calendar's planned meals point at them.
      expect(meals.map((m) => m['slotId']), [
        't1-slot-breakfast',
        't1-slot-lunch',
      ]);
      expect(
        (meals.first['target'] as Map<String, Object?>)['energyKcal'],
        500.0,
      );
    });

    test('keeps planned meals and the intake logged against them', () async {
      final raw = openV6Raw();
      seedTemplate(raw);
      raw.execute(
        'INSERT INTO planned_meals (id, slot_id, day_epoch, energy_kcal, '
        'protein_g, carbs_g, fat_g) '
        "VALUES ('pm-1', 't1-slot-breakfast', 20500, 500.0, 30.0, 55.0, 15.0);",
      );
      raw.execute(
        'INSERT INTO meal_substitutes (id, planned_meal_id, label, '
        'energy_kcal, protein_g, carbs_g, fat_g) '
        "VALUES ('sub-1', 'pm-1', 'Tofu bowl', 480.0, 32.0, 50.0, 14.0);",
      );
      raw.execute(
        'INSERT INTO nutrition_entries (id, recorded_at, day_epoch, '
        'energy_kcal, protein_g, carbs_g, fat_g, planned_meal_id) '
        "VALUES ('e-1', 1750000000000, 20500, 505.0, 31.0, 54.0, 15.0, 'pm-1');",
      );

      final db = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final meals = await db.select(db.plannedMeals).get();
      expect(meals, hasLength(1));
      expect(meals.single.id, 'pm-1');
      expect(meals.single.slotId, 't1-slot-breakfast');
      expect(meals.single.dayEpoch, 20500);
      expect(meals.single.energyKcal, 500.0);

      expect(await db.select(db.mealSubstitutes).get(), hasLength(1));

      final entries = await db.select(db.nutritionEntries).get();
      expect(entries.single.plannedMealId, 'pm-1');
    });

    test('drops the template tables once their contents are safe', () async {
      final raw = openV6Raw();
      seedTemplate(raw);

      final db = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);
      await db.select(db.dietPlanRecords).get();

      for (final table in ['diet_templates', 'diet_meal_slots']) {
        expect(
          raw.select(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
            [table],
          ),
          isEmpty,
          reason: '$table should be gone',
        );
      }
    });

    test(
      'planned_meals loses its foreign key, so a slot id may be unknown',
      () async {
        // This is the point of recreating the table. A diet now lives in a
        // document; nothing enforces that a planned meal's slot still exists, and
        // it must not, or deleting a diet would erase the history judged against
        // it.
        final raw = openV6Raw();

        final db = NutritionDatabase(NativeDatabase.opened(raw));
        addTearDown(db.close);
        await db.select(db.plannedMeals).get();

        raw.execute(
          'INSERT INTO planned_meals (id, slot_id, day_epoch, energy_kcal, '
          'protein_g, carbs_g, fat_g) '
          "VALUES ('pm-orphan', 'slot-from-a-deleted-diet', 20500, "
          '500.0, 30.0, 55.0, 15.0);',
        );

        final meals = await db.select(db.plannedMeals).get();
        expect(meals.single.slotId, 'slot-from-a-deleted-diet');
      },
    );

    test('does not switch the diet of a user who already chose one', () async {
      final raw = openV6Raw();
      seedTemplate(raw);
      raw.execute(
        'INSERT INTO diet_plan_records (id, name, document, '
        'declared_daily_energy_kcal, is_default, source_label, imported_at) '
        'VALUES (\'imported-1\', \'Nutrium 2950\', '
        '\'{"schemaVersion":1,"diet":{"name":"x","dayGroups":[]}}\', '
        '2950, 1, \'plan.pdf\', 1750000000000);',
      );

      final db = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final plans = await db.select(db.dietPlanRecords).get();
      expect(plans, hasLength(2));

      final active = plans.where((p) => p.isDefault).toList();
      expect(active, hasLength(1), reason: 'exactly one diet may be active');
      expect(
        active.single.id,
        'imported-1',
        reason: 'the diet the user had chosen stays active',
      );
    });

    test('suffixes a migrated name that an imported plan already uses', () async {
      // `diet_plan_records.name` is UNIQUE, so a collision would abort the whole
      // update if it were not handled.
      final raw = openV6Raw();
      seedTemplate(raw, name: 'Cut-A');
      raw.execute(
        'INSERT INTO diet_plan_records (id, name, document, '
        'declared_daily_energy_kcal, is_default, source_label, imported_at) '
        'VALUES (\'imported-1\', \'Cut-A\', '
        '\'{"schemaVersion":1,"diet":{"name":"x","dayGroups":[]}}\', '
        'NULL, 1, \'plan.pdf\', 1750000000000);',
      );

      final db = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final names =
          (await db.select(db.dietPlanRecords).get())
              .map((p) => p.name)
              .toList()
            ..sort();
      expect(names, ['Cut-A', 'Cut-A (2)']);
    });

    test(
      'skips a template that has no meals, since it prescribes nothing',
      () async {
        final raw = openV6Raw();
        raw.execute(
          'INSERT INTO diet_templates (id, name, energy_kcal, protein_g, '
          'carbs_g, fat_g, created_at, updated_at) '
          "VALUES ('empty', 'Empty', 0, 0, 0, 0, 0, 0);",
        );

        final db = NutritionDatabase(NativeDatabase.opened(raw));
        addTearDown(db.close);

        expect(await db.select(db.dietPlanRecords).get(), isEmpty);
      },
    );

    test('a fresh database is at v7 with no template tables', () async {
      final db = NutritionDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      expect(await db.select(db.plannedMeals).get(), isEmpty);
      // The chain does not stop at v7: opening runs every step, and v8 adds
      // the (empty, for this test) component_defaults table.
      expect(db.schemaVersion, 8);
    });
  });
}
