import '../value_objects/nutrition_target.dart';

/// A single meal slot within a [DietTemplate].
///
/// Each slot carries an explicit macro target and an ordered [position] within
/// the template. Positions are validated as non-negative and unique at the
/// template level.
class DietMealSlot {
  DietMealSlot({
    required this.id,
    required this.label,
    required this.position,
    required this.target,
  }) {
    if (position < 0) {
      throw ArgumentError.value(position, 'position', 'must be >= 0');
    }
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
  }

  final String id;
  final String label;
  final int position;
  final NutritionTarget target;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietMealSlot &&
          other.id == id &&
          other.label == label &&
          other.position == position &&
          other.target == target);

  @override
  int get hashCode => Object.hash(id, label, position, target);

  @override
  String toString() =>
      'DietMealSlot(id: $id, label: $label, position: $position, '
      'target: $target)';
}

/// A reusable diet plan composed of a daily nutritional target and an ordered
/// list of meal slots.
///
/// The template validates that the sum of its slot targets equals the daily
/// target within the macro/energy tolerance (0.01 units by default).
class DietTemplate {
  DietTemplate({
    required this.id,
    required this.name,
    required this.dailyTarget,
    required List<DietMealSlot> slots,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    final positions = slots.map((s) => s.position).toSet();
    if (positions.length != slots.length) {
      throw ArgumentError.value(
        slots.map((s) => s.position),
        'positions',
        'slot positions must be unique',
      );
    }
    final summed = NutritionTarget.sum(slots.map((s) => s.target));
    if (!summed.equalsWithinTolerance(dailyTarget)) {
      throw ArgumentError.value(
        slots,
        'slots',
        'slot targets must sum to the daily target within tolerance',
      );
    }
    this.slots = List.unmodifiable(slots);
  }

  final String id;
  final String name;
  final NutritionTarget dailyTarget;
  late final List<DietMealSlot> slots;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DietTemplate) return false;
    if (other.id != id ||
        other.name != name ||
        other.dailyTarget != dailyTarget ||
        other.slots.length != slots.length) {
      return false;
    }
    for (var i = 0; i < slots.length; i++) {
      if (other.slots[i] != slots[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, dailyTarget, Object.hashAll(slots));

  @override
  String toString() =>
      'DietTemplate(id: $id, name: $name, dailyTarget: $dailyTarget, '
      'slots: $slots)';
}
