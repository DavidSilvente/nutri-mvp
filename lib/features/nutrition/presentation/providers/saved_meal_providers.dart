import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_saved_meal_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/saved_meal_source.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/saved_meal_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart'
    show clockProvider;
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart'
    show nutritionDatabaseProvider;

/// Resolves the [SavedMealSource] port. In production this is
/// [SqlSavedMealSource] over the same on-disk [nutritionDatabaseProvider] used
/// by nutrition, hydration, and diet plans. Tests override this provider with
/// `FakeSavedMealSource` to avoid touching drift entirely.
final savedMealSourceProvider = Provider<SavedMealSource>((ref) {
  return SqlSavedMealSource(ref.watch(nutritionDatabaseProvider));
});

/// Ids for newly created saved meals.
///
/// A seam rather than a call to the clock inside the controller or the
/// screen, mirroring [planIdFactoryProvider].
final savedMealIdFactoryProvider = Provider<String Function()>((ref) {
  final now = ref.watch(clockProvider);
  return () => 'saved-${now().microsecondsSinceEpoch}';
});

/// Orchestrates the saved-meal catalogue for the UI: the list of meals as an
/// [AsyncValue], plus mutation methods (`saveMeal`, `deleteSavedMeal`).
final savedMealControllerProvider =
    AsyncNotifierProvider<SavedMealController, List<SavedMeal>>(
  SavedMealController.new,
);
