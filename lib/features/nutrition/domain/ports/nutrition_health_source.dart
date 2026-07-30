import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// Domain port for reading and writing nutrition data.
///
/// Designed from the manual/SQL use case only: it exposes exactly what the
/// domain needs (record and query), with ZERO knowledge of
/// HealthKit/Health Connect/`health` package or of `drift`/SQLite. A future
/// HealthKit-backed implementation MUST conform to this same contract.
///
/// Authorization is NOT a method on this port — it is expressed as the
/// [PermissionDenied] variant of [NutritionFailure], which manual/SQL
/// implementations MUST NEVER produce.
abstract interface class NutritionHealthSource {
  /// Persists [entry]. Returns [Err] with a [NutritionFailure] on failure.
  Future<Result<void, NutritionFailure>> record(NutritionEntry entry);

  /// Returns all entries recorded for [day], in the order they were
  /// recorded. A day with no entries MUST yield an empty list wrapped in
  /// [Ok] — never an error and never `null`.
  Future<Result<List<NutritionEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  );
}
