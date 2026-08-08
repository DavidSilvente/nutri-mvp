import 'package:nutri_mvp/core/result.dart';

import '../entities/stored_diet_plan.dart';
import '../failures/nutrition_failure.dart';
import '../value_objects/nutrition_day.dart';

/// Domain port for storing imported diet plans, the choice of which one is
/// active, and the per-day alternative selections made against them.
///
/// Implementations MUST guarantee that at most one stored plan has
/// `isDefault == true`, and that promoting a plan demotes the previous one in
/// the same atomic unit. A moment with two active diets would make the day view
/// non-deterministic.
abstract interface class DietPlanStore {
  /// Every stored plan, active one first, then by import recency (newest
  /// first), so the list reads the way a user expects.
  Future<Result<List<StoredDietPlan>, NutritionFailure>> listPlans();

  /// The user's current diet, or null when nothing has been imported yet.
  Future<Result<StoredDietPlan?, NutritionFailure>> activePlan();

  /// Persists [plan]. Returns [ConflictFailure] when another plan already uses
  /// the same name.
  ///
  /// Saving a plan with `isDefault == true` demotes any previously active plan.
  /// The FIRST plan ever stored becomes active regardless, because a library of
  /// one diet with none selected would leave the app with nothing to show.
  Future<Result<StoredDietPlan, NutritionFailure>> savePlan(
    StoredDietPlan plan,
  );

  /// Makes the plan identified by [id] the active one, demoting the previous.
  ///
  /// Returns [StorageFailure] when no such plan exists — silently doing nothing
  /// would leave the user looking at the diet they just tried to leave.
  Future<Result<void, NutritionFailure>> setActivePlan(String id);

  /// Deletes the plan identified by [id].
  ///
  /// When the deleted plan was active, the most recently imported remaining
  /// plan is promoted, so the app is never left with plans but no active one.
  Future<Result<void, NutritionFailure>> deletePlan(String id);

  /// The alternative choices recorded for [day], as component id -> option id.
  ///
  /// Components absent from the map follow the plan's default option; only
  /// deviations are stored.
  Future<Result<Map<String, String>, NutritionFailure>> selectionsFor(
    NutritionDay day,
  );

  /// Records that on [day] the user picked [optionId] for [componentId],
  /// replacing any previous choice for that component.
  Future<Result<void, NutritionFailure>> selectOption({
    required NutritionDay day,
    required String componentId,
    required String optionId,
  });

  /// Drops the recorded choice for [componentId] on [day], reverting to the
  /// plan's default option. A no-op when nothing was recorded.
  Future<Result<void, NutritionFailure>> clearSelection({
    required NutritionDay day,
    required String componentId,
  });

  /// The user's standing preferences, as component id -> option id.
  ///
  /// Independent of [selectionsFor]: a preference is a default for every day
  /// that carries no day-scoped selection of its own, and a day selection
  /// always outranks it. Components absent from the map follow the plan's
  /// default option; only deviations from that default are stored.
  Future<Result<Map<String, String>, NutritionFailure>> preferredOptions();

  /// Records that the user prefers [optionId] for [componentId] on every day
  /// that carries no day-scoped selection, replacing any previous preference
  /// for that component.
  Future<Result<void, NutritionFailure>> setPreferredOption({
    required String componentId,
    required String optionId,
  });

  /// Drops the recorded preference for [componentId], reverting resolution to
  /// the plan's default option (or a day-scoped selection, if one exists). A
  /// no-op when nothing was recorded.
  Future<Result<void, NutritionFailure>> clearPreferredOption(
    String componentId,
  );
}
