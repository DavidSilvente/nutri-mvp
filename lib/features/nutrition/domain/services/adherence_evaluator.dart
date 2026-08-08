import '../entities/nutrition_entry.dart';
import '../entities/planned_meal.dart';
import '../value_objects/adherence_tolerance.dart';
import '../value_objects/energy.dart';
import '../value_objects/macros.dart';
import '../value_objects/nutrition_day.dart';
import '../value_objects/nutrition_target.dart';

/// Whether a single planned meal was met by what was actually logged.
enum MealAdherenceStatus {
  /// Nothing has been logged against this planned meal yet.
  pending,

  /// Every component of the logged total is within tolerance of the target.
  onTarget,

  /// Something was logged, but at least one component is out of tolerance.
  off,
}

/// Whether a calendar day's plan was followed.
///
/// The three "settled" outcomes ([met], [under], [over]) judge the day's
/// LOGGED TOTAL — every entry of the day, linked or not — against its
/// PLANNED TOTAL, at day close. They deliberately do not describe per-meal
/// completion: eating everything planned and then logging 1000 extra kcal
/// as an unlinked "extra" makes the day [over], not [met]. [upcoming] and
/// [inProgress] describe a day that has not had its chance yet and MUST NOT
/// be rendered as a failure.
enum DayAdherenceStatus {
  /// No meals were planned for this day — nothing to adhere to.
  unplanned,

  /// The day lies in the future: the plan exists but cannot be judged yet.
  upcoming,

  /// The day is the reference day. Always reported here, even when the
  /// logged total already matches the planned total — a day is only judged
  /// at its close, never mid-day.
  inProgress,

  /// The day's logged total is within [AdherenceTolerance.daily] of its
  /// planned total, on every component.
  met,

  /// The day's logged total falls short of its planned total by more than
  /// the daily tolerance allows (including a day with nothing logged at
  /// all).
  under,

  /// The day's logged total exceeds its planned total by more than the
  /// daily tolerance allows.
  over,
}

/// The evaluation of one planned meal against what was logged for it.
class MealAdherence {
  const MealAdherence({
    required this.plannedMeal,
    required this.logged,
    required this.entryCount,
    required this.status,
  });

  final PlannedMeal plannedMeal;

  /// The sum of every entry linked to [plannedMeal]. A meal with no entries
  /// yields a zero target rather than `null`, so callers can render progress
  /// without null checks.
  final NutritionTarget logged;

  final int entryCount;
  final MealAdherenceStatus status;

  /// The target this meal was judged against — the snapshot frozen when the
  /// meal was planned, never the (possibly edited) template slot.
  NutritionTarget get target => plannedMeal.targetSnapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealAdherence &&
          other.plannedMeal == plannedMeal &&
          other.logged == logged &&
          other.entryCount == entryCount &&
          other.status == status);

  @override
  int get hashCode => Object.hash(plannedMeal, logged, entryCount, status);

  @override
  String toString() =>
      'MealAdherence(plannedMeal: ${plannedMeal.id}, logged: $logged, '
      'entryCount: $entryCount, status: $status)';
}

/// The evaluation of a whole calendar day.
class DayAdherence {
  const DayAdherence({
    required this.day,
    required this.meals,
    required this.entryCount,
    required this.status,
  });

  final NutritionDay day;

  /// Per-meal results, in the order the planned meals were supplied. The
  /// caller controls that order (typically by slot position).
  final List<MealAdherence> meals;

  /// Every entry considered for this day, linked to a meal or not. Exposed
  /// so a settled [DayAdherenceStatus.under] day with nothing logged
  /// (`entryCount == 0`) can be told apart from one that was partially
  /// logged — both fold into the same status, but they are not the same
  /// story.
  final int entryCount;

  final DayAdherenceStatus status;

  int get plannedCount => meals.length;

  int get onTargetCount =>
      meals.where((m) => m.status == MealAdherenceStatus.onTarget).length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DayAdherence) return false;
    if (other.day != day ||
        other.status != status ||
        other.entryCount != entryCount ||
        other.meals.length != meals.length) {
      return false;
    }
    for (var i = 0; i < meals.length; i++) {
      if (other.meals[i] != meals[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(day, Object.hashAll(meals), entryCount, status);

  @override
  String toString() =>
      'DayAdherence(day: $day, status: $status, entryCount: $entryCount, '
      'onTarget: $onTargetCount/$plannedCount)';
}

/// Pure domain service that judges logged intake against a day's plan.
///
/// It is deliberately free of clock access: the caller supplies the reference
/// day, which keeps the service deterministic and testable, and lets the UI
/// evaluate past months without the result drifting as time passes.
class AdherenceEvaluator {
  const AdherenceEvaluator._();

  /// Evaluates a single [meal] against the [entries] logged for it.
  ///
  /// Only entries whose `plannedMealId` matches are considered; the caller may
  /// pass a day's full entry list. Unlinked entries are ignored entirely —
  /// they count towards daily totals, not towards adherence.
  static MealAdherence evaluateMeal({
    required PlannedMeal meal,
    required List<NutritionEntry> entries,
    AdherenceTolerance tolerance = AdherenceTolerance.standard,
  }) {
    final linked = entries
        .where((entry) => entry.plannedMealId == meal.id)
        .toList(growable: false);

    final logged = _sum(linked);

    if (linked.isEmpty) {
      return MealAdherence(
        plannedMeal: meal,
        logged: logged,
        entryCount: 0,
        status: MealAdherenceStatus.pending,
      );
    }

    final target = meal.targetSnapshot;
    final withinTolerance =
        tolerance.acceptsEnergy(
          target: target.energy.kcal,
          actual: logged.energy.kcal,
        ) &&
        tolerance.acceptsMacro(
          target: target.macros.proteinG,
          actual: logged.macros.proteinG,
        ) &&
        tolerance.acceptsMacro(
          target: target.macros.carbsG,
          actual: logged.macros.carbsG,
        ) &&
        tolerance.acceptsMacro(
          target: target.macros.fatG,
          actual: logged.macros.fatG,
        );

    return MealAdherence(
      plannedMeal: meal,
      logged: logged,
      entryCount: linked.length,
      status: withinTolerance
          ? MealAdherenceStatus.onTarget
          : MealAdherenceStatus.off,
    );
  }

  /// Evaluates every planned meal of [day] and derives the day's own status.
  ///
  /// [today] is the reference for "has this day had its chance yet": days
  /// after it are [DayAdherenceStatus.upcoming] and the reference day itself
  /// is always [DayAdherenceStatus.inProgress], never settled early. The
  /// settled verdict ([DayAdherenceStatus.met]/[under]/[over]) is judged on
  /// the DAY'S TOTAL — every entry, linked or not — against the sum of every
  /// planned meal's target, using [dailyTolerance] rather than [tolerance]
  /// (which stays the per-meal criterion). Day status is always DERIVED
  /// here, never stored.
  static DayAdherence evaluateDay({
    required NutritionDay day,
    required List<PlannedMeal> plannedMeals,
    required List<NutritionEntry> entries,
    required NutritionDay today,
    AdherenceTolerance tolerance = AdherenceTolerance.standard,
    AdherenceTolerance dailyTolerance = AdherenceTolerance.daily,
  }) {
    final meals = plannedMeals
        .map(
          (meal) =>
              evaluateMeal(meal: meal, entries: entries, tolerance: tolerance),
        )
        .toList(growable: false);

    final loggedTotal = _sum(entries);
    final plannedTotal = NutritionTarget.sum(meals.map((m) => m.target));

    return DayAdherence(
      day: day,
      meals: meals,
      entryCount: entries.length,
      status: _dayStatus(
        day: day,
        today: today,
        meals: meals,
        loggedTotal: loggedTotal,
        plannedTotal: plannedTotal,
        dailyTolerance: dailyTolerance,
      ),
    );
  }

  static DayAdherenceStatus _dayStatus({
    required NutritionDay day,
    required NutritionDay today,
    required List<MealAdherence> meals,
    required NutritionTarget loggedTotal,
    required NutritionTarget plannedTotal,
    required AdherenceTolerance dailyTolerance,
  }) {
    if (meals.isEmpty) return DayAdherenceStatus.unplanned;

    // A plan can only be judged once its day is over. Judging today as
    // settled — even when it already matches at noon — would flip the
    // verdict back and forth as more gets logged before the day ends.
    if (day.epochDay > today.epochDay) return DayAdherenceStatus.upcoming;
    if (day.epochDay == today.epochDay) return DayAdherenceStatus.inProgress;

    return _settledStatus(
      logged: loggedTotal,
      planned: plannedTotal,
      tolerance: dailyTolerance,
    );
  }

  /// The settled-day decision rule (day.epochDay < today.epochDay).
  ///
  /// [met] when every component is within [tolerance]. Otherwise the sign of
  /// the ENERGY delta decides [over]/[under] — kcal is the metric a user
  /// reaches for first, so macro deviations stay detail, never the label.
  /// Only when the energy delta is EXACTLY zero (impossible when [met] is
  /// already true) does a macro decide, by whichever has the largest
  /// relative deviation; ties resolve by fixed field order
  /// protein -> carbs -> fat, and a zero target with non-zero logged always
  /// reads as an overshoot.
  static DayAdherenceStatus _settledStatus({
    required NutritionTarget logged,
    required NutritionTarget planned,
    required AdherenceTolerance tolerance,
  }) {
    final withinTolerance =
        tolerance.acceptsEnergy(
          target: planned.energy.kcal,
          actual: logged.energy.kcal,
        ) &&
        tolerance.acceptsMacro(
          target: planned.macros.proteinG,
          actual: logged.macros.proteinG,
        ) &&
        tolerance.acceptsMacro(
          target: planned.macros.carbsG,
          actual: logged.macros.carbsG,
        ) &&
        tolerance.acceptsMacro(
          target: planned.macros.fatG,
          actual: logged.macros.fatG,
        );
    if (withinTolerance) return DayAdherenceStatus.met;

    final energyDelta =
        logged.energy.kcal.toDouble() - planned.energy.kcal.toDouble();
    if (energyDelta > 0) return DayAdherenceStatus.over;
    if (energyDelta < 0) return DayAdherenceStatus.under;

    // energyDelta == 0 but withinTolerance was false, so at least one macro
    // is genuinely out — this branch can never see all-zero deltas.
    final macroDeltas = [
      logged.macros.proteinG.toDouble() - planned.macros.proteinG.toDouble(),
      logged.macros.carbsG.toDouble() - planned.macros.carbsG.toDouble(),
      logged.macros.fatG.toDouble() - planned.macros.fatG.toDouble(),
    ];
    final macroTargets = [
      planned.macros.proteinG.toDouble(),
      planned.macros.carbsG.toDouble(),
      planned.macros.fatG.toDouble(),
    ];

    var bestMagnitude = -1.0;
    var bestSign = 0.0;
    for (var i = 0; i < macroDeltas.length; i++) {
      final delta = macroDeltas[i];
      final target = macroTargets[i];
      final magnitude = target == 0
          ? (delta == 0 ? 0.0 : double.infinity)
          : delta.abs() / target.abs();
      if (magnitude > bestMagnitude) {
        bestMagnitude = magnitude;
        bestSign = delta;
      }
    }

    return bestSign > 0 ? DayAdherenceStatus.over : DayAdherenceStatus.under;
  }

  static NutritionTarget _sum(List<NutritionEntry> entries) {
    var kcal = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    for (final entry in entries) {
      kcal += entry.energy.kcal.toDouble();
      protein += entry.macros.proteinG.toDouble();
      carbs += entry.macros.carbsG.toDouble();
      fat += entry.macros.fatG.toDouble();
    }
    return NutritionTarget(
      energy: Energy(kcal: kcal),
      macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
    );
  }
}
