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

/// Reads a structured diet plan document into a [DietPlan], and writes a
/// hand-authored plan back out.
///
/// The document is the normalized output of an import (see `DietPdfImporter`):
/// day groups, meals, and per-item alternatives, with each alternative naming a
/// food and a quantity. For those meals no macro figures appear in the document
/// — they are all derived here from the food catalog.
///
/// A meal may instead state a `target` outright, which is how a diet typed into
/// the app is stored. Both kinds live in the same document so everything
/// downstream reads one shape regardless of where the diet came from.
class DietPlanCodec implements DietPlanDecoder, DietPlanEncoder {
  const DietPlanCodec();

  /// Versions this codec can read.
  ///
  /// v1 documents predate hand-entered meals and explicit slot ids. They keep
  /// decoding unchanged: the rules below are a superset, so a v1 document takes
  /// exactly the same path it always did.
  static const Set<int> readableSchemaVersions = {1, 2};

  /// The version [encode] writes.
  static const int supportedSchemaVersion = 2;

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
      if (!readableSchemaVersions.contains(version)) {
        return Err(MalformedPlanFailure(
          'unsupported plan schemaVersion $version, '
          'expected one of ${readableSchemaVersions.join(', ')}',
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
        // An explicit id wins over the positional one so that editing a diet —
        // inserting a meal, reordering — cannot renumber the slots underneath
        // the planned meals and selections already keyed to them. v1 documents
        // state none and keep their positional ids.
        final slotId = mealReader.stringOrNull('slotId') ?? '$planId:g$g:m$m';

        final statesTarget = mealReader.has('target');
        final statesFoods = mealReader.has('sections');
        if (statesTarget == statesFoods) {
          return Err(MalformedPlanFailure(
            'meal "$slotId" must state either "sections" or "target", '
            'and states ${statesTarget ? 'both' : 'neither'}',
          ));
        }

        if (statesTarget) {
          slots.add(DietMealSlot(
            id: slotId,
            label: mealReader.string('label'),
            position: m,
            target: _target(mealReader.child('target')),
            timeOfDay: mealReader.stringOrNull('time'),
            notes: mealReader.stringList('notes'),
          ));
          continue;
        }

        final slot = DietMealSlot.derived(
          id: slotId,
          label: mealReader.string('label'),
          position: m,
          components: _components(mealReader, slotId),
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

  static NutritionTarget _target(JsonReader target) {
    return NutritionTarget(
      energy: Energy(kcal: target.number('energyKcal')),
      macros: Macros(
        proteinG: target.number('proteinG'),
        carbsG: target.number('carbsG'),
        fatG: target.number('fatG'),
      ),
    );
  }

  @override
  Result<String, NutritionFailure> encode(DietPlan plan) {
    final groups = <Map<String, Object?>>[];

    for (final group in plan.dayGroups) {
      final meals = <Map<String, Object?>>[];
      for (final slot in group.template.slots) {
        // Refused rather than approximated: a food-first slot's macros come from
        // the plan's own recipes, which live in the catalog the decode built and
        // not on the slot. Writing the numbers alone would turn a plan that
        // knows what it prescribes into one that only remembers the totals.
        if (slot.isDerived) {
          return Err(MalformedPlanFailure(
            'meal "${slot.id}" is built from foods and cannot be encoded '
            'without losing the recipes behind them',
          ));
        }
        meals.add({
          'slotId': slot.id,
          'label': slot.label,
          if (slot.timeOfDay != null) 'time': slot.timeOfDay,
          if (slot.notes.isNotEmpty) 'notes': slot.notes,
          'target': {
            'energyKcal': slot.target.energy.kcal,
            'proteinG': slot.target.macros.proteinG,
            'carbsG': slot.target.macros.carbsG,
            'fatG': slot.target.macros.fatG,
          },
        });
      }
      groups.add({
        'label': group.label,
        'weekdays': group.weekdays.toList(),
        'meals': meals,
      });
    }

    return Ok(jsonEncode({
      'schemaVersion': supportedSchemaVersion,
      'diet': {
        'name': plan.name,
        if (plan.declaredDailyEnergyKcal != null)
          'declaredDailyEnergyKcal': plan.declaredDailyEnergyKcal,
        'dayGroups': groups,
      },
    }));
  }
}
