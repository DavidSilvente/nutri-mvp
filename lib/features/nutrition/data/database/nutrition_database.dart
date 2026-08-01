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
  DietPlanRecords,
  ComponentSelections,
])
class NutritionDatabase extends _$NutritionDatabase {
  NutritionDatabase(super.e);

  @override
  int get schemaVersion => 5;

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
          // v2 -> v3: create the six diet/menu tables. No backfill is
          // required; these aggregates start empty.
          await m.createTable(dietTemplates);
          await m.createTable(dietMealSlots);
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
}
