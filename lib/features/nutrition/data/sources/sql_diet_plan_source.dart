import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// Production [DietPlanSource] adapter backed by local `drift` (SQLite)
/// storage. Templates, planned meals, and substitutes persist on disk and
/// survive app restarts.
///
/// `drift` types (rows, tables, the generated database class) are CONFINED
/// to this file and [NutritionDatabase] — nothing here leaks into the
/// domain. This adapter NEVER produces [PermissionDenied]: that failure is
/// exclusive to platform-backed sources.
class SqlDietPlanSource implements DietPlanSource {
  SqlDietPlanSource(this._db);

  final NutritionDatabase _db;

  @override
  Future<Result<List<DietTemplate>, NutritionFailure>> listTemplates() async {
    try {
      final templateQuery = _db.select(_db.dietTemplates)
        ..orderBy([(row) => OrderingTerm.asc(row.name)]);
      final templateRows = await templateQuery.get();
      final slotRows = await _db.select(_db.dietMealSlots).get();
      final slotsByTemplate = <String, List<DietMealSlotRow>>{};
      for (final slot in slotRows) {
        slotsByTemplate.putIfAbsent(slot.templateId, () => []).add(slot);
      }

      final templates = templateRows.map((row) {
        final slots = (slotsByTemplate[row.id] ?? [])
          ..sort((a, b) => a.position.compareTo(b.position));
        return _toTemplate(row, slots);
      }).toList(growable: false);

      return Ok(templates);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<DietTemplate, NutritionFailure>> saveTemplate(
    DietTemplate template,
  ) async {
    try {
      final result = await _db.transaction<Result<DietTemplate, NutritionFailure>>(
        () async {
          final existingByName = await (_db.select(_db.dietTemplates)
                ..where((row) => row.name.equals(template.name)))
              .getSingleOrNull();
          if (existingByName != null && existingByName.id != template.id) {
            return Err(
              ConflictFailure(
                'Template name "${template.name}" already exists',
              ),
            );
          }

          // Use UPDATE for an existing template id. INSERT OR REPLACE would
          // delete the old parent row first, which cascades to the slot rows
          // and destroys planned meals/substitutes.
          final existingById = await (_db.select(_db.dietTemplates)
                ..where((row) => row.id.equals(template.id)))
              .getSingleOrNull();
          final templateCompanion = _toTemplateCompanion(template);
          if (existingById != null) {
            await _db.update(_db.dietTemplates).replace(templateCompanion);
          } else {
            await _db.into(_db.dietTemplates).insert(templateCompanion);
          }

          // Update slots in-place so that unchanged slot identities keep their
          // primary keys and FK-backed planned meals/substitutes survive the
          // edit. Removed slots are intentionally deleted and cascade as
          // declared.
          final existingSlotIds = await (_db.select(_db.dietMealSlots)
                ..where((row) => row.templateId.equals(template.id)))
              .map((row) => row.id)
              .get();
          final newSlotIds = template.slots.map((s) => s.id).toSet();
          final removedSlotIds =
              existingSlotIds.where((id) => !newSlotIds.contains(id)).toList();
          if (removedSlotIds.isNotEmpty) {
            await (_db.delete(_db.dietMealSlots)
                  ..where((row) => row.id.isIn(removedSlotIds)))
                .go();
          }

          for (final slot in template.slots) {
            final companion = _toSlotCompanion(slot, template.id);
            if (existingSlotIds.contains(slot.id)) {
              await _db.update(_db.dietMealSlots).replace(companion);
            } else {
              await _db.into(_db.dietMealSlots).insert(companion);
            }
          }

          return Ok(template);
        },
      );
      return result;
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> deleteTemplate(String id) async {
    try {
      await (_db.delete(_db.dietTemplates)..where((row) => row.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> listPlannedMeals({
    String? templateId,
    NutritionDay? day,
  }) async {
    try {
      Set<String>? slotIds;
      if (templateId != null) {
        final rows = await (_db.select(_db.dietMealSlots)
              ..where((row) => row.templateId.equals(templateId)))
            .get();
        slotIds = rows.map((row) => row.id).toSet();
      }

      final query = _db.select(_db.plannedMeals);
      if (slotIds != null) {
        query.where((row) => row.slotId.isIn(slotIds?.toList() ?? []));
      }
      if (day != null) {
        query.where((row) => row.dayEpoch.equals(day.epochDay));
      }
      final rows = await query.get();

      return Ok(rows.map(_toPlannedMeal).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> plannedMealsBetween(
    NutritionDay from,
    NutritionDay to,
  ) async {
    if (from.epochDay > to.epochDay) return const Ok([]);
    try {
      // `isBetweenValues` on a nullable column already excludes NULL days,
      // which is the documented contract: unscheduled meals are not calendar
      // commitments.
      final query = _db.select(_db.plannedMeals)
        ..where(
          (row) =>
              row.dayEpoch.isBiggerOrEqualValue(from.epochDay) &
              row.dayEpoch.isSmallerOrEqualValue(to.epochDay),
        );
      final rows = await query.get();
      return Ok(rows.map(_toPlannedMeal).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<PlannedMeal, NutritionFailure>> savePlannedMeal(
    PlannedMeal meal,
  ) async {
    try {
      final result = await _db.transaction<Result<PlannedMeal, NutritionFailure>>(
        () async {
          if (meal.day != null) {
            final existing = await (_db.select(_db.plannedMeals)
                  ..where(
                    (row) =>
                        row.slotId.equals(meal.slotId) &
                        row.dayEpoch.equals(meal.day!.epochDay),
                  ))
                .getSingleOrNull();
            if (existing != null && existing.id != meal.id) {
              return Err(
                ConflictFailure(
                  'Slot ${meal.slotId} is already planned for ${meal.day}',
                ),
              );
            }
          }

          await _db
              .into(_db.plannedMeals)
              .insert(_toPlannedMealCompanion(meal), mode: InsertMode.insertOrReplace);

          return Ok(meal);
        },
      );
      return result;
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> deletePlannedMeal(String id) async {
    try {
      await (_db.delete(_db.plannedMeals)..where((row) => row.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<MealSubstitute>, NutritionFailure>> listSubstitutes(
    String plannedMealId,
  ) async {
    try {
      final rows = await (_db.select(_db.mealSubstitutes)
            ..where((row) => row.plannedMealId.equals(plannedMealId)))
          .get();
      return Ok(rows.map(_toSubstitute).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<MealSubstitute, NutritionFailure>> saveSubstitute(
    MealSubstitute substitute,
  ) async {
    try {
      await _db
          .into(_db.mealSubstitutes)
          .insert(_toSubstituteCompanion(substitute), mode: InsertMode.insertOrReplace);
      return Ok(substitute);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> deleteSubstitute(String id) async {
    try {
      await (_db.delete(_db.mealSubstitutes)..where((row) => row.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  DietTemplatesCompanion _toTemplateCompanion(DietTemplate template) {
    final now = DateTime.now();
    final target = _targetValues(template.dailyTarget);
    return DietTemplatesCompanion.insert(
      id: template.id,
      name: template.name,
      energyKcal: target.energyKcal,
      proteinG: target.proteinG,
      carbsG: target.carbsG,
      fatG: target.fatG,
      createdAt: now,
      updatedAt: now,
    );
  }

  DietMealSlotsCompanion _toSlotCompanion(DietMealSlot slot, String templateId) {
    final target = _targetValues(slot.target);
    return DietMealSlotsCompanion.insert(
      id: slot.id,
      templateId: templateId,
      label: slot.label,
      position: slot.position,
      energyKcal: target.energyKcal,
      proteinG: target.proteinG,
      carbsG: target.carbsG,
      fatG: target.fatG,
    );
  }

  DietTemplate _toTemplate(DietTemplateRow row, List<DietMealSlotRow> slotRows) {
    return DietTemplate(
      id: row.id,
      name: row.name,
      dailyTarget: _toTarget(
        energyKcal: row.energyKcal,
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
      ),
      slots: slotRows.map(_toSlot).toList(growable: false),
    );
  }

  DietMealSlot _toSlot(DietMealSlotRow row) {
    return DietMealSlot(
      id: row.id,
      label: row.label,
      position: row.position,
      target: _toTarget(
        energyKcal: row.energyKcal,
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
      ),
    );
  }

  PlannedMealsCompanion _toPlannedMealCompanion(PlannedMeal meal) {
    final target = _targetValues(meal.targetSnapshot);
    return PlannedMealsCompanion.insert(
      id: meal.id,
      slotId: meal.slotId,
      dayEpoch: Value(meal.day?.epochDay),
      energyKcal: target.energyKcal,
      proteinG: target.proteinG,
      carbsG: target.carbsG,
      fatG: target.fatG,
    );
  }

  PlannedMeal _toPlannedMeal(PlannedMealRow row) {
    return PlannedMeal(
      id: row.id,
      slotId: row.slotId,
      day: _toDay(row.dayEpoch),
      targetSnapshot: _toTarget(
        energyKcal: row.energyKcal,
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
      ),
    );
  }

  MealSubstitutesCompanion _toSubstituteCompanion(MealSubstitute substitute) {
    final target = _targetValues(substitute.target);
    return MealSubstitutesCompanion.insert(
      id: substitute.id,
      plannedMealId: substitute.plannedMealId,
      label: substitute.label,
      energyKcal: target.energyKcal,
      proteinG: target.proteinG,
      carbsG: target.carbsG,
      fatG: target.fatG,
    );
  }

  MealSubstitute _toSubstitute(MealSubstituteRow row) {
    return MealSubstitute(
      id: row.id,
      plannedMealId: row.plannedMealId,
      label: row.label,
      target: _toTarget(
        energyKcal: row.energyKcal,
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
      ),
    );
  }

  NutritionTarget _toTarget({
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) {
    return NutritionTarget(
      energy: Energy(kcal: energyKcal),
      macros: Macros(
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
      ),
    );
  }

  ({double energyKcal, double proteinG, double carbsG, double fatG})
      _targetValues(NutritionTarget target) {
    return (
      energyKcal: target.energy.kcal.toDouble(),
      proteinG: target.macros.proteinG.toDouble(),
      carbsG: target.macros.carbsG.toDouble(),
      fatG: target.macros.fatG.toDouble(),
    );
  }

  NutritionDay? _toDay(int? dayEpoch) {
    if (dayEpoch == null) return null;
    return NutritionDay.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(
        dayEpoch * Duration.millisecondsPerDay,
        isUtc: true,
      ),
    );
  }
}
