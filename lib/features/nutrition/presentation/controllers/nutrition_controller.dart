import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';

/// Orchestrates the nutrition use cases for the current day's entries.
///
/// Exposes today's [NutritionEntry] list as an [AsyncValue], and lets the UI
/// [record] a new entry, refreshing the list on success.
class NutritionController extends AsyncNotifier<List<NutritionEntry>> {
  @override
  FutureOr<List<NutritionEntry>> build() => _loadToday();

  /// Records [entry] via the use case. On success, refreshes the state with
  /// today's entries. On failure, surfaces the failure as an [AsyncError]
  /// via [HealthFailureException].
  Future<void> record(NutritionEntry entry) async {
    final recordResult = await ref.read(recordEntryProvider).call(entry);
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

  Future<List<NutritionEntry>> _loadToday() async {
    final result = await ref.read(getDailyProvider).call(_today());
    return switch (result) {
      Ok(value: final entries) => entries,
      Err(failure: final failure) => throw HealthFailureException(failure),
    };
  }

  NutritionDay _today() => NutritionDay.fromDateTime(DateTime.now());
}
