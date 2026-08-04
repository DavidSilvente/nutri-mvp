import '../entities/diet_plan.dart';

/// A slot's identity within its diet: what to call it and where it sits in the
/// day.
class MealSlotInfo {
  const MealSlotInfo({
    required this.label,
    required this.position,
    required this.dayGroupLabel,
  });

  final String label;
  final int position;

  /// The diet's own wording for the group of weekdays this slot belongs to,
  /// e.g. `LU Y VI`.
  final String dayGroupLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealSlotInfo &&
          other.label == label &&
          other.position == position &&
          other.dayGroupLabel == dayGroupLabel);

  @override
  int get hashCode => Object.hash(label, position, dayGroupLabel);

  @override
  String toString() =>
      'MealSlotInfo(label: $label, position: $position, '
      'dayGroup: $dayGroupLabel)';
}

/// Flattens a diet into a slot-id lookup.
///
/// Planned meals only carry a `slotId`; the human label ("Breakfast") and the
/// ordering position live on the diet's meal slot. Resolving that once per load
/// keeps the cross-referencing out of both the UI and the use cases.
class MealSlotIndex {
  MealSlotIndex(Map<String, MealSlotInfo> bySlotId) : _bySlotId = bySlotId;

  /// Indexes EVERY day group of [plan], not just the one for a given weekday.
  ///
  /// A month of planned meals spans every group, so an index built from one
  /// weekday would leave most of the calendar unable to name its own meals.
  factory MealSlotIndex.fromPlan(DietPlan plan) {
    final map = <String, MealSlotInfo>{};
    for (final group in plan.dayGroups) {
      for (final slot in group.template.slots) {
        map[slot.id] = MealSlotInfo(
          label: slot.label,
          position: slot.position,
          dayGroupLabel: group.label,
        );
      }
    }
    return MealSlotIndex(map);
  }

  /// An index that knows no slots, for when no diet is active.
  MealSlotIndex.empty() : _bySlotId = const {};

  final Map<String, MealSlotInfo> _bySlotId;

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
