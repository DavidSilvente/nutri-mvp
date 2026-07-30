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

/// Local storage table for reusable diet templates.
///
/// Each template stores an explicit daily macro target and is uniquely
/// named. The per-user uniqueness expected by the domain is enforced in the
/// application layer; the schema guarantees global name uniqueness.
@DataClassName('DietTemplateRow')
class DietTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();

  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local storage table for the ordered meal slots inside a [DietTemplate].
@DataClassName('DietMealSlotRow')
class DietMealSlots extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text().references(
        DietTemplates,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get label => text()();
  IntColumn get position => integer()();

  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {templateId, position},
  ];
}

/// Local storage table for planned assignments of a meal slot to a day.
///
/// [dayEpoch] is nullable because a planned meal may exist without a fixed
/// calendar day. The unique constraint on `(slotId, dayEpoch)` allows multiple
/// rows with a NULL day as required by SQLite semantics.
@DataClassName('PlannedMealRow')
class PlannedMeals extends Table {
  TextColumn get id => text()();
  TextColumn get slotId => text().references(
        DietMealSlots,
        #id,
        onDelete: KeyAction.cascade,
      )();
  IntColumn get dayEpoch => integer().nullable()();

  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {slotId, dayEpoch},
  ];
}

/// Local storage table for substitutes scoped to a single planned meal.
@DataClassName('MealSubstituteRow')
class MealSubstitutes extends Table {
  TextColumn get id => text()();
  TextColumn get plannedMealId => text().references(
        PlannedMeals,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get label => text()();

  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local storage table for captured menu photo references.
///
/// The actual image bytes live in app-owned local storage; this table only
/// persists the durable reference and creation timestamp.
@DataClassName('MenuPhotoRow')
class MenuPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get localUri => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local storage table for manually-entered menu items scoped to a photo.
@DataClassName('MenuItemRow')
class MenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get photoId => text().references(
        MenuPhotos,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get label => text()();

  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift database for the nutrition feature.
///
/// Production usage opens a file on disk (via `driftDatabase(name: ...)`);
/// tests open `NativeDatabase.memory()` — both share this same schema.
///
/// One physical database file, eight tables (legacy [NutritionEntries] and
/// [HydrationEntries] plus the diet/menu tables introduced in v3).
@DriftDatabase(tables: [
  NutritionEntries,
  HydrationEntries,
  DietTemplates,
  DietMealSlots,
  PlannedMeals,
  MealSubstitutes,
  MenuPhotos,
  MenuItems,
])
class NutritionDatabase extends _$NutritionDatabase {
  NutritionDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      await transaction(() async {
        if (from < 2) {
          // v1 -> v2: hydration becomes its own table. Preserve any
          // previously-recorded water as a standalone `HydrationEntry`
          // (prefixed id to avoid colliding with `NutritionEntries` ids),
          // then drop `waterMl` from `NutritionEntries` entirely. All three
          // steps run as a single atomic unit.
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
        }
        if (from < 3) {
          // v2 -> v3: create the six diet/menu tables. No backfill is
          // required; these aggregates start empty.
          await m.createTable(dietTemplates);
          await m.createTable(dietMealSlots);
          await m.createTable(plannedMeals);
          await m.createTable(mealSubstitutes);
          await m.createTable(menuPhotos);
          await m.createTable(menuItems);
        }
      });
    },
    beforeOpen: (details) async {
      // SQLite disables foreign-key enforcement by default. The v3 schema
      // relies on cascading deletes, so the pragma must be active for every
      // connection before any write transaction runs.
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );
}
