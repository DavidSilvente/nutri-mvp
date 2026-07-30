import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// Domain port for reading and writing hydration (water) data.
///
/// Hydration is an independent aggregate from `NutritionEntry`: this port
/// exposes exactly what the domain needs (record and query), with ZERO
/// knowledge of `drift`/SQLite or any platform-specific health API.
///
/// Authorization is NOT a method on this port — it is expressed as the
/// [PermissionDenied] variant of [NutritionFailure] (reused from the
/// nutrition domain), which manual/SQL implementations MUST NEVER produce.
abstract interface class HydrationSource {
  /// Persists [entry]. Returns [Err] with a [NutritionFailure] on failure.
  Future<Result<void, NutritionFailure>> record(HydrationEntry entry);

  /// Returns all hydration entries recorded for [day], in the order they
  /// were recorded. A day with no entries MUST yield an empty list wrapped
  /// in [Ok] — never an error and never `null`.
  Future<Result<List<HydrationEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  );
}
