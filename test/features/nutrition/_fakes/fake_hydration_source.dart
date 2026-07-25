import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/hydration_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// In-memory [HydrationSource] test double.
///
/// Mirrors the contract the real adapter (`SqlHydrationSource`) MUST honor:
/// [record] persists, [entriesOn] filters by day and returns entries in
/// recording order, and a day with no entries yields an empty list — never
/// an error. This fake NEVER produces [PermissionDenied]: that failure is
/// exclusive to platform-backed sources.
class FakeHydrationSource implements HydrationSource {
  final List<HydrationEntry> _entries = [];

  @override
  Future<Result<void, NutritionFailure>> record(HydrationEntry entry) async {
    _entries.add(entry);
    return const Ok(null);
  }

  @override
  Future<Result<List<HydrationEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  ) async {
    final matches = _entries
        .where((entry) => NutritionDay.fromDateTime(entry.recordedAt) == day)
        .toList(growable: false);
    return Ok(matches);
  }
}
