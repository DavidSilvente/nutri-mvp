import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_plan_codec.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/food_table_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_decoder.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';

/// End-to-end check over the REAL shipped assets: the USDA-derived food table
/// and a diet plan normalized from an actual Nutrium PDF.
///
/// This is the test that keeps the whole food-first pipeline honest. It does not
/// assert on a hand-built fixture but on the data the app actually loads, so a
/// regression anywhere along the chain — food table regenerated with different
/// FDC ids, a decode bug, a quantity misread, a plan edited by hand — moves one
/// of these totals and fails here.
///
/// The expected energies are DERIVED values, not the plan's 2950 kcal headline.
/// They are pinned to catch drift; see `plan headline` group for the check that
/// they stay near what the dietitian advertised.
void main() {
  late FoodCatalog table;
  late String planSource;

  setUpAll(() {
    final tableSource = File(
      'assets/nutrition/food_table.json',
    ).readAsStringSync();
    final decodedTable = const FoodTableCodec().decode(tableSource);
    table = switch (decodedTable) {
      Ok(value: final foods) => FoodCatalog(foods),
      Err(failure: final failure) => fail(
        'food table failed to decode: $failure',
      ),
    };
    planSource = File(
      'assets/diets/nutrium_david_2950kcal.json',
    ).readAsStringSync();
  });

  DecodedDietPlan decodePlan() {
    final result = const DietPlanCodec().decode(
      planSource,
      baseCatalog: table,
      planId: 'plan-1',
      isDefault: true,
      sourceLabel: 'DAVID GALERA AJUSTE 2950KCAL.pdf',
    );
    return switch (result) {
      Ok(value: final decoded) => decoded,
      Err(failure: final failure) => fail('plan failed to decode: $failure'),
    };
  }

  group('food table asset', () {
    test('carries a large searchable pool plus the curated slugs', () {
      // The pool exists so an importer can match arbitrary plan wording; the
      // curated slugs are the ids plan documents reference directly. Asserted as
      // properties rather than an exact count, which would need an edit every
      // time the dataset is regenerated.
      expect(table.length, greaterThan(5000));
      expect(
        table.all.where((food) => food.id.startsWith('usda_')).length,
        greaterThan(5000),
      );
      for (final slug in [
        'chicken_breast_grilled',
        'rice_white_raw',
        'rice_white_boiled',
        'pasta_raw',
        'ham_serrano',
      ]) {
        expect(table.byId(slug), isNotNull, reason: slug);
      }
    });

    test('resolves each id uniquely', () {
      // FoodCatalog throws on duplicate ids, so construction already proved it;
      // this pins that curated slugs never collide with a pool id.
      final curated = table.all
          .where((food) => !food.id.startsWith('usda_'))
          .toList();
      expect(curated.length, 48);
      for (final food in curated) {
        expect(food.id.startsWith('usda_'), isFalse);
      }
    });

    test('marks only the foods with no USDA equivalent as estimated', () {
      final estimated = table.all
          .where((food) => food.source == FoodDataSource.estimated)
          .map((food) => food.id)
          .toList();
      expect(estimated, [
        'gelatin_0',
        'ham_serrano',
        'pizza_base_thin',
        'pork_loin_cured',
      ]);
    });

    test('keeps an auditable FDC reference on every table-sourced food', () {
      final tableSourced = table.all.where(
        (f) => f.source == FoodDataSource.usdaSrLegacy,
      );
      expect(tableSourced, isNotEmpty);
      for (final food in tableSourced) {
        expect(
          food.sourceRef,
          isNotNull,
          reason: '${food.id} must cite the FDC id it came from',
        );
      }
    });

    test('preserves the preparation state that drives energy density', () {
      // Losing this distinction is a ~3x error, so it is asserted explicitly.
      final raw = table.byId('rice_white_raw')!;
      final boiled = table.byId('rice_white_boiled')!;
      expect(raw.preparation, FoodPreparation.raw);
      expect(boiled.preparation, FoodPreparation.boiled);
      expect(raw.per100g.energy.kcal, greaterThan(300));
      expect(boiled.per100g.energy.kcal, lessThan(150));
    });
  });

  group('real plan decode', () {
    test('covers the whole week across four day groups', () {
      final plan = decodePlan().plan;
      expect(plan.dayGroups.map((g) => g.label).toList(), [
        'LU Y VI',
        'MA Y JU',
        'MI Y DO',
        'SÁBADO',
      ]);
      expect(plan.coversWholeWeek, isTrue);
      expect(plan.uncoveredWeekdays, isEmpty);
    });

    test('resolves every referenced food, including the plan recipes', () {
      // Reaching Ok already proves it: an unresolved id yields
      // UnknownFoodFailure. This pins the recipe override behaviour.
      final decoded = decodePlan();
      final gnocchi = decoded.catalog.byId('recipe_gnocchi');
      expect(gnocchi, isNotNull);
      expect(gnocchi!.source, FoodDataSource.planRecipe);
      expect(gnocchi.per100g.energy.kcal, 126);
    });

    test('does not confuse the two similarly named vegetable recipes', () {
      // "verduras a la parrilla" (51 kcal/100 g) and "parrillada de verduras"
      // (25 kcal/100 g) are different recipes in the same PDF. Mixing them up
      // is a silent 2x error on a component that appears in most meals.
      final catalog = decodePlan().catalog;
      expect(
        catalog.byId('recipe_grilled_vegetables')!.per100g.energy.kcal,
        51,
      );
      expect(
        catalog.byId('recipe_grilled_vegetable_platter')!.per100g.energy.kcal,
        25,
      );
    });

    test('reads a parenthesised weight as the total, not per unit', () {
      final plan = decodePlan().plan;
      // "3 unidades medianas de huevo de gallina, entero, crudo (150 g)"
      final saturday = plan.groupForWeekday(DateTime.saturday)!;
      final lunch = saturday.template.slots.firstWhere(
        (slot) => slot.label == 'COMIDA',
      );
      final eggOption = lunch.components
          .expand((component) => component.options)
          .firstWhere((option) => option.rawText.startsWith('3 unidades'));
      expect(eggOption.quantity.count, 3);
      expect(eggOption.quantity.grams, 150, reason: '150 g total, not each');
    });

    test('keeps meal times and the dietitian notes', () {
      final plan = decodePlan().plan;
      final group = plan.groupForWeekday(DateTime.tuesday)!;
      final breakfast = group.template.slots.first;
      expect(breakfast.label, 'DESAYUNO');
      expect(breakfast.timeOfDay, '07:30');
      expect(breakfast.notes.single, contains('remojo'));
    });

    test('derives every slot target from its components', () {
      final plan = decodePlan().plan;
      for (final group in plan.dayGroups) {
        for (final slot in group.template.slots) {
          expect(slot.isDerived, isTrue, reason: '${slot.id} must be derived');
          expect(slot.target.energy.kcal, greaterThan(0));
        }
      }
    });

    test('groups alternatives per item, not per meal', () {
      final plan = decodePlan().plan;
      final monday = plan.groupForWeekday(DateTime.monday)!;
      final lunch = monday.template.slots.firstWhere(
        (slot) => slot.label == 'COMIDA',
      );
      // The protein has four interchangeable options while the side dish has
      // its own separate four — that is the whole point of per-item swaps.
      final protein = lunch.components.first;
      expect(protein.options.length, 4);
      expect(protein.defaultOption.rawText, contains('pollo, pechuga'));
      expect(protein.sectionLabel, 'PRIMER PLATO');
      final dessert = lunch.components.where(
        (component) => component.sectionLabel == 'POSTRE',
      );
      expect(dessert, hasLength(1));
    });
  });

  group('derived day energy', () {
    // Pinned from the real assets. A change here means the pipeline's numbers
    // moved and someone must say why.
    const expectedKcal = <String, int>{
      'LU Y VI': 3082,
      'MA Y JU': 3081,
      'MI Y DO': 3069,
      'SÁBADO': 2953,
    };

    test('matches the pinned per-group totals', () {
      final plan = decodePlan().plan;
      for (final group in plan.dayGroups) {
        expect(
          group.template.dailyTarget.energy.kcal.round(),
          expectedKcal[group.label],
          reason: 'day group ${group.label}',
        );
      }
    });

    test('daily target is the sum of its slots, so the invariant holds', () {
      // The 0.01 tolerance is preserved rather than relaxed: a derived template
      // computes its daily target instead of being checked against a headline.
      final plan = decodePlan().plan;
      for (final group in plan.dayGroups) {
        final template = group.template;
        final summed = template.slots.fold<double>(
          0,
          (total, slot) => total + slot.target.energy.kcal.toDouble(),
        );
        expect(
          (summed - template.dailyTarget.energy.kcal).abs(),
          lessThan(0.01),
          reason: group.label,
        );
      }
    });

    test('energy stays consistent with the 4/4/9 macro identity', () {
      final plan = decodePlan().plan;
      for (final group in plan.dayGroups) {
        final target = group.template.dailyTarget;
        final fromMacros =
            target.macros.proteinG * 4 +
            target.macros.carbsG * 4 +
            target.macros.fatG * 9;
        final drift =
            (fromMacros - target.energy.kcal).abs() / target.energy.kcal;
        expect(
          drift,
          lessThan(0.02),
          reason:
              '${group.label}: energy and macros disagree by '
              '${(drift * 100).toStringAsFixed(1)}%',
        );
      }
    });
  });

  group('plan headline', () {
    test('keeps the advertised figure separate from the derived one', () {
      final plan = decodePlan().plan;
      expect(plan.declaredDailyEnergyKcal, 2950);
      for (final group in plan.dayGroups) {
        expect(group.template.declaredDailyEnergyKcal, 2950);
        // Derived macros never land exactly on a round headline; they must land
        // close enough that the import is trustworthy.
        final delta = group.template.declaredEnergyDelta!.abs();
        expect(
          delta / 2950,
          lessThan(0.06),
          reason:
              '${group.label} drifts ${delta.round()} kcal from the '
              'advertised 2950',
        );
      }
    });
  });
}
