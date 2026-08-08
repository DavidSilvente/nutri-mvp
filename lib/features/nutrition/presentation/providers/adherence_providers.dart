import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_day_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_month_adherence.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/adherence_tolerance.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/calendar_month.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/data_revision_provider.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';

/// Today's calendar date, as a provider so the whole feature reads the clock
/// through ONE seam. Tests override it to pin "today" instead of relying on
/// the machine date, which would make calendar assertions rot over time.
final todayProvider = Provider<NutritionDay>((ref) {
  return NutritionDay.fromDateTime(DateTime.now());
});

/// The criterion used to judge whether a logged meal met its plan. Exposed as
/// a provider so it can become a user setting without touching call sites.
final adherenceToleranceProvider = Provider<AdherenceTolerance>((ref) {
  return AdherenceTolerance.standard;
});

/// The criterion used to judge the DAY's own verdict, independent of
/// [adherenceToleranceProvider], which stays per-meal.
final dailyAdherenceToleranceProvider = Provider<AdherenceTolerance>((ref) {
  return AdherenceTolerance.daily;
});

final getDayPlanProvider = Provider<GetDayPlan>((ref) {
  return GetDayPlan(
    dietPlanSource: ref.watch(dietPlanSourceProvider),
    nutritionSource: ref.watch(nutritionSourceProvider),
    slotDirectory: ref.watch(mealSlotDirectoryProvider),
    choiceSource: ref.watch(optionChoiceSourceProvider),
    tolerance: ref.watch(adherenceToleranceProvider),
    dailyTolerance: ref.watch(dailyAdherenceToleranceProvider),
  );
});

final getMonthAdherenceProvider = Provider<GetMonthAdherence>((ref) {
  return GetMonthAdherence(
    dietPlanSource: ref.watch(dietPlanSourceProvider),
    nutritionSource: ref.watch(nutritionSourceProvider),
    slotDirectory: ref.watch(mealSlotDirectoryProvider),
    tolerance: ref.watch(adherenceToleranceProvider),
    dailyTolerance: ref.watch(dailyAdherenceToleranceProvider),
  );
});

/// The plan and the reality of a single day.
///
/// Watches [dataRevisionProvider] so it re-runs after any intake or planning
/// write, without writers needing to know this provider exists.
final dayPlanProvider = FutureProvider.family<DayPlan, NutritionDay>((
  ref,
  day,
) async {
  ref.watch(dataRevisionProvider);
  final result = await ref.watch(getDayPlanProvider)(
    day,
    today: ref.watch(todayProvider),
  );
  return switch (result) {
    Ok(value: final plan) => plan,
    Err(failure: final failure) => throw HealthFailureException(failure),
  };
});

/// One month of evaluated days, for the calendar grid.
final monthAdherenceProvider =
    FutureProvider.family<MonthAdherence, CalendarMonth>((ref, month) async {
      ref.watch(dataRevisionProvider);
      final result = await ref.watch(getMonthAdherenceProvider)(
        month,
        today: ref.watch(todayProvider),
      );
      return switch (result) {
        Ok(value: final adherence) => adherence,
        Err(failure: final failure) => throw HealthFailureException(failure),
      };
    });
