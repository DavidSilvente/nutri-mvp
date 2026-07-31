import '../value_objects/nutrition_target.dart';

/// A substitute option defined for a specific planned meal.
///
/// Substitutes are scoped to a single [plannedMealId] and carry a full
/// nutritional target so they can be ranked against the meal's macro target.
class MealSubstitute {
  MealSubstitute({
    required this.id,
    required this.plannedMealId,
    required this.label,
    required this.target,
  }) {
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
  }

  final String id;
  final String plannedMealId;
  final String label;
  final NutritionTarget target;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealSubstitute &&
          other.id == id &&
          other.plannedMealId == plannedMealId &&
          other.label == label &&
          other.target == target);

  @override
  int get hashCode => Object.hash(id, plannedMealId, label, target);

  @override
  String toString() =>
      'MealSubstitute(id: $id, plannedMealId: $plannedMealId, '
      'label: $label, target: $target)';
}
