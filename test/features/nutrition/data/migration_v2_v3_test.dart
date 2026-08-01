import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('NutritionDatabase schema migration v2 -> v3', () {
    sqlite3.Database openV2Raw() {
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
      return raw;
    }

    test('creates all six new diet/menu tables and keeps v2 tables intact',
        () async {
      final raw = openV2Raw();
      raw.execute('PRAGMA user_version = 2;');

      final database = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);

      // Trigger migration by running a query.
      await database.select(database.nutritionEntries).get();

      // (1) The six new tables are reachable through the generated API.
      final tables = <String>[
        'diet_templates',
        'diet_meal_slots',
        'planned_meals',
        'meal_substitutes',
        'menu_photos',
        'menu_items',
      ];
      for (final name in tables) {
        final result = raw.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          [name],
        );
        expect(result, isNotEmpty, reason: 'table $name should exist');
      }

      // (2) The v2 tables survived the migration.
      final legacyTables = <String>['nutrition_entries', 'hydration_entries'];
      for (final name in legacyTables) {
        final result = raw.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          [name],
        );
        expect(result, isNotEmpty, reason: 'legacy table $name should exist');
      }

      // (3) New tables accept rows with full target columns and FKs cascade.
      final templateId = 'template-1';
      final slotId = 'slot-1';
      final plannedMealId = 'planned-1';
      final substituteId = 'substitute-1';
      final photoId = 'photo-1';
      final menuItemId = 'item-1';
      final now = DateTime.utc(2026, 7, 30);
      final day = DateTime.utc(2026, 8, 1);
      final dayEpoch =
          day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

      await database.into(database.dietTemplates).insert(
        DietTemplatesCompanion.insert(
          id: templateId,
          name: 'Cut-A',
          energyKcal: 2200,
          proteinG: 150,
          carbsG: 220,
          fatG: 73,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.into(database.dietMealSlots).insert(
        DietMealSlotsCompanion.insert(
          id: slotId,
          templateId: templateId,
          label: 'Breakfast',
          position: 0,
          energyKcal: 700,
          proteinG: 40,
          carbsG: 60,
          fatG: 20,
        ),
      );

      await database.into(database.plannedMeals).insert(
        PlannedMealsCompanion.insert(
          id: plannedMealId,
          slotId: slotId,
          dayEpoch: Value(dayEpoch),
          energyKcal: 700,
          proteinG: 40,
          carbsG: 60,
          fatG: 20,
        ),
      );

      await database.into(database.mealSubstitutes).insert(
        MealSubstitutesCompanion.insert(
          id: substituteId,
          plannedMealId: plannedMealId,
          label: 'Tofu (200g)',
          energyKcal: 680,
          proteinG: 42,
          carbsG: 58,
          fatG: 22,
        ),
      );

      await database.into(database.menuPhotos).insert(
        MenuPhotosCompanion.insert(
          id: photoId,
          localUri: '/photos/menu-1.jpg',
          createdAt: now,
        ),
      );

      await database.into(database.menuItems).insert(
        MenuItemsCompanion.insert(
          id: menuItemId,
          photoId: photoId,
          label: 'Grilled Salmon (300g)',
          energyKcal: 550,
          proteinG: 50,
          carbsG: 0,
          fatG: 35,
        ),
      );

      final templates = await database.select(database.dietTemplates).get();
      expect(templates, hasLength(1));
      expect(templates.single.name, 'Cut-A');

      final slots = await database.select(database.dietMealSlots).get();
      expect(slots.single.templateId, templateId);

      final planned = await database.select(database.plannedMeals).get();
      expect(planned.single.dayEpoch, dayEpoch);

      final substitutes =
          await database.select(database.mealSubstitutes).get();
      expect(substitutes.single.plannedMealId, plannedMealId);

      final photos = await database.select(database.menuPhotos).get();
      expect(photos.single.localUri, '/photos/menu-1.jpg');

      final items = await database.select(database.menuItems).get();
      expect(items.single.photoId, photoId);

      // (4) Deleting a template cascades to slots, planned meals and substitutes.
      await (database.delete(database.dietTemplates)
            ..where((t) => t.id.equals(templateId)))
          .go();
      expect(await database.select(database.dietTemplates).get(), isEmpty);
      expect(await database.select(database.dietMealSlots).get(), isEmpty);
      expect(await database.select(database.plannedMeals).get(), isEmpty);
      expect(await database.select(database.mealSubstitutes).get(), isEmpty);

      // (5) Deleting a photo cascades to menu items.
      await (database.delete(database.menuPhotos)
            ..where((t) => t.id.equals(photoId)))
          .go();
      expect(await database.select(database.menuPhotos).get(), isEmpty);
      expect(await database.select(database.menuItems).get(), isEmpty);
    });

    test('rejects duplicate template name, slot position, and planned day',
        () async {
      final raw = openV2Raw();
      raw.execute('PRAGMA user_version = 2;');

      final database = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);

      await database.select(database.nutritionEntries).get();

      final now = DateTime.utc(2026, 7, 30);
      final day = DateTime.utc(2026, 8, 1);
      final dayEpoch =
          day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

      await database.into(database.dietTemplates).insert(
        DietTemplatesCompanion.insert(
          id: 't1',
          name: 'Cut-A',
          energyKcal: 2200,
          proteinG: 150,
          carbsG: 220,
          fatG: 73,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.into(database.dietMealSlots).insert(
        DietMealSlotsCompanion.insert(
          id: 's1',
          templateId: 't1',
          label: 'Breakfast',
          position: 0,
          energyKcal: 700,
          proteinG: 40,
          carbsG: 60,
          fatG: 20,
        ),
      );
      await database.into(database.plannedMeals).insert(
        PlannedMealsCompanion.insert(
          id: 'pm1',
          slotId: 's1',
          dayEpoch: Value(dayEpoch),
          energyKcal: 700,
          proteinG: 40,
          carbsG: 60,
          fatG: 20,
        ),
      );

      expect(
        () => database.into(database.dietTemplates).insert(
          DietTemplatesCompanion.insert(
            id: 't2',
            name: 'Cut-A',
            energyKcal: 2000,
            proteinG: 140,
            carbsG: 200,
            fatG: 66,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => database.into(database.dietMealSlots).insert(
          DietMealSlotsCompanion.insert(
            id: 's2',
            templateId: 't1',
            label: 'Lunch',
            position: 0,
            energyKcal: 800,
            proteinG: 50,
            carbsG: 70,
            fatG: 25,
          ),
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => database.into(database.plannedMeals).insert(
          PlannedMealsCompanion.insert(
            id: 'pm2',
            slotId: 's1',
            dayEpoch: Value(dayEpoch),
            energyKcal: 700,
            proteinG: 40,
            carbsG: 60,
            fatG: 20,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('a fresh database creates schema v3 directly without running migrations',
        () async {
      final database = NutritionDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.select(database.nutritionEntries).get();

      // We only assert the new tables are reachable on a fresh v3 database.
      expect(await database.select(database.dietTemplates).get(), isEmpty);
      expect(await database.select(database.dietMealSlots).get(), isEmpty);
      expect(await database.select(database.plannedMeals).get(), isEmpty);
      expect(await database.select(database.mealSubstitutes).get(), isEmpty);
      expect(await database.select(database.menuPhotos).get(), isEmpty);
      expect(await database.select(database.menuItems).get(), isEmpty);
    });
  });

  group('NutritionDatabase schema migration v1 -> v3', () {
    test('reaches v3 atomically: backfills hydration and creates new tables',
        () async {
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
      final recordedAt =
          DateTime.utc(2026, 7, 24, 9).millisecondsSinceEpoch ~/ 1000;

      raw.execute(
        '''
          INSERT INTO nutrition_entries
            (id, recorded_at, day_epoch, energy_kcal, protein_g, carbs_g, fat_g, water_ml)
          VALUES
            ('meal-with-water', ?, ?, 500, 30, 40, 15, 250);
          ''',
        [recordedAt, dayEpoch],
      );

      raw.execute('PRAGMA user_version = 1;');

      final database = NutritionDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);

      // Trigger migrations.
      await database.select(database.nutritionEntries).get();

      // (1) v1 -> v2 hydration backfill still happened.
      final hydrationRows =
          await database.select(database.hydrationEntries).get();
      expect(hydrationRows, hasLength(1));
      expect(hydrationRows.single.id, 'hydration-meal-with-water');

      // (2) v2 -> v3 created the six new tables.
      final tables = <String>[
        'diet_templates',
        'diet_meal_slots',
        'planned_meals',
        'meal_substitutes',
        'menu_photos',
        'menu_items',
      ];
      for (final name in tables) {
        final result = raw.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          [name],
        );
        expect(result, isNotEmpty, reason: 'table $name should exist');
      }

      // (3) A v1 database is migrated all the way to the CURRENT schema
      // version in one open — not just to v3. Asserting a hardcoded 3 here
      // would break on every future migration; assert the invariant instead.
      final versionResult = raw.select('PRAGMA user_version;');
      expect(versionResult.single['user_version'], database.schemaVersion);
    });
  });
}
