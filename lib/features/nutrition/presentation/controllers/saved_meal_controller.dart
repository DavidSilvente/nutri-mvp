import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/data_revision_provider.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';

/// Orchestrates the saved-meal catalogue for the UI.
///
/// Wraps [SavedMealSource] directly (no intermediate use case) because the
/// source already encapsulates the persistence contract — the same shape as
/// `DietPlanController`. The state IS the meal list, refreshed on a
/// successful write; a failing write (e.g. a duplicate name) surfaces as an
/// [AsyncError] wrapping a [HealthFailureException].
class SavedMealController extends AsyncNotifier<List<SavedMeal>> {
  @override
  FutureOr<List<SavedMeal>> build() => _load();

  /// Persists [meal]. On success the list is refreshed; on failure the
  /// state becomes an [AsyncError].
  Future<void> saveMeal(SavedMeal meal) async {
    final result = await ref.read(savedMealSourceProvider).saveMeal(meal);
    await _commit(result);
  }

  /// Removes the saved meal identified by [id]. A hard delete: any
  /// `NutritionEntry` previously logged from it is unaffected — see
  /// `SavedMealSource.deleteSavedMeal`.
  Future<void> deleteSavedMeal(String id) async {
    final result =
        await ref.read(savedMealSourceProvider).deleteSavedMeal(id);
    await _commit(result);
  }

  /// Copies [entry]'s energy and macros into a NEW [SavedMeal] named [name].
  ///
  /// [entry] is never mutated — a `NutritionEntry` is a historical fact, and
  /// the saved meal is an independent copy of it. Naming is mandatory
  /// because `NutritionEntry` carries no label of its own.
  Future<void> promoteEntry(
    NutritionEntry entry, {
    required String name,
    String? portionNote,
  }) async {
    final meal = SavedMeal(
      id: ref.read(savedMealIdFactoryProvider)(),
      name: name,
      target: NutritionTarget(energy: entry.energy, macros: entry.macros),
      portionNote: portionNote,
      createdAt: DateTime.now(),
    );
    final result = await ref.read(savedMealSourceProvider).saveMeal(meal);
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

  Future<List<SavedMeal>> _load() async {
    final result = await ref.read(savedMealSourceProvider).listSavedMeals();
    return switch (result) {
      Ok(value: final meals) => meals,
      Err(failure: final failure) => throw HealthFailureException(failure),
    };
  }
}
