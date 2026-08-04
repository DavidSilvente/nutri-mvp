import 'package:nutri_mvp/core/result.dart';

import '../entities/diet_plan.dart';
import '../entities/food_item.dart';
import '../entities/meal_component.dart';
import '../entities/stored_diet_plan.dart';
import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_decoder.dart';
import '../ports/diet_plan_store.dart';
import '../ports/food_table_source.dart';
import '../services/derived_targets.dart';
import '../services/food_catalog.dart';
import '../value_objects/nutrition_day.dart';
import '../value_objects/nutrition_target.dart';

/// One element of a meal on a specific day, with its chosen option resolved.
class DietDayComponent {
  DietDayComponent({
    required this.componentId,
    required this.sectionLabel,
    required this.options,
    required this.chosen,
    required this.food,
    required this.target,
    required this.isDeviation,
  });

  final String componentId;
  final String? sectionLabel;

  /// Every interchangeable option, in the dietitian's preference order.
  final List<ComponentOption> options;

  /// The option in force for this day.
  final ComponentOption chosen;

  /// The food [chosen] resolves to.
  final FoodItem food;

  /// Macros for [chosen] at its quantity.
  final NutritionTarget target;

  /// Whether [chosen] differs from the plan's first choice, i.e. the user
  /// actively swapped it for this day.
  final bool isDeviation;

  bool get hasAlternatives => options.length > 1;

  /// Whether the macros shown here rest on an estimate the user should check.
  bool get needsReview => food.source.needsReview;
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
    required FoodTableSource foodTable,
    required DietPlanDecoder decoder,
  })  : _store = store,
        _foodTable = foodTable,
        _decoder = decoder;

  final DietPlanStore _store;
  final FoodTableSource _foodTable;
  final DietPlanDecoder _decoder;

  Future<Result<DietDay?, NutritionFailure>> call(NutritionDay day) async {
    final activePlan = await _store.activePlan();
    final StoredDietPlan active;
    switch (activePlan) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final plan):
        if (plan == null) return const Ok(null);
        active = plan;
    }

    final foods = await _foodTable.loadFoods();
    final FoodCatalog baseCatalog;
    switch (foods) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final items):
        baseCatalog = FoodCatalog(items);
    }

    final decoded = _decoder.decode(
      active.document,
      baseCatalog: baseCatalog,
      planId: active.id,
      isDefault: true,
      sourceLabel: active.sourceLabel,
    );
    final DecodedDietPlan plan;
    switch (decoded) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
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

    return _assemble(
      day: day,
      plan: plan.plan,
      group: group,
      catalog: plan.catalog,
      selections: selections,
    );
  }

  Result<DietDay?, NutritionFailure> _assemble({
    required NutritionDay day,
    required DietPlan plan,
    required DietPlanDayGroup group,
    required FoodCatalog catalog,
    required Map<String, String> selections,
  }) {
    final meals = <DietDayMeal>[];
    final unresolved = <String>{};

    for (final slot in group.template.slots) {
      final components = <DietDayComponent>[];
      for (final component in slot.components) {
        final chosen = DerivedTargets.optionFor(component, selections);
        final food = catalog.byId(chosen.foodId);
        if (food == null) {
          unresolved.add(chosen.foodId);
          continue;
        }
        components.add(DietDayComponent(
          componentId: component.id,
          sectionLabel: component.sectionLabel,
          options: component.options,
          chosen: chosen,
          food: food,
          target: food.targetFor(chosen.quantity),
          isDeviation: chosen.id != component.defaultOption.id,
        ));
      }
      meals.add(DietDayMeal(
        slotId: slot.id,
        label: slot.label,
        timeOfDay: slot.timeOfDay,
        components: components,
        target: NutritionTarget.sum(components.map((c) => c.target)),
        notes: slot.notes,
      ));
    }

    if (unresolved.isNotEmpty) {
      return Err(UnknownFoodFailure(unresolved));
    }

    return Ok(DietDay(
      day: day,
      planId: plan.id,
      planName: plan.name,
      dayGroupLabel: group.label,
      meals: meals,
      // Summed from the day's meals rather than read off the template, so a
      // swapped alternative is reflected in the day total immediately.
      target: NutritionTarget.sum(meals.map((meal) => meal.target)),
      declaredDailyEnergyKcal: plan.declaredDailyEnergyKcal,
    ));
  }
}
