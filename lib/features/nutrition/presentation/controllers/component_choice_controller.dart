import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/data_revision_provider.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Writes the option a user picks for one component, at either scope: a
/// day-scoped selection, or a standing preference that applies to every day
/// without a selection of its own.
///
/// A family on [NutritionDay] because the day-scoped write is day-scoped, and
/// because both screens that read a resolved component for this day
/// (`day_plan_screen`, `diet_day_screen`) already key their controllers off
/// the same day. Holds no data of its own: after a successful write it bumps
/// [dataRevisionProvider], so `dayPlanProvider` re-reads, and invalidates
/// `dietDayControllerProvider(arg)`, so this day's own view re-reads too.
/// That second step is what actually lets a write made from the day-plan
/// screen reach `diet_day_screen` — the coupling those two screens shared with
/// `DietDayController.chooseOption`/`resetOption`, not the widget that used to
/// call them.
class ComponentChoiceController
    extends FamilyAsyncNotifier<void, NutritionDay> {
  @override
  FutureOr<void> build(NutritionDay arg) {}

  /// Chooses [optionId] for [componentId] on this controller's day.
  Future<void> selectOption({
    required String componentId,
    required String optionId,
  }) async {
    final result = await ref
        .read(dietPlanStoreProvider)
        .selectOption(day: arg, componentId: componentId, optionId: optionId);
    await _commit(result);
  }

  /// Drops the recorded day-scoped choice for [componentId], reverting
  /// resolution to whatever the next precedence level says (a standing
  /// preference, or the plan's default option). A no-op when nothing was
  /// recorded for this day.
  Future<void> clearSelection(String componentId) async {
    final result = await ref
        .read(dietPlanStoreProvider)
        .clearSelection(day: arg, componentId: componentId);
    await _commit(result);
  }

  /// Makes [optionId] the standing preference for [componentId], applied on
  /// every day that carries no day-scoped selection of its own.
  Future<void> setPreference({
    required String componentId,
    required String optionId,
  }) async {
    final result = await ref
        .read(dietPlanStoreProvider)
        .setPreferredOption(componentId: componentId, optionId: optionId);
    await _commit(result);
  }

  /// Drops the standing preference for [componentId].
  Future<void> clearPreference(String componentId) async {
    final result = await ref
        .read(dietPlanStoreProvider)
        .clearPreferredOption(componentId);
    await _commit(result);
  }

  Future<void> _commit(Result<void, NutritionFailure> result) async {
    switch (result) {
      case Ok():
        bumpDataRevision(ref);
        ref.invalidate(dietDayControllerProvider(arg));
        state = const AsyncValue.data(null);
      case Err(failure: final failure):
        state = AsyncValue.error(
          HealthFailureException(failure),
          StackTrace.current,
        );
    }
  }
}
