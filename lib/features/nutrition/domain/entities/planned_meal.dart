import '../value_objects/nutrition_day.dart';
import '../value_objects/nutrition_target.dart';

/// A planned assignment of a diet template meal slot to a calendar day.
///
/// The [targetSnapshot] is a verbatim copy of the slot's target at the moment
/// the meal is planned, so the planned meal remains stable even if the template
/// is edited later.
class PlannedMeal {
  PlannedMeal({
    required this.id,
    required this.slotId,
    this.day,
    required this.targetSnapshot,
  });

  final String id;
  final String slotId;
  final NutritionDay? day;
  final NutritionTarget targetSnapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedMeal &&
          other.id == id &&
          other.slotId == slotId &&
          other.day == day &&
          other.targetSnapshot == targetSnapshot);

  @override
  int get hashCode => Object.hash(id, slotId, day, targetSnapshot);

  @override
  String toString() =>
      'PlannedMeal(id: $id, slotId: $slotId, day: $day, '
      'targetSnapshot: $targetSnapshot)';
}
