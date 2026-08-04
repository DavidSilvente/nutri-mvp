import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../ports/meal_slot_directory.dart';
import '../usecases/resolve_active_diet.dart';
import 'meal_slot_index.dart';

/// Answers [MealSlotDirectory] from the user's active diet.
///
/// The one adapter between "what are my meals called" and the full resolve of
/// the active plan, so the day and month use cases never touch the store, the
/// food table or the codec themselves.
class ActiveDietSlotDirectory implements MealSlotDirectory {
  ActiveDietSlotDirectory(this._activeDiet);

  final ResolveActiveDiet _activeDiet;

  @override
  Future<Result<MealSlotIndex, NutritionFailure>> activeSlots() async {
    final resolved = await _activeDiet();
    return switch (resolved) {
      Err(failure: final failure) => Err(failure),
      // Every day group is indexed, not just today's: a month of planned meals
      // spans all of them.
      Ok(value: final diet) => Ok(
        diet == null
            ? MealSlotIndex.empty()
            : MealSlotIndex.fromPlan(diet.plan, diet.catalog),
      ),
    };
  }
}
