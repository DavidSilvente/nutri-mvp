import 'package:nutri_mvp/core/result.dart';

import '../entities/meal_component.dart';
import '../failures/nutrition_failure.dart';
import '../value_objects/nutrition_target.dart';
import 'food_catalog.dart';

/// Derives nutritional targets from foods and quantities.
///
/// This is the piece that makes the model food-first: no macro figure in a
/// component-backed plan is entered by hand, every one is computed from a
/// [FoodCatalog] entry scaled by a quantity. Change the grams and the numbers
/// follow, which is exactly what hand-entered targets could never do.
class DerivedTargets {
  const DerivedTargets._();

  /// The target for [component], using [selections] to pick an option.
  ///
  /// [selections] maps a component id to a chosen option id. A component with
  /// no entry falls back to its [MealComponent.defaultOption]; an entry naming
  /// an option the component does not carry is IGNORED rather than treated as
  /// an error, so a stale selection (e.g. after the plan is re-imported) cannot
  /// break the day view.
  static Result<NutritionTarget, NutritionFailure> forComponent(
    MealComponent component,
    FoodCatalog catalog, {
    Map<String, String> selections = const {},
  }) {
    final option = optionFor(component, selections);
    final food = catalog.byId(option.foodId);
    if (food == null) {
      return Err(UnknownFoodFailure({option.foodId}));
    }
    return Ok(food.targetFor(option.quantity));
  }

  /// The option that applies to [component] given [selections].
  static ComponentOption optionFor(
    MealComponent component,
    Map<String, String> selections,
  ) {
    final selectedId = selections[component.id];
    if (selectedId == null) return component.defaultOption;
    for (final option in component.options) {
      if (option.id == selectedId) return option;
    }
    return component.defaultOption;
  }

  /// The summed target for [components].
  ///
  /// Reports every unresolved food id at once instead of failing on the first,
  /// so an import can show the user the complete list of gaps.
  static Result<NutritionTarget, NutritionFailure> forComponents(
    Iterable<MealComponent> components,
    FoodCatalog catalog, {
    Map<String, String> selections = const {},
  }) {
    final targets = <NutritionTarget>[];
    final unresolved = <String>{};
    for (final component in components) {
      final option = optionFor(component, selections);
      final food = catalog.byId(option.foodId);
      if (food == null) {
        unresolved.add(option.foodId);
        continue;
      }
      targets.add(food.targetFor(option.quantity));
    }
    if (unresolved.isNotEmpty) {
      return Err(UnknownFoodFailure(unresolved));
    }
    return Ok(NutritionTarget.sum(targets));
  }

  /// Whether any option reachable from [components] resolves to a food whose
  /// value is only an estimate, meaning the totals shown are approximate.
  static bool hasEstimatedFoods(
    Iterable<MealComponent> components,
    FoodCatalog catalog, {
    Map<String, String> selections = const {},
  }) {
    for (final component in components) {
      final option = optionFor(component, selections);
      final food = catalog.byId(option.foodId);
      if (food != null && food.source.needsReview) return true;
    }
    return false;
  }
}
