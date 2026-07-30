import 'package:nutri_mvp/core/result.dart';

import '../entities/diet_template.dart';
import '../entities/planned_meal.dart';
import '../failures/nutrition_failure.dart';

/// Domain policy enforcing uniqueness constraints for diet planning.
///
/// These rules are not intrinsic to a single entity; they apply to a set of
/// templates or planned meals observed by a caller. The policy returns a
/// [ConflictFailure] rather than throwing so callers can report the error
/// through the same [Result] path used by the persistence ports.
class DietPlanPolicy {
  const DietPlanPolicy._();

  /// Ensures no other template in [existing] shares [candidate]'s name.
  ///
  /// A template is allowed to keep its own name when it is already present in
  /// the list (e.g. during an update), so the comparison excludes the
  /// candidate's [id].
  static Result<DietTemplate, NutritionFailure> ensureUniqueTemplateName(
    DietTemplate candidate,
    List<DietTemplate> existing,
  ) {
    final duplicate = existing.any(
      (t) => t.name == candidate.name && t.id != candidate.id,
    );
    if (duplicate) {
      return Err(
        ConflictFailure(
          'A template named "${candidate.name}" already exists',
        ),
      );
    }
    return Ok(candidate);
  }

  /// Ensures no other planned meal in [existing] assigns the same slot to the
  /// same calendar day.
  ///
  /// Meals without a day are not constrained. A candidate that already exists
  /// in the list (same [id]) is allowed to match itself.
  static Result<PlannedMeal, NutritionFailure> ensureUniqueSameDaySlot(
    PlannedMeal candidate,
    List<PlannedMeal> existing,
  ) {
    if (candidate.day == null) return Ok(candidate);

    final duplicate = existing.any(
      (m) =>
          m.id != candidate.id &&
          m.slotId == candidate.slotId &&
          m.day == candidate.day,
    );
    if (duplicate) {
      return const Err(
        ConflictFailure(
          'Slot is already planned for this day',
        ),
      );
    }
    return Ok(candidate);
  }
}
