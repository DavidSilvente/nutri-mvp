import 'package:nutri_mvp/core/result.dart';

import '../entities/meal_component.dart';
import '../failures/nutrition_failure.dart';
import '../value_objects/logged_ingredient.dart';
import '../value_objects/nutrition_target.dart';
import 'food_catalog.dart';

/// A composition and the target it produces, bundled as ONE value — so no
/// caller can pair a composition with a target it did not derive. Produced by
/// [DerivedTargets.compose] and consumed by each entity's `.composed` factory
/// (e.g. `NutritionEntry.composed`).
class DerivedComposition {
  DerivedComposition({
    required this.target,
    required List<LoggedIngredient> ingredients,
    required Set<String> unresolvedFoodIds,
  }) : ingredients = List.unmodifiable(ingredients),
       unresolvedFoodIds = Set.unmodifiable(unresolvedFoodIds);

  final NutritionTarget target;

  /// Every ingredient [DerivedTargets.compose] was given, in order, verbatim
  /// — unresolved ones included. Never dropped.
  final List<LoggedIngredient> ingredients;

  /// The `foodId`s in [ingredients] the catalog could not resolve. Empty when
  /// every ingredient resolved.
  final Set<String> unresolvedFoodIds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DerivedComposition) return false;
    if (other.target != target ||
        other.ingredients.length != ingredients.length ||
        other.unresolvedFoodIds.length != unresolvedFoodIds.length) {
      return false;
    }
    for (var i = 0; i < ingredients.length; i++) {
      if (other.ingredients[i] != ingredients[i]) return false;
    }
    return other.unresolvedFoodIds.containsAll(unresolvedFoodIds);
  }

  @override
  int get hashCode => Object.hash(
    target,
    Object.hashAll(ingredients),
    Object.hashAllUnordered(unresolvedFoodIds),
  );

  @override
  String toString() =>
      'DerivedComposition(target: $target, ingredients: $ingredients, '
      'unresolvedFoodIds: $unresolvedFoodIds)';
}

/// The choices in force when resolving which [ComponentOption] applies,
/// layered by specificity: a choice made for one calendar day beats a stored
/// user preference, which beats the plan's own first choice.
///
/// Both maps are component id -> option id. An id naming an option the
/// component does not carry is treated as ABSENT at that level rather than as
/// an error, so a stale choice (e.g. after the plan is re-imported, or from a
/// diet that has since changed) cannot break resolution — it simply falls
/// through to the next level.
class OptionChoices {
  const OptionChoices({
    this.daySelections = const {},
    this.preferences = const {},
  });

  /// No choice at either level: every component resolves to its plan default.
  const OptionChoices.none() : this();

  /// Day-scoped choices only, with no user-level preference layer — the shape
  /// resolution had before preferences existed.
  const OptionChoices.day(Map<String, String> daySelections)
    : this(daySelections: daySelections);

  /// Recorded for one specific calendar day.
  final Map<String, String> daySelections;

  /// The user's standing default, independent of any single day.
  final Map<String, String> preferences;
}

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
    final option = optionFor(component, OptionChoices.day(selections));
    final food = catalog.byId(option.foodId);
    if (food == null) {
      return Err(UnknownFoodFailure({option.foodId}));
    }
    return Ok(food.targetFor(option.quantity));
  }

  /// The option that applies to [component] given [choices], resolved by
  /// [OptionChoices]' precedence: day selection, then preference, then the
  /// plan's first choice.
  static ComponentOption optionFor(
    MealComponent component,
    OptionChoices choices,
  ) {
    return _resolve(component, choices.daySelections) ??
        _resolve(component, choices.preferences) ??
        component.defaultOption;
  }

  /// The option [selections] names for [component], or `null` when [component]
  /// has no entry, or the entry names an option [component] does not carry.
  static ComponentOption? _resolve(
    MealComponent component,
    Map<String, String> selections,
  ) {
    final selectedId = selections[component.id];
    if (selectedId == null) return null;
    for (final option in component.options) {
      if (option.id == selectedId) return option;
    }
    return null;
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
    final choices = OptionChoices.day(selections);
    final targets = <NutritionTarget>[];
    final unresolved = <String>{};
    for (final component in components) {
      final option = optionFor(component, choices);
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
    final choices = OptionChoices.day(selections);
    for (final component in components) {
      final option = optionFor(component, choices);
      final food = catalog.byId(option.foodId);
      if (food != null && food.source.needsReview) return true;
    }
    return false;
  }

  /// Derives a target from a user's own logged/saved [ingredients].
  ///
  /// This NEVER FAILS — unlike [forComponent]/[forComponents], which back
  /// PLANNED, dietitian-authored data: an unresolved food there is an
  /// authoring defect the reviewer must see and fix before the plan is
  /// usable, so hard-failing with [UnknownFoodFailure] is correct for them.
  /// `compose` backs the USER's OWN logged or saved data instead: the food
  /// existed when it was picked and may simply be missing from the CURRENT
  /// bundled catalog (an asset update, not a user mistake). Blocking or
  /// dropping data here would punish the user for a change outside their
  /// control, so an unresolved [LoggedIngredient] contributes ZERO to the
  /// returned target, is added to [DerivedComposition.unresolvedFoodIds], and
  /// survives verbatim in [DerivedComposition.ingredients] — it is never
  /// dropped and never blocks the caller.
  static DerivedComposition compose(
    List<LoggedIngredient> ingredients,
    FoodCatalog catalog,
  ) {
    final targets = <NutritionTarget>[];
    final unresolved = <String>{};
    for (final ingredient in ingredients) {
      final food = catalog.byId(ingredient.foodId);
      if (food == null) {
        unresolved.add(ingredient.foodId);
        continue;
      }
      targets.add(food.targetFor(ingredient.quantity));
    }
    return DerivedComposition(
      target: NutritionTarget.sum(targets),
      ingredients: ingredients,
      unresolvedFoodIds: unresolved,
    );
  }
}
