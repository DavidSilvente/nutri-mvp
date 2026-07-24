import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';

/// A single nutrition intake record: energy, macros and water, at a point
/// in time.
///
/// Validation is fully delegated to its value objects ([Energy], [Macros],
/// [WaterVolume]) — this entity does not duplicate their `>= 0` checks.
class NutritionEntry {
  NutritionEntry({
    required this.id,
    required this.recordedAt,
    required this.energy,
    required this.macros,
    required this.water,
  });

  final String id;
  final DateTime recordedAt;
  final Energy energy;
  final Macros macros;
  final WaterVolume water;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionEntry &&
          other.id == id &&
          other.recordedAt == recordedAt &&
          other.energy == energy &&
          other.macros == macros &&
          other.water == water);

  @override
  int get hashCode => Object.hash(id, recordedAt, energy, macros, water);

  @override
  String toString() =>
      'NutritionEntry(id: $id, recordedAt: $recordedAt, energy: $energy, '
      'macros: $macros, water: $water)';
}
