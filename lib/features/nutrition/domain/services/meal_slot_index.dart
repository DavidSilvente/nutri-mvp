import '../entities/diet_template.dart';

/// A slot's identity within its template: what to call it and where it sits
/// in the day.
class MealSlotInfo {
  const MealSlotInfo({
    required this.label,
    required this.position,
    required this.templateId,
    required this.templateName,
  });

  final String label;
  final int position;
  final String templateId;
  final String templateName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealSlotInfo &&
          other.label == label &&
          other.position == position &&
          other.templateId == templateId &&
          other.templateName == templateName);

  @override
  int get hashCode => Object.hash(label, position, templateId, templateName);

  @override
  String toString() =>
      'MealSlotInfo(label: $label, position: $position, '
      'template: $templateName)';
}

/// Flattens a list of templates into a slot-id lookup.
///
/// Planned meals only carry a `slotId`; the human label ("Breakfast") and the
/// ordering position live on the template slot. Resolving that once per load
/// keeps the cross-referencing out of both the UI and the use cases.
class MealSlotIndex {
  MealSlotIndex(Map<String, MealSlotInfo> bySlotId) : _bySlotId = bySlotId;

  factory MealSlotIndex.fromTemplates(List<DietTemplate> templates) {
    final map = <String, MealSlotInfo>{};
    for (final template in templates) {
      for (final slot in template.slots) {
        map[slot.id] = MealSlotInfo(
          label: slot.label,
          position: slot.position,
          templateId: template.id,
          templateName: template.name,
        );
      }
    }
    return MealSlotIndex(map);
  }

  final Map<String, MealSlotInfo> _bySlotId;

  /// The slot's info, or `null` when the slot is unknown — which can only
  /// happen if a template was edited between the two reads of a load.
  MealSlotInfo? operator [](String slotId) => _bySlotId[slotId];

  /// The slot's position, or a large sentinel so unknown slots sort last
  /// instead of jumping to the top of the day.
  int positionOf(String slotId) => _bySlotId[slotId]?.position ?? 1 << 20;

  /// The slot's label, falling back to [fallback] for an unknown slot.
  String labelOf(String slotId, {String fallback = 'Meal'}) =>
      _bySlotId[slotId]?.label ?? fallback;

  bool get isEmpty => _bySlotId.isEmpty;
}
