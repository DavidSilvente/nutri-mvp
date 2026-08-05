import 'food_quantity.dart';

/// A single food reference logged by the user: a food plus how much of it.
///
/// Mirrors [ComponentOption]'s shape, deliberately minus three fields that
/// exist there for reasons that don't apply here:
/// - no `id` — nothing references an ingredient by id, unlike
///   `ComponentOption.id`, which lets `ComponentSelections` name a choice.
/// - no `rawText` — the user picked this row from the catalog, so
///   `FoodItem.name` already IS the wording; there is no dietitian phrasing
///   to preserve verbatim, unlike a diet plan's own line.
/// - no `position` — list order already carries it, exactly as
///   `MealComponent.options` order does. Position is a storage-only concern
///   (the composite primary key on the persisted child tables), never a
///   domain field.
class LoggedIngredient {
  LoggedIngredient({required this.foodId, required this.quantity}) {
    if (foodId.trim().isEmpty) {
      throw ArgumentError.value(foodId, 'foodId', 'must not be empty');
    }
  }

  /// References a `FoodItem.id`.
  final String foodId;

  final FoodQuantity quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoggedIngredient &&
          other.foodId == foodId &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(foodId, quantity);

  @override
  String toString() =>
      'LoggedIngredient(foodId: $foodId, quantity: $quantity)';
}
