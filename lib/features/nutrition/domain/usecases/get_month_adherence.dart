import 'package:nutri_mvp/core/result.dart';

import '../entities/nutrition_entry.dart';
import '../entities/planned_meal.dart';
import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_source.dart';
import '../ports/meal_slot_directory.dart';
import '../ports/nutrition_health_source.dart';
import '../services/adherence_evaluator.dart';
import '../services/meal_slot_index.dart';
import '../value_objects/adherence_tolerance.dart';
import '../value_objects/calendar_month.dart';
import '../value_objects/nutrition_day.dart';

/// One month of evaluated days, keyed for O(1) lookup by the calendar grid.
class MonthAdherence {
  const MonthAdherence({
    required this.month,
    required Map<int, DayAdherence> byEpochDay,
  }) : _byEpochDay = byEpochDay;

  final CalendarMonth month;
  final Map<int, DayAdherence> _byEpochDay;

  /// The evaluation for [day]. Every day of [month] is present, including
  /// days with no plan (as [DayAdherenceStatus.unplanned]), so the grid never
  /// has to handle a missing key. Days outside the month yield `null`.
  DayAdherence? forDay(NutritionDay day) => _byEpochDay[day.epochDay];

  /// Days that had a plan at all — the denominator for any honest streak or
  /// percentage. Days without a plan are not failures.
  int get plannedDays => _byEpochDay.values
      .where((d) => d.status != DayAdherenceStatus.unplanned)
      .length;

  int get completeDays => _byEpochDay.values
      .where((d) => d.status == DayAdherenceStatus.complete)
      .length;

  /// Days already settled: neither upcoming nor still in progress, and with a
  /// plan to judge.
  int get settledDays => _byEpochDay.values
      .where(
        (d) =>
            d.status == DayAdherenceStatus.complete ||
            d.status == DayAdherenceStatus.partial ||
            d.status == DayAdherenceStatus.missed,
      )
      .length;

  /// Fraction of SETTLED days fully met, in `[0, 1]`.
  ///
  /// Deliberately excludes upcoming and in-progress days: counting a dinner
  /// not yet eaten as a failure would make the month look worse the earlier
  /// in the day you look at it.
  double get completionRatio =>
      settledDays == 0 ? 0 : completeDays / settledDays;

  @override
  String toString() =>
      'MonthAdherence($month, $completeDays/$settledDays settled days met)';
}

/// Evaluates a whole month in one pass, for the calendar view.
///
/// Loads the month's planned meals and entries with one range query each,
/// rather than one query per day.
class GetMonthAdherence {
  GetMonthAdherence({
    required DietPlanSource dietPlanSource,
    required NutritionHealthSource nutritionSource,
    required MealSlotDirectory slotDirectory,
    this.tolerance = AdherenceTolerance.standard,
  }) : _dietPlanSource = dietPlanSource,
       _nutritionSource = nutritionSource,
       _slotDirectory = slotDirectory;

  final DietPlanSource _dietPlanSource;
  final NutritionHealthSource _nutritionSource;
  final MealSlotDirectory _slotDirectory;
  final AdherenceTolerance tolerance;

  Future<Result<MonthAdherence, NutritionFailure>> call(
    CalendarMonth month, {
    required NutritionDay today,
  }) async {
    final from = month.firstDay;
    final to = month.lastDay;

    final slotsResult = await _slotDirectory.activeSlots();
    if (slotsResult case Err(failure: final failure)) return Err(failure);

    final plannedResult = await _dietPlanSource.plannedMealsBetween(from, to);
    if (plannedResult case Err(failure: final failure)) return Err(failure);

    final entriesResult = await _nutritionSource.entriesBetween(from, to);
    if (entriesResult case Err(failure: final failure)) return Err(failure);

    // Used for ordering only, so a month whose diet has since been deleted still
    // evaluates; it just cannot sort its meals by a position it no longer knows.
    final index = (slotsResult as Ok).value as MealSlotIndex;
    final plannedMeals = (plannedResult as Ok).value as List<PlannedMeal>;
    final entries = (entriesResult as Ok).value as List<NutritionEntry>;

    final mealsByDay = <int, List<PlannedMeal>>{};
    for (final meal in plannedMeals) {
      final day = meal.day;
      if (day == null) continue;
      mealsByDay.putIfAbsent(day.epochDay, () => []).add(meal);
    }

    final entriesByDay = <int, List<NutritionEntry>>{};
    for (final entry in entries) {
      final epochDay = NutritionDay.fromDateTime(entry.recordedAt).epochDay;
      entriesByDay.putIfAbsent(epochDay, () => []).add(entry);
    }

    final byEpochDay = <int, DayAdherence>{};
    for (final day in month.days) {
      final meals = mealsByDay[day.epochDay] ?? const <PlannedMeal>[];
      final ordered = [...meals]
        ..sort(
          (a, b) =>
              index.positionOf(a.slotId).compareTo(index.positionOf(b.slotId)),
        );

      byEpochDay[day.epochDay] = AdherenceEvaluator.evaluateDay(
        day: day,
        plannedMeals: ordered,
        entries: entriesByDay[day.epochDay] ?? const <NutritionEntry>[],
        today: today,
        tolerance: tolerance,
      );
    }

    return Ok(MonthAdherence(month: month, byEpochDay: byEpochDay));
  }
}
