import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// Production [DietPlanStore] adapter backed by local `drift` (SQLite) storage.
///
/// `drift` types stay CONFINED to this file and [NutritionDatabase]; nothing
/// here leaks into the domain. This adapter NEVER produces [PermissionDenied],
/// which is exclusive to platform-backed sources.
class SqlDietPlanStore implements DietPlanStore {
  SqlDietPlanStore(this._db);

  final NutritionDatabase _db;

  @override
  Future<Result<List<StoredDietPlan>, NutritionFailure>> listPlans() async {
    try {
      final query = _db.select(_db.dietPlanRecords)
        ..orderBy([
          // Active first, then newest import. Descending on isDefault puts
          // true (1) ahead of false (0).
          (row) => OrderingTerm.desc(row.isDefault),
          (row) => OrderingTerm.desc(row.importedAt),
        ]);
      final rows = await query.get();
      return Ok(rows.map(_toPlan).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<StoredDietPlan?, NutritionFailure>> activePlan() async {
    try {
      final row = await (_db.select(_db.dietPlanRecords)
            ..where((row) => row.isDefault.equals(true))
            ..limit(1))
          .getSingleOrNull();
      return Ok(row == null ? null : _toPlan(row));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<StoredDietPlan, NutritionFailure>> savePlan(
    StoredDietPlan plan,
  ) async {
    try {
      return await _db.transaction<Result<StoredDietPlan, NutritionFailure>>(
        () async {
          final clash = await (_db.select(_db.dietPlanRecords)
                ..where((row) => row.name.equals(plan.name)))
              .getSingleOrNull();
          if (clash != null && clash.id != plan.id) {
            return Err(
              ConflictFailure('Diet plan name "${plan.name}" already exists'),
            );
          }

          // The first plan ever stored becomes active: a library holding one
          // diet with none selected would leave the day view with nothing to
          // read, which is never what the user meant by importing it.
          final total = await _countPlans();
          final existing = await (_db.select(_db.dietPlanRecords)
                ..where((row) => row.id.equals(plan.id)))
              .getSingleOrNull();
          final isFirstPlan = total == 0 || (total == 1 && existing != null);
          final shouldBeActive = plan.isDefault || isFirstPlan;

          if (shouldBeActive) {
            await _demoteAllExcept(plan.id);
          }

          final companion = DietPlanRecordsCompanion.insert(
            id: plan.id,
            name: plan.name,
            document: plan.document,
            declaredDailyEnergyKcal: Value(
              plan.declaredDailyEnergyKcal?.toDouble(),
            ),
            isDefault: Value(shouldBeActive),
            sourceLabel: Value(plan.sourceLabel),
            importedAt: plan.importedAt,
          );
          if (existing == null) {
            await _db.into(_db.dietPlanRecords).insert(companion);
          } else {
            await (_db.update(_db.dietPlanRecords)
                  ..where((row) => row.id.equals(plan.id)))
                .write(companion);
          }

          return Ok(plan.copyWith(isDefault: shouldBeActive));
        },
      );
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> setActivePlan(String id) async {
    try {
      return await _db.transaction<Result<void, NutritionFailure>>(() async {
        final target = await (_db.select(_db.dietPlanRecords)
              ..where((row) => row.id.equals(id)))
            .getSingleOrNull();
        if (target == null) {
          return Err(StorageFailure('No diet plan with id "$id"'));
        }
        await _demoteAllExcept(id);
        await (_db.update(_db.dietPlanRecords)
              ..where((row) => row.id.equals(id)))
            .write(const DietPlanRecordsCompanion(isDefault: Value(true)));
        return const Ok(null);
      });
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> deletePlan(String id) async {
    try {
      return await _db.transaction<Result<void, NutritionFailure>>(() async {
        final target = await (_db.select(_db.dietPlanRecords)
              ..where((row) => row.id.equals(id)))
            .getSingleOrNull();
        if (target == null) return const Ok(null);

        await (_db.delete(_db.dietPlanRecords)
              ..where((row) => row.id.equals(id)))
            .go();

        // Deleting the active diet must not leave the app with plans but no
        // active one, so the most recent survivor is promoted.
        if (target.isDefault) {
          final successor = await (_db.select(_db.dietPlanRecords)
                ..orderBy([(row) => OrderingTerm.desc(row.importedAt)])
                ..limit(1))
              .getSingleOrNull();
          if (successor != null) {
            await (_db.update(_db.dietPlanRecords)
                  ..where((row) => row.id.equals(successor.id)))
                .write(const DietPlanRecordsCompanion(isDefault: Value(true)));
          }
        }
        return const Ok(null);
      });
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, String>, NutritionFailure>> selectionsFor(
    NutritionDay day,
  ) async {
    try {
      final rows = await (_db.select(_db.componentSelections)
            ..where((row) => row.dayEpoch.equals(day.epochDay)))
          .get();
      return Ok({
        for (final row in rows) row.componentId: row.optionId,
      });
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> selectOption({
    required NutritionDay day,
    required String componentId,
    required String optionId,
  }) async {
    try {
      // (dayEpoch, componentId) is the primary key, so an upsert replaces any
      // previous choice for that component on that day.
      await _db.into(_db.componentSelections).insertOnConflictUpdate(
        ComponentSelectionsCompanion.insert(
          dayEpoch: day.epochDay,
          componentId: componentId,
          optionId: optionId,
        ),
      );
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> clearSelection({
    required NutritionDay day,
    required String componentId,
  }) async {
    try {
      await (_db.delete(_db.componentSelections)
            ..where((row) =>
                row.dayEpoch.equals(day.epochDay) &
                row.componentId.equals(componentId)))
          .go();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  Future<int> _countPlans() async {
    final count = _db.dietPlanRecords.id.count();
    final row = await (_db.selectOnly(_db.dietPlanRecords)
          ..addColumns([count]))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> _demoteAllExcept(String id) async {
    await (_db.update(_db.dietPlanRecords)
          ..where((row) => row.isDefault.equals(true) & row.id.equals(id).not()))
        .write(const DietPlanRecordsCompanion(isDefault: Value(false)));
  }

  static StoredDietPlan _toPlan(DietPlanRow row) => StoredDietPlan(
    id: row.id,
    name: row.name,
    document: row.document,
    importedAt: row.importedAt,
    declaredDailyEnergyKcal: row.declaredDailyEnergyKcal,
    isDefault: row.isDefault,
    sourceLabel: row.sourceLabel,
  );
}
