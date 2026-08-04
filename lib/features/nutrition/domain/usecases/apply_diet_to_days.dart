import 'package:nutri_mvp/core/result.dart';

import '../entities/diet_plan.dart';
import '../entities/planned_meal.dart';
import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_source.dart';
import '../value_objects/nutrition_day.dart';

/// What applying a diet actually did.
///
/// Reports skipped days rather than swallowing them: a plan that only covers
/// weekdays is normal, and a UI that said "applied to 31 days" when 8 of them
/// got nothing would be lying about the state of the calendar.
class ApplyDietOutcome {
  const ApplyDietOutcome({
    required this.mealsWritten,
    required this.skippedDays,
  });

  final int mealsWritten;

  /// Days whose weekday the diet says nothing about, ascending.
  final List<NutritionDay> skippedDays;

  @override
  String toString() =>
      'ApplyDietOutcome(mealsWritten: $mealsWritten, '
      'skipped: ${skippedDays.length})';
}

/// Assigns the meals a diet prescribes to each of the given days.
///
/// This is what turns a diet ("what I eat on a Monday") into an actual plan on
/// the calendar. Without it, filling a month means assigning meals one by one,
/// which nobody would do twice.
///
/// WEEKDAY-AWARE: each day receives the day group that covers ITS weekday, so a
/// diet with a different Sunday menu lands correctly instead of one group being
/// stamped over the whole range.
///
/// The generated planned-meal ids are DETERMINISTIC — `pm-{slotId}-{epochDay}`
/// — which makes the whole operation idempotent: applying the same diet to the
/// same days twice overwrites the same rows instead of stacking duplicates or
/// tripping the `(slot, day)` uniqueness rule.
class ApplyDietToDays {
  ApplyDietToDays(this._source);

  final DietPlanSource _source;

  /// Builds the id used for a slot on a day. Exposed so callers (and tests)
  /// can reason about the same identity the use case writes.
  static String plannedMealId(String slotId, NutritionDay day) =>
      'pm-$slotId-${day.epochDay}';

  /// Writes the plan onto [days].
  ///
  /// Stops at the FIRST failure and returns it: a half-applied plan is easier
  /// to reason about when the caller knows exactly where it stopped, and the
  /// deterministic ids make a retry safe.
  Future<Result<ApplyDietOutcome, NutritionFailure>> call({
    required DietPlan plan,
    required List<NutritionDay> days,
  }) async {
    var written = 0;
    final skipped = <NutritionDay>[];

    for (final day in days) {
      final group = plan.groupForWeekday(day.weekday);
      if (group == null) {
        skipped.add(day);
        continue;
      }
      for (final slot in group.template.slots) {
        final result = await _source.savePlannedMeal(
          PlannedMeal(
            id: plannedMealId(slot.id, day),
            slotId: slot.id,
            day: day,
            // Frozen at assignment time: editing the diet later must not
            // silently rewrite what a past day was judged against.
            targetSnapshot: slot.target,
          ),
        );
        if (result case Err(failure: final failure)) return Err(failure);
        written++;
      }
    }

    return Ok(ApplyDietOutcome(mealsWritten: written, skippedDays: skipped));
  }

  /// Removes every planned meal this use case would have created for [days].
  ///
  /// Intake already logged against those meals survives — the storage layer
  /// nulls the link rather than cascading the delete.
  Future<Result<ApplyDietOutcome, NutritionFailure>> clear({
    required DietPlan plan,
    required List<NutritionDay> days,
  }) async {
    var removed = 0;
    final skipped = <NutritionDay>[];

    for (final day in days) {
      final group = plan.groupForWeekday(day.weekday);
      if (group == null) {
        skipped.add(day);
        continue;
      }
      for (final slot in group.template.slots) {
        final result = await _source.deletePlannedMeal(
          plannedMealId(slot.id, day),
        );
        if (result case Err(failure: final failure)) return Err(failure);
        removed++;
      }
    }

    return Ok(ApplyDietOutcome(mealsWritten: removed, skippedDays: skipped));
  }
}
