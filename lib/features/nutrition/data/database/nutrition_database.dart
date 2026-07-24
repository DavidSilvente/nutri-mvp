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
  RealColumn get waterMl => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift database for the nutrition feature.
///
/// Production usage opens a file on disk (via `driftDatabase(name: ...)`);
/// tests open `NativeDatabase.memory()` — both share this same schema.
@DriftDatabase(tables: [NutritionEntries])
class NutritionDatabase extends _$NutritionDatabase {
  NutritionDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
