import '../services/derived_targets.dart';
import '../value_objects/logged_ingredient.dart';
import '../value_objects/nutrition_target.dart';

/// A substitute option defined for a specific planned meal.
///
/// Substitutes are scoped to a single [plannedMealId] and carry a full
/// nutritional target so they can be ranked against the meal's macro target.
///
/// [ingredients] is the OPTIONAL food-first composition backing [target],
/// mirroring `MealComponent.options`; empty for a hand-typed substitute or
/// one created before this change. Like [SavedMeal], a substitute is an
/// editable TEMPLATE — [MealSubstitute.composed] recomputes only its own
/// [target]. The plain constructor is for storage rehydration and manual
/// entry only.
class MealSubstitute {
  MealSubstitute({
    required this.id,
    required this.plannedMealId,
    required this.label,
    required this.target,
    List<LoggedIngredient> ingredients = const [],
  }) : ingredients = List.unmodifiable(ingredients) {
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
  }

  /// Builds a substitute whose [target] is DERIVED from [composition].
  factory MealSubstitute.composed({
    required String id,
    required String plannedMealId,
    required String label,
    required DerivedComposition composition,
  }) => MealSubstitute(
    id: id,
    plannedMealId: plannedMealId,
    label: label,
    target: composition.target,
    ingredients: composition.ingredients,
  );

  final String id;
  final String plannedMealId;
  final String label;
  final NutritionTarget target;
  final List<LoggedIngredient> ingredients;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MealSubstitute) return false;
    if (other.id != id ||
        other.plannedMealId != plannedMealId ||
        other.label != label ||
        other.target != target ||
        other.ingredients.length != ingredients.length) {
      return false;
    }
    for (var i = 0; i < ingredients.length; i++) {
      if (other.ingredients[i] != ingredients[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    plannedMealId,
    label,
    target,
    Object.hashAll(ingredients),
  );

  @override
  String toString() =>
      'MealSubstitute(id: $id, plannedMealId: $plannedMealId, '
      'label: $label, target: $target, ingredients: $ingredients)';
}
