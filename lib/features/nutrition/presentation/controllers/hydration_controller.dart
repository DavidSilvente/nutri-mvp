import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';

/// Orchestrates the hydration use cases for the current day's entries.
///
/// Exposes today's [HydrationEntry] list as an [AsyncValue], and lets the UI
/// [record] a new entry, refreshing the list on success. Reuses
/// [HealthFailureException] to wrap the `NutritionFailure` type shared
/// with nutrition (see `hydration-log` design) — mirrors
/// `NutritionController` exactly, since both use cases delegate to a
/// `Result<_, NutritionFailure>`-returning port. Unlike the earlier
/// `NutritionFailureException`, this shared wrapper lives in `core/` so
/// neither controller depends on the other's presentation-layer file.
class HydrationController extends AsyncNotifier<List<HydrationEntry>> {
  @override
  FutureOr<List<HydrationEntry>> build() => _loadToday();

  /// Records [entry] via the use case. On success, refreshes the state with
  /// today's entries. On failure, surfaces the failure as an [AsyncError]
  /// via [HealthFailureException].
  Future<void> record(HydrationEntry entry) async {
    final recordResult = await ref.read(recordHydrationProvider).call(entry);
    switch (recordResult) {
      case Ok():
        state = await AsyncValue.guard(_loadToday);
      case Err(failure: final failure):
        state = AsyncValue.error(
          HealthFailureException(failure),
          StackTrace.current,
        );
    }
  }

  Future<List<HydrationEntry>> _loadToday() async {
    final result = await ref.read(getDailyHydrationProvider).call(_today());
    return switch (result) {
      Ok(value: final entries) => entries,
      Err(failure: final failure) => throw HealthFailureException(failure),
    };
  }

  NutritionDay _today() => NutritionDay.fromDateTime(DateTime.now());
}
