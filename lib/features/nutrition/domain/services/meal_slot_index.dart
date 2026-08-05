import '../entities/diet_plan.dart';
import '../entities/meal_component.dart';
import 'food_catalog.dart';

/// A slot's identity within its diet: what to call it, where it sits in the
/// day, and what it is made of.
class MealSlotInfo {
  const MealSlotInfo({
    required this.label,
    required this.position,
    required this.dayGroupLabel,
    this.components = const [],
    this.timeOfDay,
    this.notes = const [],
  });

  final String label;
  final int position;

  /// The diet's own wording for the group of weekdays this slot belongs to,
  /// e.g. `LU Y VI`.
  final String dayGroupLabel;

  /// The foods this slot is made of, in the plan's own order. Empty for a
  /// hand-entered slot.
  final List<MealComponent> components;

  /// The time the plan scheduled this meal for, as `HH:mm`, when it gave one.
  final String? timeOfDay;

  /// Free-text guidance the source plan attached to this meal.
  final List<String> notes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MealSlotInfo) return false;
    if (other.label != label ||
        other.position != position ||
        other.dayGroupLabel != dayGroupLabel ||
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
    label,
    position,
    dayGroupLabel,
    Object.hashAll(components),
    timeOfDay,
    Object.hashAll(notes),
  );

  @override
  String toString() =>
      'MealSlotInfo(label: $label, position: $position, '
      'dayGroup: $dayGroupLabel, components: ${components.length}, '
      'timeOfDay: $timeOfDay, notes: ${notes.length})';
}

/// Flattens a diet into a slot-id lookup.
///
/// Planned meals only carry a `slotId`; the human label ("Breakfast"), the
/// ordering position and the food itself live on the diet's meal slot.
/// Resolving that once per load keeps the cross-referencing out of both the
/// UI and the use cases.
class MealSlotIndex {
  MealSlotIndex(
    Map<String, MealSlotInfo> bySlotId, {
    this.estimatedFoodIds = const {},
  }) : _bySlotId = bySlotId;

  /// Indexes EVERY day group of [plan], not just the one for a given weekday.
  ///
  /// A month of planned meals spans every group, so an index built from one
  /// weekday would leave most of the calendar unable to name its own meals.
  ///
  /// [catalog] resolves every option's food so [estimatedFoodIds] can be
  /// computed once here, rather than handing the catalog to every use case
  /// that just wants to know whether a chosen food needs review.
  factory MealSlotIndex.fromPlan(DietPlan plan, FoodCatalog catalog) {
    final map = <String, MealSlotInfo>{};
    final estimatedFoodIds = <String>{};
    for (final group in plan.dayGroups) {
      for (final slot in group.template.slots) {
        map[slot.id] = MealSlotInfo(
          label: slot.label,
          position: slot.position,
          dayGroupLabel: group.label,
          components: slot.components,
          timeOfDay: slot.timeOfDay,
          notes: slot.notes,
        );
        for (final component in slot.components) {
          for (final option in component.options) {
            final food = catalog.byId(option.foodId);
            if (food != null && food.source.needsReview) {
              estimatedFoodIds.add(option.foodId);
            }
          }
        }
      }
    }
    return MealSlotIndex(map, estimatedFoodIds: estimatedFoodIds);
  }

  /// An index that knows no slots, for when no diet is active.
  MealSlotIndex.empty() : _bySlotId = const {}, estimatedFoodIds = const {};

  final Map<String, MealSlotInfo> _bySlotId;

  /// Every food id, plan-wide, whose value is only an estimate — so a caller
  /// can tell a resolved option needs review without holding a [FoodCatalog]
  /// of its own.
  final Set<String> estimatedFoodIds;

  /// The slot's info, or `null` when the slot is unknown — which happens for a
  /// day planned from a diet that has since been edited or deleted.
  MealSlotInfo? operator [](String slotId) => _bySlotId[slotId];

  /// The slot's position, or a large sentinel so unknown slots sort last
  /// instead of jumping to the top of the day.
  int positionOf(String slotId) => _bySlotId[slotId]?.position ?? 1 << 20;

  /// The slot's label, falling back to [fallback] for an unknown slot.
  String labelOf(String slotId, {String fallback = 'Meal'}) =>
      _bySlotId[slotId]?.label ?? fallback;

  bool get isEmpty => _bySlotId.isEmpty;
}
