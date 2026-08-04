import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_diet_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Orchestrates one day of the user's active diet, and the per-item swaps made
/// against it.
///
/// State is `null` when there is no active diet, or when the active plan says
/// nothing about that weekday. Both are legitimate empty states rather than
/// errors, so the UI distinguishes "nothing planned" from "something broke".
class DietDayController extends FamilyAsyncNotifier<DietDay?, NutritionDay> {
  @override
  FutureOr<DietDay?> build(NutritionDay arg) => _load();

  /// Chooses [optionId] for [componentId] on this controller's day.
  ///
  /// Recorded per day, so swapping today's chicken for beef leaves every other
  /// day untouched.
  Future<void> chooseOption({
    required String componentId,
    required String optionId,
  }) async {
    final result = await ref
        .read(dietPlanStoreProvider)
        .selectOption(day: arg, componentId: componentId, optionId: optionId);
    await _applyWrite(result);
  }

  /// Reverts [componentId] to the plan's first choice for this day.
  Future<void> resetOption(String componentId) async {
    final result = await ref
        .read(dietPlanStoreProvider)
        .clearSelection(day: arg, componentId: componentId);
    await _applyWrite(result);
  }

  Future<void> _applyWrite(Result<void, NutritionFailure> result) async {
    switch (result) {
      case Ok():
        state = await AsyncValue.guard(_load);
      case Err(failure: final failure):
        state = AsyncValue.error(
          HealthFailureException(failure),
          StackTrace.current,
        );
    }
  }

  Future<DietDay?> _load() async {
    final result = await ref.read(getDietDayProvider).call(arg);
    return switch (result) {
      Ok(value: final day) => day,
      Err(failure: final failure) => throw HealthFailureException(failure),
    };
  }
}
