import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';

/// Wraps a [NutritionFailure] so it can travel through an [AsyncValue.error]
/// (which requires an [Object], not a domain-specific sealed type).
class NutritionFailureException implements Exception {
  const NutritionFailureException(this.failure);

  final NutritionFailure failure;

  @override
  String toString() => 'NutritionFailureException($failure)';
}

/// Orchestrates the nutrition use cases for the current day's entries.
///
/// Exposes today's [NutritionEntry] list as an [AsyncValue], and lets the UI
/// [record] a new entry, refreshing the list on success.
class NutritionController extends AsyncNotifier<List<NutritionEntry>> {
  @override
  FutureOr<List<NutritionEntry>> build() => _loadToday();

  /// Records [entry] via the use case. On success, refreshes the state with
  /// today's entries. On failure, surfaces the [NutritionFailure] as an
  /// [AsyncError] via [NutritionFailureException].
  Future<void> record(NutritionEntry entry) async {
    final recordResult = await ref.read(recordEntryProvider).call(entry);
    switch (recordResult) {
      case Ok():
        state = await AsyncValue.guard(_loadToday);
      case Err(failure: final failure):
        state = AsyncValue.error(
          NutritionFailureException(failure),
          StackTrace.current,
        );
    }
  }

  Future<List<NutritionEntry>> _loadToday() async {
    final result = await ref.read(getDailyProvider).call(_today());
    return switch (result) {
      Ok(value: final entries) => entries,
      Err(failure: final failure) => throw NutritionFailureException(failure),
    };
  }

  NutritionDay _today() => NutritionDay.fromDateTime(DateTime.now());
}
