import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// In-memory [DietPlanSource] test double.
///
/// Mirrors the contract the real SQL adapter MUST honor: templates enforce
/// unique names, planned meals enforce unique (slot, day) assignments, and
/// deletes remove dependent substitutes. This fake NEVER produces
/// [PermissionDenied]: that failure is exclusive to platform-backed sources.
class FakeDietPlanSource implements DietPlanSource {
  final Map<String, DietTemplate> _templates = {};
  final Map<String, PlannedMeal> _plannedMeals = {};
  final Map<String, MealSubstitute> _substitutes = {};

  @override
  Future<Result<List<DietTemplate>, NutritionFailure>> listTemplates() async {
    final values = _templates.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    return Ok(values);
  }

  @override
  Future<Result<DietTemplate, NutritionFailure>> saveTemplate(
    DietTemplate template,
  ) async {
    final duplicate = _templates.values
        .where((t) => t.name == template.name && t.id != template.id)
        .isNotEmpty;
    if (duplicate) {
      return Err(
        ConflictFailure('Template name "${template.name}" already exists'),
      );
    }

    // Mirror the SQL cascade: removing a slot drops its planned meals and
    // their substitutes. Unchanged slot identities survive the edit.
    final previous = _templates[template.id];
    if (previous != null) {
      final keptSlotIds = template.slots.map((s) => s.id).toSet();
      final removedSlotIds = previous.slots
          .map((s) => s.id)
          .where((id) => !keptSlotIds.contains(id))
          .toList();
      if (removedSlotIds.isNotEmpty) {
        final removedMealIds = _plannedMeals.values
            .where((m) => removedSlotIds.contains(m.slotId))
            .map((m) => m.id)
            .toSet();
        _plannedMeals.removeWhere((_, m) => removedMealIds.contains(m.id));
        _substitutes.removeWhere((_, s) => removedMealIds.contains(s.plannedMealId));
      }
    }

    _templates[template.id] = template;
    return Ok(template);
  }

  @override
  Future<Result<void, NutritionFailure>> deleteTemplate(String id) async {
    _templates.remove(id);
    return const Ok(null);
  }

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> listPlannedMeals({
    String? templateId,
    NutritionDay? day,
  }) async {
    final slotIds = templateId == null
        ? null
        : _templates[templateId]?.slots.map((s) => s.id).toSet();

    final matches = _plannedMeals.values.where((meal) {
      if (slotIds != null && !slotIds.contains(meal.slotId)) return false;
      if (day != null && meal.day != day) return false;
      return true;
    }).toList(growable: false);

    return Ok(matches);
  }

  @override
  Future<Result<PlannedMeal, NutritionFailure>> savePlannedMeal(
    PlannedMeal meal,
  ) async {
    if (meal.day != null) {
      final duplicate = _plannedMeals.values.any(
        (m) =>
            m.id != meal.id &&
            m.slotId == meal.slotId &&
            m.day == meal.day,
      );
      if (duplicate) {
        return Err(
          ConflictFailure(
            'Slot ${meal.slotId} is already planned for ${meal.day}',
          ),
        );
      }
    }
    _plannedMeals[meal.id] = meal;
    return Ok(meal);
  }

  @override
  Future<Result<void, NutritionFailure>> deletePlannedMeal(String id) async {
    _plannedMeals.remove(id);
    _substitutes.removeWhere((_, sub) => sub.plannedMealId == id);
    return const Ok(null);
  }

  @override
  Future<Result<List<MealSubstitute>, NutritionFailure>> listSubstitutes(
    String plannedMealId,
  ) async {
    final matches = _substitutes.values
        .where((sub) => sub.plannedMealId == plannedMealId)
        .toList(growable: false);
    return Ok(matches);
  }

  @override
  Future<Result<MealSubstitute, NutritionFailure>> saveSubstitute(
    MealSubstitute substitute,
  ) async {
    _substitutes[substitute.id] = substitute;
    return Ok(substitute);
  }

  @override
  Future<Result<void, NutritionFailure>> deleteSubstitute(String id) async {
    _substitutes.remove(id);
    return const Ok(null);
  }
}
