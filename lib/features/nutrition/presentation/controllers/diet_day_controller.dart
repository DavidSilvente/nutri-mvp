import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_diet_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Orchestrates one day of the user's active diet.
///
/// State is `null` when there is no active diet, or when the active plan says
/// nothing about that weekday. Both are legitimate empty states rather than
/// errors, so the UI distinguishes "nothing planned" from "something broke".
///
/// Read-only: writes that affect this day (a component swap, day-scoped or
/// standing) go through `ComponentChoiceController`, which invalidates this
/// provider after a successful write so the day re-reads instead of going
/// stale.
class DietDayController extends FamilyAsyncNotifier<DietDay?, NutritionDay> {
  @override
  FutureOr<DietDay?> build(NutritionDay arg) => _load();

  Future<DietDay?> _load() async {
    final result = await ref.read(getDietDayProvider).call(arg);
    return switch (result) {
      Ok(value: final day) => day,
      Err(failure: final failure) => throw HealthFailureException(failure),
    };
  }
}
