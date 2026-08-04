import 'package:drift/drift.dart';

import 'legacy_template_migration.dart';

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

  /// Optional link to the [PlannedMeals] row this intake was logged against.
  ///
  /// Nullable because unplanned intake must still be recordable. The delete
  /// action is `setNull`, NOT `cascade`: un-planning a meal must never erase
  /// the historical fact that food was eaten — the entry survives and simply
  /// stops counting towards adherence.
  TextColumn get plannedMealId => text().nullable().references(
        PlannedMeals,
        #id,
        onDelete: KeyAction.setNull,
      )();

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

/// Local storage table for planned assignments of a meal slot to a day.
///
/// [dayEpoch] is nullable because a planned meal may exist without a fixed
/// calendar day. The unique constraint on `(slotId, dayEpoch)` allows multiple
/// rows with a NULL day as required by SQLite semantics.
///
/// [slotId] is a PLAIN reference, not a foreign key. Until v7 it cascaded from a
/// `diet_meal_slots` table; a diet now lives in one place, as a document in
/// [DietPlanRecords], and the slot it names is resolved by decoding that
/// document. Keeping the column unconstrained is what lets this table stay the
/// immutable ledger of what a day was committed to: deleting or editing a diet
/// must never erase the record of what a past day was judged against.
@DataClassName('PlannedMealRow')
class PlannedMeals extends Table {
  TextColumn get id => text()();
  TextColumn get slotId => text()();
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

/// An imported diet plan, stored as its normalized document.
///
/// The plan itself is IMMUTABLE once imported, so it is persisted verbatim as
/// the normalized JSON document rather than exploded across tables for meals,
/// components and options. Two reasons:
///
/// * re-importing the same source reproduces the same document, and because
///   component ids are positional, the user's saved alternative choices keep
///   resolving;
/// * the mutable state (which plan is active, which alternative was picked on a
///   given day) is small and lives in its own tables, so nothing needs to be
///   migrated when the plan document schema grows a field.
///
/// [isDefault] marks the user's current diet. Exactly one row may carry it; the
/// data source enforces that transactionally, since SQLite partial unique
/// indexes are not expressible through drift's table DSL.
@DataClassName('DietPlanRow')
class DietPlanRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();

  /// The normalized plan JSON, as decoded by `DietPlanCodec`.
  TextColumn get document => text()();

  /// Headline daily energy the source plan advertised, for display only.
  RealColumn get declaredDailyEnergyKcal => real().nullable()();

  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();

  /// Where the plan came from, e.g. the imported file name.
  TextColumn get sourceLabel => text().nullable()();

  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local storage table for the user's saved-meal catalogue.
///
/// Independent of [MenuItems] and [MealSubstitutes] — a saved meal is not
/// scoped to any plan or planned meal. Uniqueness on the trimmed,
/// case-folded name is enforced in the application layer (see
/// `SqlSavedMealSource`), not through a schema constraint: SQLite `UNIQUE`
/// collations do not express trimming, and `NOCASE` folds ASCII only.
@DataClassName('SavedMealRow')
class SavedMeals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get portionNote => text().nullable()();

  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Which alternative the user picked for a meal component on a given day.
///
/// Absence is meaningful: a component with no row falls back to the plan's
/// default option. Only DEVIATIONS from the dietitian's first choice are stored,
/// so a normal day writes nothing at all.
///
/// Not foreign-keyed to a plan row on purpose: a selection is keyed by the
/// positional component id, which survives a re-import of the same plan.
@DataClassName('ComponentSelectionRow')
class ComponentSelections extends Table {
  /// Day the choice applies to, as a `NutritionDay` epoch day.
  IntColumn get dayEpoch => integer()();

  /// The `MealComponent.id` being decided.
  TextColumn get componentId => text()();

  /// The chosen `ComponentOption.id`.
  TextColumn get optionId => text()();

  @override
  Set<Column> get primaryKey => {dayEpoch, componentId};
}

/// Drift database for the nutrition feature.
///
/// Production usage opens a file on disk (via `driftDatabase(name: ...)`);
/// tests open `NativeDatabase.memory()` — both share this same schema.
///
/// One physical database file (legacy [NutritionEntries] and
/// [HydrationEntries], the diet/menu tables introduced in v3, and the
/// saved-meal catalogue introduced in v6).
@DriftDatabase(tables: [
  NutritionEntries,
  HydrationEntries,
  PlannedMeals,
  MealSubstitutes,
  MenuPhotos,
  MenuItems,
  DietPlanRecords,
  ComponentSelections,
  SavedMeals,
])
class NutritionDatabase extends _$NutritionDatabase {
  NutritionDatabase(super.e);

  @override
  int get schemaVersion => 7;

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
          //
          // `newColumns` lists every column added to the Dart definition
          // AFTER v2. Without it, the recreate would try to copy those
          // columns out of the v1 table, which does not have them, and the
          // whole v1 -> v4 path would fail with "no such column". Anything
          // added to this table in a future version MUST be listed here too.
          await m.alterTable(
            TableMigration(
              nutritionEntries,
              newColumns: [nutritionEntries.plannedMealId],
            ),
          );
        }
        if (from < 3) {
          // v2 -> v3: create the diet/menu tables. No backfill is required;
          // these aggregates start empty.
          //
          // The original step also created `diet_templates` and
          // `diet_meal_slots`. It no longer does: v7 below drops them, and
          // creating a pair of tables here only to delete them two steps later
          // would leave dead DDL that has to be maintained forever. A database
          // that really was at v3 still HAS them, which is why v7 checks
          // instead of assuming.
          await m.createTable(plannedMeals);
          await m.createTable(mealSubstitutes);
          await m.createTable(menuPhotos);
          await m.createTable(menuItems);
        }
        if (from < 4) {
          // v3 -> v4: link intake to the planned meal it fulfils, so
          // adherence can be computed. Existing rows keep NULL — historical
          // intake was logged before planning existed and is not retroactively
          // attributable to any meal.
          //
          // Guarded because the v1 -> v2 step above already recreates
          // `nutrition_entries` from the current Dart definition, so a
          // database coming all the way from v1 arrives here with the column
          // already present; an unconditional ADD COLUMN would abort with
          // "duplicate column name".
          if (!await _hasColumn('nutrition_entries', 'planned_meal_id')) {
            await m.addColumn(nutritionEntries, nutritionEntries.plannedMealId);
          }
        }
        if (from < 5) {
          // v4 -> v5: imported diet plans and the per-day alternative choices
          // made against them. Both start empty; nothing to backfill, and no
          // existing table is touched, so a database at any earlier version
          // reaches v5 by creating these two.
          await m.createTable(dietPlanRecords);
          await m.createTable(componentSelections);
        }
        if (from < 6) {
          // v5 -> v6: the user's own meal catalogue. Purely additive; starts
          // empty.
          await m.createTable(savedMeals);
        }
        if (from < 7) {
          // v6 -> v7: a diet lives in ONE place. The hand-built templates of v3
          // were a second, parallel store for the same idea, and the day and
          // calendar views read only that one while imported plans sat unused.
          //
          // Order matters. The templates are rewritten as plan documents FIRST,
          // while their tables are still there to be read; only then does the
          // schema lose them.
          if (await _hasTable('diet_templates')) {
            await LegacyTemplateMigration.run(this);
          }

          // `planned_meals.slot_id` used to cascade from `diet_meal_slots`.
          // Recreated from the current definition, which has no such key, so
          // that dropping that table cannot take the calendar with it. This is
          // the whole reason the step cannot be a plain DROP.
          await m.alterTable(TableMigration(plannedMeals));

          await customStatement('DROP TABLE IF EXISTS diet_meal_slots;');
          await customStatement('DROP TABLE IF EXISTS diet_templates;');
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

  /// Whether [column] already exists on [table], read straight from SQLite.
  ///
  /// Migration steps cannot assume the shape of the table they receive: an
  /// earlier step may have recreated it from the current Dart definition.
  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect("PRAGMA table_info('$table');").get();
    return rows.any((row) => row.read<String>('name') == column);
  }

  /// Whether [table] exists at all.
  ///
  /// Needed because a table can be absent for two different reasons: the
  /// database predates it, or a later step already dropped it. A step that
  /// tidies up after an earlier schema has to tell those apart rather than
  /// failing on "no such table".
  Future<bool> _hasTable(String table) async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?;",
      variables: [Variable<String>(table)],
    ).get();
    return rows.isNotEmpty;
  }
}
