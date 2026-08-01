import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/apply_template_to_days.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/data_revision_provider.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// The aggregated async state exposed by [DietPlanController].
///
/// It deliberately groups templates and planned meals together because the
/// planning UI needs both: the template list drives creation/editing, and
/// planned meals are required to show assignments and to validate uniqueness
/// constraints in the presentation layer.
class DietPlanState {
  const DietPlanState({
    required this.templates,
    required this.plannedMeals,
  });

  final List<DietTemplate> templates;
  final List<PlannedMeal> plannedMeals;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DietPlanState) return false;
    if (other.templates.length != templates.length) return false;
    if (other.plannedMeals.length != plannedMeals.length) return false;
    for (var i = 0; i < templates.length; i++) {
      if (other.templates[i] != templates[i]) return false;
    }
    for (var i = 0; i < plannedMeals.length; i++) {
      if (other.plannedMeals[i] != plannedMeals[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(templates),
        Object.hashAll(plannedMeals),
      );

  @override
  String toString() =>
      'DietPlanState(templates: $templates, plannedMeals: $plannedMeals)';
}

/// Orchestrates diet plan operations for the UI.
///
/// Wraps a [DietPlanSource] directly (no intermediate use case) because the
/// source already encapsulates the persistence contract. The controller
/// exposes templates and planned meals as an [AsyncValue] and provides
/// mutation methods that refresh the aggregate state on success and surface
/// failures as [AsyncError] via [HealthFailureException].
class DietPlanController extends AsyncNotifier<DietPlanState> {
  @override
  FutureOr<DietPlanState> build() => _load();

  /// Persists [template]. On success the aggregate state is refreshed; on
  /// failure the state becomes an [AsyncError] wrapping a
  /// [HealthFailureException].
  Future<void> saveTemplate(DietTemplate template) async {
    final result = await ref.read(dietPlanSourceProvider).saveTemplate(template);
    await _commit(result);
  }

  /// Persists [meal] as a planned assignment to a day. Refreshes the
  /// aggregate state on success; surfaces failures as [AsyncError].
  Future<void> assignMealToDay(PlannedMeal meal) async {
    final result =
        await ref.read(dietPlanSourceProvider).savePlannedMeal(meal);
    await _commit(result);
  }

  /// Assigns every meal of [template] to each day in [days].
  ///
  /// Idempotent, so re-applying a diet over days that already have it is
  /// harmless — see [ApplyTemplateToDays].
  Future<void> applyTemplate({
    required DietTemplate template,
    required List<NutritionDay> days,
  }) async {
    final result = await ref.read(applyTemplateProvider)(
      template: template,
      days: days,
    );
    await _commit(result);
  }

  /// Removes the meals [template] put on [days]. Logged intake survives.
  Future<void> clearPlan({
    required DietTemplate template,
    required List<NutritionDay> days,
  }) async {
    final result = await ref.read(applyTemplateProvider).clear(
      template: template,
      days: days,
    );
    await _commit(result);
  }

  /// Removes a planned assignment. Any intake already logged against it
  /// survives — the storage layer nulls the link rather than cascading.
  Future<void> deletePlannedMeal(String id) async {
    final result = await ref.read(dietPlanSourceProvider).deletePlannedMeal(id);
    await _commit(result);
  }

  /// Persists an alternative for a planned meal, for days when the planned
  /// option does not appeal.
  Future<void> saveSubstitute(MealSubstitute substitute) async {
    final result = await ref
        .read(dietPlanSourceProvider)
        .saveSubstitute(substitute);
    await _commit(result);
  }

  Future<void> deleteSubstitute(String id) async {
    final result = await ref.read(dietPlanSourceProvider).deleteSubstitute(id);
    await _commit(result);
  }

  Future<void> _commit<T>(Result<T, NutritionFailure> result) async {
    switch (result) {
      case Ok():
        bumpDataRevision(ref);
        state = await AsyncValue.guard(_load);
      case Err(failure: final failure):
        state = AsyncValue.error(
          HealthFailureException(failure),
          StackTrace.current,
        );
    }
  }

  Future<DietPlanState> _load() async {
    final source = ref.read(dietPlanSourceProvider);
    final templatesResult = await source.listTemplates();
    final plannedMealsResult = await source.listPlannedMeals();

    return switch ((templatesResult, plannedMealsResult)) {
      (Ok(value: final templates), Ok(value: final plannedMeals)) =>
        DietPlanState(
          templates: templates,
          plannedMeals: plannedMeals,
        ),
      (Err(failure: final failure), _) => throw HealthFailureException(failure),
      (_, Err(failure: final failure)) =>
        throw HealthFailureException(failure),
    };
  }
}
