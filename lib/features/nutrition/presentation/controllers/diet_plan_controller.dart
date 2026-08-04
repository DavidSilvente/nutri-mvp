import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/apply_diet_to_days.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/data_revision_provider.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Writes to the calendar side of the diet: planned meals and their
/// substitutes.
///
/// Holds no data of its own. What a day or a month looks like is read through
/// `dayPlanProvider` and `monthAdherenceProvider`, which re-run off
/// [dataRevisionProvider]; this notifier exists to perform the writes, bump that
/// revision, and give the caller one place to look for a failure.
///
/// Keeping it stateless is deliberate: the only thing it could cache is "every
/// planned meal ever", which grows without bound and which nothing reads.
class DietPlanController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Persists [meal] as a planned assignment to a day.
  Future<void> assignMealToDay(PlannedMeal meal) async {
    final result =
        await ref.read(dietPlanSourceProvider).savePlannedMeal(meal);
    await _commit(result);
  }

  /// Assigns the meals [plan] prescribes to each day in [days].
  ///
  /// Idempotent, and weekday-aware — see [ApplyDietToDays].
  Future<ApplyDietOutcome?> applyDiet({
    required DietPlan plan,
    required List<NutritionDay> days,
  }) async {
    final result = await ref.read(applyDietProvider)(
      plan: plan,
      days: days,
    );
    await _commit(result);
    return switch (result) {
      Ok(value: final outcome) => outcome,
      Err() => null,
    };
  }

  /// Removes the meals [plan] put on [days]. Logged intake survives.
  Future<void> clearPlan({
    required DietPlan plan,
    required List<NutritionDay> days,
  }) async {
    final result = await ref.read(applyDietProvider).clear(
      plan: plan,
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
        state = const AsyncValue.data(null);
      case Err(failure: final failure):
        state = AsyncValue.error(
          HealthFailureException(failure),
          StackTrace.current,
        );
    }
  }
}
