import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../services/derived_targets.dart';
import '../services/food_catalog.dart';
import '../value_objects/nutrition_target.dart';
import 'meal_component.dart';

/// A single meal slot within a [DietTemplate].
///
/// Each slot carries a macro target and an ordered [position] within the
/// template. Positions are validated as non-negative and unique at the template
/// level.
///
/// A slot reaches its [target] one of two ways:
///
/// * hand-entered — the caller supplies [target] directly, which is how
///   templates built in the in-app editor work;
/// * derived — the caller supplies [components] and the target is computed from
///   the referenced foods and their quantities (see [DietMealSlot.derived]).
///   This is how an imported plan works, because there the foods are the source
///   of truth and the macros follow from them.
///
/// Both live on the same class so everything downstream — the calendar, the day
/// view, adherence — keeps working against one shape regardless of provenance.
class DietMealSlot {
  DietMealSlot({
    required this.id,
    required this.label,
    required this.position,
    required this.target,
    this.timeOfDay,
    List<MealComponent> components = const [],
    List<String> notes = const [],
  }) {
    if (position < 0) {
      throw ArgumentError.value(position, 'position', 'must be >= 0');
    }
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
    if (timeOfDay != null && !_timePattern.hasMatch(timeOfDay!)) {
      throw ArgumentError.value(
        timeOfDay,
        'timeOfDay',
        'must be HH:mm in 24-hour form',
      );
    }
    final positions = components.map((c) => c.position).toSet();
    if (positions.length != components.length) {
      throw ArgumentError.value(
        components.map((c) => c.position),
        'components',
        'component positions must be unique',
      );
    }
    this.components = List.unmodifiable(
      components.toList()..sort((a, b) => a.position.compareTo(b.position)),
    );
    this.notes = List.unmodifiable(notes);
  }

  /// Builds a slot whose [target] is derived from [components].
  ///
  /// Returns [UnknownFoodFailure] naming every food id the catalog cannot
  /// resolve, so a caller importing a plan learns about all gaps at once.
  static Result<DietMealSlot, NutritionFailure> derived({
    required String id,
    required String label,
    required int position,
    required List<MealComponent> components,
    required FoodCatalog catalog,
    String? timeOfDay,
    List<String> notes = const [],
    Map<String, String> selections = const {},
  }) {
    final derivedTarget = DerivedTargets.forComponents(
      components,
      catalog,
      selections: selections,
    );
    return switch (derivedTarget) {
      Err(failure: final failure) => Err(failure),
      Ok(value: final target) => Ok(
        DietMealSlot(
          id: id,
          label: label,
          position: position,
          target: target,
          timeOfDay: timeOfDay,
          components: components,
          notes: notes,
        ),
      ),
    };
  }

  static final RegExp _timePattern =
      RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  final String id;
  final String label;
  final int position;
  final NutritionTarget target;

  /// The time the plan scheduled this meal for, as `HH:mm`, when it gave one.
  final String? timeOfDay;

  /// The foods this slot is made of, ordered by position. Empty for
  /// hand-entered slots, which carry a [target] and nothing else.
  late final List<MealComponent> components;

  /// Free-text guidance the source plan attached to this meal (soaking oats,
  /// batch-cooking rice, which supermarket format to buy).
  ///
  /// Kept because it is a real part of what the dietitian prescribed; dropping
  /// it would silently discard the reasoning behind the numbers.
  late final List<String> notes;

  /// Whether this slot's [target] was derived from [components].
  bool get isDerived => components.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DietMealSlot) return false;
    if (other.id != id ||
        other.label != label ||
        other.position != position ||
        other.target != target ||
        other.timeOfDay != timeOfDay ||
        other.components.length != components.length ||
        other.notes.length != notes.length) {
      return false;
    }
    for (var i = 0; i < components.length; i++) {
      if (other.components[i] != components[i]) return false;
    }
    for (var i = 0; i < notes.length; i++) {
      if (other.notes[i] != notes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    position,
    target,
    timeOfDay,
    Object.hashAll(components),
    Object.hashAll(notes),
  );

  @override
  String toString() =>
      'DietMealSlot(id: $id, label: $label, position: $position, '
      'target: $target, timeOfDay: $timeOfDay, '
      'components: ${components.length}, notes: ${notes.length})';
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
    this.declaredDailyEnergyKcal,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (declaredDailyEnergyKcal != null && declaredDailyEnergyKcal! < 0) {
      throw ArgumentError.value(
        declaredDailyEnergyKcal,
        'declaredDailyEnergyKcal',
        'must be >= 0 when present',
      );
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

  /// Builds a template whose [dailyTarget] is the SUM of its slots.
  ///
  /// Imported plans state a round headline figure ("2950 kcal") that derived
  /// macros will never reproduce exactly — real composition tables land a few
  /// percent away from whatever the plan's author used. Validating derived
  /// slots against that headline would reject every import.
  ///
  /// So the headline is not treated as a constraint: it is kept separately as
  /// [declaredDailyEnergyKcal] for display, and [dailyTarget] is computed from
  /// the slots. The sum invariant therefore holds by construction, and the
  /// existing tolerance keeps absorbing floating-point noise rather than being
  /// widened to paper over a real discrepancy.
  factory DietTemplate.derived({
    required String id,
    required String name,
    required List<DietMealSlot> slots,
    num? declaredDailyEnergyKcal,
  }) {
    return DietTemplate(
      id: id,
      name: name,
      dailyTarget: NutritionTarget.sum(slots.map((s) => s.target)),
      slots: slots,
      declaredDailyEnergyKcal: declaredDailyEnergyKcal,
    );
  }

  final String id;
  final String name;

  /// The target this template is actually held to: for derived templates it is
  /// the sum of the slots, not the plan's headline figure.
  final NutritionTarget dailyTarget;

  /// The headline daily energy the source plan advertised, when it stated one
  /// (e.g. 2950 for a plan titled "AJUSTE 2950KCAL").
  ///
  /// Display only. Derived macros routinely land a few percent from this
  /// figure, so it MUST NOT be used as a validation bound or as the denominator
  /// for adherence — [dailyTarget] is the honest number.
  final num? declaredDailyEnergyKcal;

  late final List<DietMealSlot> slots;

  /// Signed difference between the derived [dailyTarget] and the plan's
  /// headline figure, or null when the plan stated none.
  ///
  /// Exposed so the UI can be upfront about the gap instead of hiding it.
  num? get declaredEnergyDelta => declaredDailyEnergyKcal == null
      ? null
      : dailyTarget.energy.kcal - declaredDailyEnergyKcal!;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DietTemplate) return false;
    if (other.id != id ||
        other.name != name ||
        other.dailyTarget != dailyTarget ||
        other.declaredDailyEnergyKcal != declaredDailyEnergyKcal ||
        other.slots.length != slots.length) {
      return false;
    }
    for (var i = 0; i < slots.length; i++) {
      if (other.slots[i] != slots[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dailyTarget,
    declaredDailyEnergyKcal,
    Object.hashAll(slots),
  );

  @override
  String toString() =>
      'DietTemplate(id: $id, name: $name, dailyTarget: $dailyTarget, '
      'declaredDailyEnergyKcal: $declaredDailyEnergyKcal, slots: $slots)';
}
