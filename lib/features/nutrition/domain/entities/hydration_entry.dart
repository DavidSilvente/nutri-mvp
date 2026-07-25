import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';

/// A single hydration (water) record, independent of any meal.
///
/// Validation is fully delegated to [WaterVolume] — this entity does not
/// duplicate its `>= 0` check.
class HydrationEntry {
  HydrationEntry({
    required this.id,
    required this.recordedAt,
    required this.volume,
  });

  final String id;
  final DateTime recordedAt;
  final WaterVolume volume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HydrationEntry &&
          other.id == id &&
          other.recordedAt == recordedAt &&
          other.volume == volume);

  @override
  int get hashCode => Object.hash(id, recordedAt, volume);

  @override
  String toString() =>
      'HydrationEntry(id: $id, recordedAt: $recordedAt, volume: $volume)';
}
