import '../value_objects/food_quantity.dart';

/// One interchangeable way to satisfy a [MealComponent].
///
/// [rawText] is the plan's own wording, kept verbatim so the app can show what
/// the dietitian actually wrote rather than a reconstruction of it.
class ComponentOption {
  ComponentOption({
    required this.id,
    required this.foodId,
    required this.quantity,
    required this.rawText,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (foodId.trim().isEmpty) {
      throw ArgumentError.value(foodId, 'foodId', 'must not be empty');
    }
    if (rawText.trim().isEmpty) {
      throw ArgumentError.value(rawText, 'rawText', 'must not be empty');
    }
  }

  final String id;

  /// References a `FoodItem.id`.
  final String foodId;

  final FoodQuantity quantity;

  /// The plan's original line for this option, e.g.
  /// `140 gramos de pollo, pechuga, plancha`.
  final String rawText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComponentOption &&
          other.id == id &&
          other.foodId == foodId &&
          other.quantity == quantity &&
          other.rawText == rawText);

  @override
  int get hashCode => Object.hash(id, foodId, quantity, rawText);

  @override
  String toString() =>
      'ComponentOption(id: $id, foodId: $foodId, quantity: $quantity, '
      'rawText: $rawText)';
}

/// A single element of a meal, together with every option that satisfies it.
///
/// This is the granularity at which real diet plans express alternatives: the
/// plan swaps the chicken for beef while the rice stays put. Modelling
/// alternatives on the whole meal instead would make that inexpressible.
///
/// The options come from the plan already treated as interchangeable by its
/// author, so the app MUST NOT recompute equivalences or reorder them by
/// closeness — [options] order is the dietitian's preference order, and
/// [defaultOption] is their first choice.
class MealComponent {
  MealComponent({
    required this.id,
    required this.position,
    required List<ComponentOption> options,
    this.sectionLabel,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (position < 0) {
      throw ArgumentError.value(position, 'position', 'must be >= 0');
    }
    if (options.isEmpty) {
      throw ArgumentError.value(
        options,
        'options',
        'must carry at least one option',
      );
    }
    final ids = options.map((o) => o.id).toSet();
    if (ids.length != options.length) {
      throw ArgumentError.value(
        options.map((o) => o.id),
        'options',
        'option ids must be unique',
      );
    }
    this.options = List.unmodifiable(options);
  }

  final String id;

  /// Ordering within the owning meal slot.
  final int position;

  /// Optional grouping the plan used, e.g. `PRIMER PLATO` or `POSTRE`.
  final String? sectionLabel;

  late final List<ComponentOption> options;

  /// The plan's first-choice option.
  ComponentOption get defaultOption => options.first;

  /// Whether the user has a real choice here.
  bool get hasAlternatives => options.length > 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MealComponent) return false;
    if (other.id != id ||
        other.position != position ||
        other.sectionLabel != sectionLabel ||
        other.options.length != options.length) {
      return false;
    }
    for (var i = 0; i < options.length; i++) {
      if (other.options[i] != options[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, position, sectionLabel, Object.hashAll(options));

  @override
  String toString() =>
      'MealComponent(id: $id, position: $position, '
      'sectionLabel: $sectionLabel, options: $options)';
}
