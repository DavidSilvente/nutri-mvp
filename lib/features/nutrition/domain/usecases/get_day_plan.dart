import 'package:nutri_mvp/core/result.dart';

import '../entities/meal_component.dart';
import '../entities/nutrition_entry.dart';
import '../entities/planned_meal.dart';
import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_source.dart';
import '../ports/meal_slot_directory.dart';
import '../ports/nutrition_health_source.dart';
import '../ports/option_choice_source.dart';
import '../services/adherence_evaluator.dart';
import '../services/derived_targets.dart';
import '../services/meal_slot_index.dart';
import '../services/resolved_component.dart';
import '../value_objects/adherence_tolerance.dart';
import '../value_objects/energy.dart';
import '../value_objects/macros.dart';
import '../value_objects/nutrition_day.dart';
import '../value_objects/nutrition_target.dart';

/// A planned meal with everything the UI needs to render one row: its label,
/// its position in the day, its adherence result, its resolved food, and the
/// entries behind it.
class PlannedMealDetail {
  const PlannedMealDetail({
    required this.meal,
    required this.label,
    required this.position,
    required this.adherence,
    required this.entries,
    this.components = const [],
    this.timeOfDay,
    this.notes = const [],
  });

  final PlannedMeal meal;
  final String label;
  final int position;
  final MealAdherence adherence;

  /// The entries logged against this meal, in recording order.
  final List<NutritionEntry> entries;

  /// The meal's food, resolved against the day's chosen options. Empty when
  /// the meal's slot no longer exists in the active diet, or when it never
  /// carried components (a hand-entered slot).
  final List<ResolvedComponent> components;

  /// The time the plan scheduled this meal for, as `HH:mm`, when it gave one
  /// and the slot still exists.
  final String? timeOfDay;

  /// Free-text guidance the source plan attached to this meal.
  final List<String> notes;

  MealAdherenceStatus get status => adherence.status;
  NutritionTarget get target => meal.targetSnapshot;
  NutritionTarget get logged => adherence.logged;

  @override
  String toString() =>
      'PlannedMealDetail(label: $label, position: $position, '
      'status: ${adherence.status})';
}

/// Everything that happened, and was supposed to happen, on one day.
class DayPlan {
  const DayPlan({
    required this.day,
    required this.meals,
    required this.adherence,
    required this.unplannedEntries,
    required this.loggedTotal,
  });

  final NutritionDay day;

  /// Planned meals ordered by slot position.
  final List<PlannedMealDetail> meals;

  final DayAdherence adherence;

  /// Entries with no planned meal attached. They count towards [loggedTotal]
  /// but never towards adherence.
  final List<NutritionEntry> unplannedEntries;

  /// Sum of EVERY entry of the day, planned or not — what the user actually
  /// ate, as opposed to what the plan asked for.
  final NutritionTarget loggedTotal;

  /// Sum of the targets of every planned meal: the day's intended intake.
  NutritionTarget get plannedTotal =>
      NutritionTarget.sum(meals.map((m) => m.target));

  DayAdherenceStatus get status => adherence.status;
  bool get hasPlan => meals.isNotEmpty;

  @override
  String toString() =>
      'DayPlan(day: $day, meals: ${meals.length}, status: $status)';
}

/// Assembles the full picture of a single day: its planned meals, what was
/// logged against each of them, and how well the two match.
///
/// Reads from both ports because a day is inherently a join of the plan
/// (diet source) and reality (nutrition source). The [today] argument is
/// supplied by the caller rather than read from the clock, so the result is
/// deterministic and past days can be evaluated without drift.
///
/// Meal names and ordering come from the active diet, through
/// [MealSlotDirectory]. A planned meal only stores a slot id and the target it
/// was committed to, so the diet is what turns it back into "Breakfast, first
/// meal of the day".
class GetDayPlan {
  GetDayPlan({
    required DietPlanSource dietPlanSource,
    required NutritionHealthSource nutritionSource,
    required MealSlotDirectory slotDirectory,
    required OptionChoiceSource choiceSource,
    this.tolerance = AdherenceTolerance.standard,
  }) : _dietPlanSource = dietPlanSource,
       _nutritionSource = nutritionSource,
       _slotDirectory = slotDirectory,
       _choiceSource = choiceSource;

  final DietPlanSource _dietPlanSource;
  final NutritionHealthSource _nutritionSource;
  final MealSlotDirectory _slotDirectory;
  final OptionChoiceSource _choiceSource;
  final AdherenceTolerance tolerance;

  Future<Result<DayPlan, NutritionFailure>> call(
    NutritionDay day, {
    required NutritionDay today,
  }) async {
    final slotsResult = await _slotDirectory.activeSlots();
    if (slotsResult case Err(failure: final failure)) return Err(failure);

    final plannedResult = await _dietPlanSource.listPlannedMeals(day: day);
    if (plannedResult case Err(failure: final failure)) return Err(failure);

    final entriesResult = await _nutritionSource.entriesOn(day);
    if (entriesResult case Err(failure: final failure)) return Err(failure);

    // One call for the whole day, not per meal or per component: the choices
    // in force do not vary within a day.
    final choicesResult = await _choiceSource.choicesFor(day);
    if (choicesResult case Err(failure: final failure)) return Err(failure);

    final index = (slotsResult as Ok).value as MealSlotIndex;
    final plannedMeals = (plannedResult as Ok).value as List<PlannedMeal>;
    final entries = (entriesResult as Ok).value as List<NutritionEntry>;
    final choices = (choicesResult as Ok).value as OptionChoices;

    final ordered = [...plannedMeals]
      ..sort(
        (a, b) =>
            index.positionOf(a.slotId).compareTo(index.positionOf(b.slotId)),
      );

    final dayAdherence = AdherenceEvaluator.evaluateDay(
      day: day,
      plannedMeals: ordered,
      entries: entries,
      today: today,
      tolerance: tolerance,
    );

    final details = [
      for (var i = 0; i < ordered.length; i++)
        PlannedMealDetail(
          meal: ordered[i],
          label: index.labelOf(ordered[i].slotId),
          position: index.positionOf(ordered[i].slotId),
          adherence: dayAdherence.meals[i],
          entries: entries
              .where((e) => e.plannedMealId == ordered[i].id)
              .toList(growable: false),
          components: _resolveComponents(index, ordered[i].slotId, choices),
          timeOfDay: index[ordered[i].slotId]?.timeOfDay,
          notes: index[ordered[i].slotId]?.notes ?? const [],
        ),
    ];

    final plannedIds = ordered.map((m) => m.id).toSet();

    return Ok(
      DayPlan(
        day: day,
        meals: details,
        adherence: dayAdherence,
        unplannedEntries: entries
            .where(
              (e) =>
                  e.plannedMealId == null ||
                  !plannedIds.contains(e.plannedMealId),
            )
            .toList(growable: false),
        loggedTotal: _sum(entries),
      ),
    );
  }

  /// The resolved food for [slotId], or an empty list when the slot no longer
  /// exists in the active diet or never carried components — the same
  /// degradation [MealSlotIndex.labelOf] already applies to a deleted slot's
  /// label.
  List<ResolvedComponent> _resolveComponents(
    MealSlotIndex index,
    String slotId,
    OptionChoices choices,
  ) {
    final components = index[slotId]?.components ?? const [];
    return [
      for (final component in components) _resolve(component, index, choices),
    ];
  }

  ResolvedComponent _resolve(
    MealComponent component,
    MealSlotIndex index,
    OptionChoices choices,
  ) {
    final chosen = DerivedTargets.optionFor(component, choices);
    return ResolvedComponent(
      componentId: component.id,
      sectionLabel: component.sectionLabel,
      options: component.options,
      chosen: chosen,
      isDeviation: chosen.id != component.defaultOption.id,
      needsReview: index.estimatedFoodIds.contains(chosen.foodId),
    );
  }

  NutritionTarget _sum(List<NutritionEntry> entries) {
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
