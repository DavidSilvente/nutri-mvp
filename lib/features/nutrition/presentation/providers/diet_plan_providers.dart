import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/diet_plan_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart'
    show nutritionDatabaseProvider;

/// Resolves the [DietPlanSource] port. In production this is
/// [SqlDietPlanSource] over the same on-disk [nutritionDatabaseProvider] used by
/// nutrition and hydration. Tests override this provider with
/// `FakeDietPlanSource` to avoid touching drift entirely.
final dietPlanSourceProvider = Provider<DietPlanSource>((ref) {
  return SqlDietPlanSource(ref.watch(nutritionDatabaseProvider));
});

/// Orchestrates diet templates and planned meals for the planning UI.
final dietPlanControllerProvider =
    AsyncNotifierProvider<DietPlanController, DietPlanState>(
      DietPlanController.new,
    );
