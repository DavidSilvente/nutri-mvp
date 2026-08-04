import 'package:nutri_mvp/core/result.dart';

import '../entities/diet_plan.dart';
import '../entities/food_item.dart';
import '../entities/meal_component.dart';
import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_decoder.dart';
import '../ports/diet_plan_store.dart';
import '../services/derived_targets.dart';
import '../services/food_catalog.dart';
import '../services/resolved_component.dart';
import '../value_objects/nutrition_day.dart';
import '../value_objects/nutrition_target.dart';
import 'resolve_active_diet.dart';

/// One element of a meal on a specific day, with its chosen option resolved.
///
/// Composes [ResolvedComponent] rather than duplicating its fields, so this
/// pipeline and `GetDayPlan`'s share one definition of "resolved" and the
/// options sheet (which reaches both screens) can take a single input type.
/// `food`/`target` stay here rather than on [ResolvedComponent] itself: they
/// need a [FoodCatalog], which the month-scale pipeline that also builds
/// [ResolvedComponent] must not pay for.
class DietDayComponent {
  DietDayComponent({
    required this.resolved,
    required this.food,
    required this.target,
  });

  final ResolvedComponent resolved;

  /// The food [resolved.chosen] resolves to.
  final FoodItem food;

  /// Macros for [resolved.chosen] at its quantity.
  final NutritionTarget target;

  String get componentId => resolved.componentId;
  String? get sectionLabel => resolved.sectionLabel;

  /// Every interchangeable option, in the dietitian's preference order.
  List<ComponentOption> get options => resolved.options;

  /// The option in force for this day.
  ComponentOption get chosen => resolved.chosen;

  /// Whether [chosen] differs from the plan's first choice, i.e. the user
  /// actively swapped it for this day.
  bool get isDeviation => resolved.isDeviation;

  bool get hasAlternatives => resolved.hasAlternatives;

  /// Whether the macros shown here rest on an estimate the user should check.
  bool get needsReview => resolved.needsReview;
}

/// A meal on a specific day.
class DietDayMeal {
  DietDayMeal({
    required this.slotId,
    required this.label,
    required this.timeOfDay,
    required this.components,
    required this.target,
    required this.notes,
  });

  final String slotId;
  final String label;
  final String? timeOfDay;
  final List<DietDayComponent> components;

  /// Sum of this meal's component targets.
  final NutritionTarget target;
  final List<String> notes;

  bool get needsReview => components.any((c) => c.needsReview);
}

/// What the user's active diet prescribes for one calendar day.
class DietDay {
  DietDay({
    required this.day,
    required this.planId,
    required this.planName,
    required this.dayGroupLabel,
    required this.meals,
    required this.target,
    required this.declaredDailyEnergyKcal,
  });

  final NutritionDay day;
  final String planId;
  final String planName;

  /// The plan's own wording for the group this day falls in, e.g. `LU Y VI`.
  final String dayGroupLabel;

  final List<DietDayMeal> meals;

  /// Sum of the day's meals — the honest derived figure.
  final NutritionTarget target;

  /// The headline the source plan advertised, for display next to [target].
  final num? declaredDailyEnergyKcal;

  bool get needsReview => meals.any((meal) => meal.needsReview);

  /// Signed difference between what this day actually adds up to and the plan's
  /// headline, or null when the plan stated none.
  num? get declaredEnergyDelta => declaredDailyEnergyKcal == null
      ? null
      : target.energy.kcal - declaredDailyEnergyKcal!;
}

/// Reads the day the user is looking at out of their ACTIVE diet.
///
/// Returns `Ok(null)` when there is no active diet or when the active plan says
/// nothing about that weekday. Both are ordinary states — no diet imported yet,
/// or a plan that only covers weekdays — not failures, so the UI can show an
/// empty state instead of an error.
class GetDietDay {
  GetDietDay({
    required DietPlanStore store,
    required ResolveActiveDiet activeDiet,
  }) : _store = store,
       _activeDiet = activeDiet;

  final DietPlanStore _store;
  final ResolveActiveDiet _activeDiet;

  Future<Result<DietDay?, NutritionFailure>> call(NutritionDay day) async {
    final resolved = await _activeDiet();
    final DecodedDietPlan plan;
    switch (resolved) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        if (value == null) return const Ok(null);
        plan = value;
    }

    final group = plan.plan.groupForWeekday(day.weekday);
    if (group == null) return const Ok(null);

    final selectionsResult = await _store.selectionsFor(day);
    final Map<String, String> selections;
    switch (selectionsResult) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        selections = value;
    }

    // Resolves all 3 precedence levels (day > preference > plan default), the
    // same rule `GetDayPlan` already applies. Before this, only the day level
    // was read here, so a standing preference set from the day plan screen
    // silently had no effect on this screen for the same day.
    //
    // This still goes through `DietPlanStore` directly rather than the
    // `OptionChoiceSource` port `GetDayPlan` uses — migrating fully onto that
    // port is a deliberate follow-up, out of scope for this fix (see the
    // day-shows-planned-food design notes).
    final preferencesResult = await _store.preferredOptions();
    final Map<String, String> preferences;
    switch (preferencesResult) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        preferences = value;
    }

    return _assemble(
      day: day,
      plan: plan.plan,
      group: group,
      catalog: plan.catalog,
      choices: OptionChoices(
        daySelections: selections,
        preferences: preferences,
      ),
    );
  }

  Result<DietDay?, NutritionFailure> _assemble({
    required NutritionDay day,
    required DietPlan plan,
    required DietPlanDayGroup group,
    required FoodCatalog catalog,
    required OptionChoices choices,
  }) {
    final meals = <DietDayMeal>[];
    final unresolved = <String>{};

    for (final slot in group.template.slots) {
      final components = <DietDayComponent>[];
      for (final component in slot.components) {
        final chosen = DerivedTargets.optionFor(component, choices);
        final food = catalog.byId(chosen.foodId);
        if (food == null) {
          unresolved.add(chosen.foodId);
          continue;
        }
        components.add(
          DietDayComponent(
            resolved: ResolvedComponent(
              componentId: component.id,
              sectionLabel: component.sectionLabel,
              options: component.options,
              chosen: chosen,
              isDeviation: chosen.id != component.defaultOption.id,
              needsReview: food.source.needsReview,
            ),
            food: food,
            target: food.targetFor(chosen.quantity),
          ),
        );
      }
      meals.add(
        DietDayMeal(
          slotId: slot.id,
          label: slot.label,
          timeOfDay: slot.timeOfDay,
          components: components,
          target: NutritionTarget.sum(components.map((c) => c.target)),
          notes: slot.notes,
        ),
      );
    }

    if (unresolved.isNotEmpty) {
      return Err(UnknownFoodFailure(unresolved));
    }

    return Ok(
      DietDay(
        day: day,
        planId: plan.id,
        planName: plan.name,
        dayGroupLabel: group.label,
        meals: meals,
        // Summed from the day's meals rather than read off the template, so a
        // swapped alternative is reflected in the day total immediately.
        target: NutritionTarget.sum(meals.map((meal) => meal.target)),
        declaredDailyEnergyKcal: plan.declaredDailyEnergyKcal,
      ),
    );
  }
}
