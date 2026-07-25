import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';

/// A single nutrition intake record: energy and macros, at a point in time.
///
/// Water is NOT part of this entity — hydration is tracked as an independent
/// aggregate (see `HydrationEntry`).
///
/// Validation is fully delegated to its value objects ([Energy], [Macros])
/// — this entity does not duplicate their `>= 0` checks.
class NutritionEntry {
  NutritionEntry({
    required this.id,
    required this.recordedAt,
    required this.energy,
    required this.macros,
  });

  final String id;
  final DateTime recordedAt;
  final Energy energy;
  final Macros macros;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionEntry &&
          other.id == id &&
          other.recordedAt == recordedAt &&
          other.energy == energy &&
          other.macros == macros);

  @override
  int get hashCode => Object.hash(id, recordedAt, energy, macros);

  @override
  String toString() =>
      'NutritionEntry(id: $id, recordedAt: $recordedAt, energy: $energy, '
      'macros: $macros)';
}
