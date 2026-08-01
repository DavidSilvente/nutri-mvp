import 'package:nutri_mvp/core/result.dart';

import '../entities/diet_template.dart';
import '../entities/planned_meal.dart';
import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_source.dart';
import '../value_objects/nutrition_day.dart';

/// Assigns every meal slot of a template to each of the given days.
///
/// This is what turns a template ("my typical day") into an actual plan on
/// the calendar. Without it, filling a month means assigning slots one by one,
/// which nobody would do twice.
///
/// The generated planned-meal ids are DETERMINISTIC — `pm-{slotId}-{epochDay}`
/// — which makes the whole operation idempotent: applying the same template to
/// the same days twice overwrites the same rows instead of stacking duplicates
/// or tripping the `(slot, day)` uniqueness rule.
class ApplyTemplateToDays {
  ApplyTemplateToDays(this._source);

  final DietPlanSource _source;

  /// Builds the id used for a slot on a day. Exposed so callers (and tests)
  /// can reason about the same identity the use case writes.
  static String plannedMealId(String slotId, NutritionDay day) =>
      'pm-$slotId-${day.epochDay}';

  /// Returns how many planned meals were written.
  ///
  /// Stops at the FIRST failure and returns it: a half-applied plan is easier
  /// to reason about when the caller knows exactly where it stopped, and the
  /// deterministic ids make a retry safe.
  Future<Result<int, NutritionFailure>> call({
    required DietTemplate template,
    required List<NutritionDay> days,
  }) async {
    var written = 0;

    for (final day in days) {
      for (final slot in template.slots) {
        final result = await _source.savePlannedMeal(
          PlannedMeal(
            id: plannedMealId(slot.id, day),
            slotId: slot.id,
            day: day,
            // Frozen at assignment time: editing the template later must not
            // silently rewrite what a past day was judged against.
            targetSnapshot: slot.target,
          ),
        );
        if (result case Err(failure: final failure)) return Err(failure);
        written++;
      }
    }

    return Ok(written);
  }

  /// Removes every planned meal this use case would have created for [days].
  ///
  /// Intake already logged against those meals survives — the storage layer
  /// nulls the link rather than cascading the delete.
  Future<Result<int, NutritionFailure>> clear({
    required DietTemplate template,
    required List<NutritionDay> days,
  }) async {
    var removed = 0;

    for (final day in days) {
      for (final slot in template.slots) {
        final result = await _source.deletePlannedMeal(
          plannedMealId(slot.id, day),
        );
        if (result case Err(failure: final failure)) return Err(failure);
        removed++;
      }
    }

    return Ok(removed);
  }
}
