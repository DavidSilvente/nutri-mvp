import 'dart:convert';

import 'package:nutri_mvp/core/result.dart';

import '../../domain/entities/diet_plan.dart';
import '../../domain/entities/diet_template.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal_component.dart';
import '../../domain/failures/nutrition_failure.dart';
import '../../domain/ports/diet_plan_decoder.dart';
import '../../domain/services/food_catalog.dart';
import '../../domain/value_objects/energy.dart';
import '../../domain/value_objects/food_quantity.dart';
import '../../domain/value_objects/macros.dart';
import '../../domain/value_objects/nutrition_target.dart';
import 'json_reader.dart';

/// Reads a structured diet plan document into a [DietPlan] with derived macros.
///
/// The document is the normalized output of an import (see `DietPdfImporter`):
/// day groups, meals, and per-item alternatives, with each alternative naming a
/// food and a quantity. No macro figures appear in it — they are all derived
/// here from the food catalog.
class DietPlanCodec implements DietPlanDecoder {
  const DietPlanCodec();

  static const int supportedSchemaVersion = 1;

  /// Decodes [source], resolving foods against [baseCatalog] plus any recipes
  /// the document defines.
  ///
  /// [planId] namespaces every generated id. Ids are DERIVED FROM POSITION
  /// (`<planId>:g0:m2:c1:o3`) rather than random, so re-importing the same
  /// document yields the same ids and a user's saved alternative choices keep
  /// pointing at the right component instead of being orphaned.
  @override
  Result<DecodedDietPlan, NutritionFailure> decode(
    String source, {
    required FoodCatalog baseCatalog,
    required String planId,
    bool isDefault = false,
    String? sourceLabel,
  }) {
    final Object? raw;
    try {
      raw = jsonDecode(source);
    } on FormatException catch (error) {
      return Err(MalformedPlanFailure('plan is not valid JSON: '
          '${error.message}'));
    }

    final JsonReader root;
    final JsonReader diet;
    final List<FoodItem> recipes;
    try {
      root = JsonReader.object(raw, 'plan');
      final version = root.integer('schemaVersion');
      if (version != supportedSchemaVersion) {
        return Err(MalformedPlanFailure(
          'unsupported plan schemaVersion $version, '
          'expected $supportedSchemaVersion',
        ));
      }
      diet = root.child('diet');
      recipes = _recipes(diet);
    } on JsonReadException catch (error) {
      return Err(MalformedPlanFailure(error.message));
    } on ArgumentError catch (error) {
      return Err(MalformedPlanFailure('invalid plan value: ${error.message}'));
    }

    // Plan recipes win over generic table entries: they are what this plan
    // actually prescribes, computed by its author.
    final catalog = baseCatalog.withOverrides(recipes);

    final List<DietPlanDayGroup> groups;
    try {
      final result = _dayGroups(diet, catalog, planId);
      switch (result) {
        case Err(failure: final failure):
          return Err(failure);
        case Ok(value: final value):
          groups = value;
      }
    } on JsonReadException catch (error) {
      return Err(MalformedPlanFailure(error.message));
    } on ArgumentError catch (error) {
      return Err(MalformedPlanFailure('invalid plan value: ${error.message}'));
    }

    try {
      return Ok(DecodedDietPlan(
        plan: DietPlan(
          id: planId,
          name: diet.string('name'),
          dayGroups: groups,
          declaredDailyEnergyKcal: diet.numberOrNull('declaredDailyEnergyKcal'),
          isDefault: isDefault,
          sourceLabel: sourceLabel,
        ),
        catalog: catalog,
      ));
    } on JsonReadException catch (error) {
      return Err(MalformedPlanFailure(error.message));
    } on ArgumentError catch (error) {
      return Err(MalformedPlanFailure('invalid plan value: ${error.message}'));
    }
  }

  static List<FoodItem> _recipes(JsonReader diet) {
    if (!diet.has('recipes')) return const [];
    return [
      for (final recipe in diet.objectList('recipes'))
        _recipeFood(recipe),
    ];
  }

  static FoodItem _recipeFood(JsonReader recipe) {
    final per100g = recipe.child('per100g');
    return FoodItem(
      id: recipe.string('id'),
      name: recipe.string('name'),
      // A recipe is a prepared dish; its table already reflects that state.
      preparation: FoodPreparation.cooked,
      per100g: NutritionTarget(
        energy: Energy(kcal: per100g.number('energyKcal')),
        macros: Macros(
          proteinG: per100g.number('proteinG'),
          carbsG: per100g.number('carbsG'),
          fatG: per100g.number('fatG'),
        ),
      ),
      source: FoodDataSource.planRecipe,
      sourceRef: recipe.has('page') ? 'page ${recipe.integer('page')}' : null,
    );
  }

  static Result<List<DietPlanDayGroup>, NutritionFailure> _dayGroups(
    JsonReader diet,
    FoodCatalog catalog,
    String planId,
  ) {
    final groups = <DietPlanDayGroup>[];
    final groupReaders = diet.objectList('dayGroups');
    for (var g = 0; g < groupReaders.length; g++) {
      final groupReader = groupReaders[g];
      final slots = <DietMealSlot>[];
      final mealReaders = groupReader.objectList('meals');

      for (var m = 0; m < mealReaders.length; m++) {
        final mealReader = mealReaders[m];
        final components = _components(mealReader, '$planId:g$g:m$m');
        final slot = DietMealSlot.derived(
          id: '$planId:g$g:m$m',
          label: mealReader.string('label'),
          position: m,
          components: components,
          catalog: catalog,
          timeOfDay: mealReader.stringOrNull('time'),
          notes: mealReader.stringList('notes'),
        );
        switch (slot) {
          case Err(failure: final failure):
            return Err(failure);
          case Ok(value: final value):
            slots.add(value);
        }
      }

      groups.add(DietPlanDayGroup(
        label: groupReader.string('label'),
        weekdays: groupReader.integerList('weekdays').toSet(),
        template: DietTemplate.derived(
          id: '$planId:g$g',
          name: '${diet.string('name')} — ${groupReader.string('label')}',
          slots: slots,
          declaredDailyEnergyKcal: diet.numberOrNull(
            'declaredDailyEnergyKcal',
          ),
        ),
      ));
    }
    return Ok(groups);
  }

  static List<MealComponent> _components(JsonReader meal, String slotId) {
    final components = <MealComponent>[];
    var position = 0;
    for (final section in meal.objectList('sections')) {
      final sectionLabel = section.stringOrNull('label');
      for (final component in section.objectList('components')) {
        final componentId = '$slotId:c$position';
        final optionReaders = component.objectList('alternatives');
        components.add(MealComponent(
          id: componentId,
          position: position,
          sectionLabel: sectionLabel,
          options: [
            for (var o = 0; o < optionReaders.length; o++)
              _option(optionReaders[o], '$componentId:o$o'),
          ],
        ));
        position++;
      }
    }
    return components;
  }

  static ComponentOption _option(JsonReader option, String optionId) {
    final quantity = option.child('quantity');
    return ComponentOption(
      id: optionId,
      foodId: option.string('foodRef'),
      quantity: FoodQuantity(
        grams: quantity.number('grams'),
        count: quantity.numberOrNull('count'),
        unit: quantity.stringOrNull('unit'),
      ),
      rawText: option.string('rawText'),
    );
  }
}
