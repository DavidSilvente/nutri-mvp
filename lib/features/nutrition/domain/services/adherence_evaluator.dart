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
/// The three "settled" outcomes ([complete], [partial], [missed]) describe a
/// day whose plan can still be judged; [upcoming] and [inProgress] describe a
/// day that has not had its chance yet and MUST NOT be rendered as a failure.
enum DayAdherenceStatus {
  /// No meals were planned for this day — nothing to adhere to.
  unplanned,

  /// The day lies in the future: the plan exists but cannot be judged yet.
  upcoming,

  /// The day is the reference day and its plan is not fully met yet.
  inProgress,

  /// Every planned meal is [MealAdherenceStatus.onTarget].
  complete,

  /// At least one planned meal was met, but not all of them.
  partial,

  /// A settled day where no planned meal was met.
  missed,
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
    required this.status,
  });

  final NutritionDay day;

  /// Per-meal results, in the order the planned meals were supplied. The
  /// caller controls that order (typically by slot position).
  final List<MealAdherence> meals;

  final DayAdherenceStatus status;

  int get plannedCount => meals.length;

  int get onTargetCount =>
      meals.where((m) => m.status == MealAdherenceStatus.onTarget).length;

  /// Fraction of planned meals met, in `[0, 1]`. A day with no planned meals
  /// yields 0 rather than dividing by zero.
  double get completionRatio =>
      plannedCount == 0 ? 0 : onTargetCount / plannedCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DayAdherence) return false;
    if (other.day != day ||
        other.status != status ||
        other.meals.length != meals.length) {
      return false;
    }
    for (var i = 0; i < meals.length; i++) {
      if (other.meals[i] != meals[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(day, Object.hashAll(meals), status);

  @override
  String toString() =>
      'DayAdherence(day: $day, status: $status, '
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
  /// is [DayAdherenceStatus.inProgress] until its plan is fully met. Day
  /// status is always DERIVED here, never stored.
  static DayAdherence evaluateDay({
    required NutritionDay day,
    required List<PlannedMeal> plannedMeals,
    required List<NutritionEntry> entries,
    required NutritionDay today,
    AdherenceTolerance tolerance = AdherenceTolerance.standard,
  }) {
    final meals = plannedMeals
        .map(
          (meal) =>
              evaluateMeal(meal: meal, entries: entries, tolerance: tolerance),
        )
        .toList(growable: false);

    return DayAdherence(
      day: day,
      meals: meals,
      status: _dayStatus(day: day, today: today, meals: meals),
    );
  }

  static DayAdherenceStatus _dayStatus({
    required NutritionDay day,
    required NutritionDay today,
    required List<MealAdherence> meals,
  }) {
    if (meals.isEmpty) return DayAdherenceStatus.unplanned;

    final onTarget = meals
        .where((m) => m.status == MealAdherenceStatus.onTarget)
        .length;
    if (onTarget == meals.length) return DayAdherenceStatus.complete;

    // A plan can only fail once its day is over. Judging today or tomorrow as
    // "missed" would paint the calendar red for meals not yet eaten.
    if (day.epochDay > today.epochDay) return DayAdherenceStatus.upcoming;
    if (day.epochDay == today.epochDay) return DayAdherenceStatus.inProgress;

    return onTarget == 0
        ? DayAdherenceStatus.missed
        : DayAdherenceStatus.partial;
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
