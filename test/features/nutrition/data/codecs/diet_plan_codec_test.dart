import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_plan_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_decoder.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// Unit-level rules of the plan document, over a two-food fixture catalog.
///
/// Complements `real_diet_plan_test.dart`, which reads the shipped assets: this
/// file pins the SHAPE rules — which fields are required, how slot ids are
/// formed, and what a hand-entered meal means — where a tiny catalog makes the
/// expected numbers obvious.
void main() {
  const codec = DietPlanCodec();

  final catalog = FoodCatalog([
    FoodItem(
      id: 'rice_white_raw',
      name: 'White rice, raw',
      preparation: FoodPreparation.raw,
      // Round figures so a quantity of 100 g reads straight off the fixture.
      per100g: NutritionTarget(
        energy: Energy(kcal: 360),
        macros: Macros(proteinG: 7, carbsG: 80, fatG: 1),
      ),
      source: FoodDataSource.usdaSrLegacy,
    ),
    FoodItem(
      id: 'chicken_breast_grilled',
      name: 'Chicken breast, grilled',
      preparation: FoodPreparation.grilled,
      per100g: NutritionTarget(
        energy: Energy(kcal: 165),
        macros: Macros(proteinG: 31, carbsG: 0, fatG: 4),
      ),
      source: FoodDataSource.usdaSrLegacy,
    ),
  ]);

  DecodedDietPlan decode(Map<String, Object?> document) {
    final result = codec.decode(
      jsonEncode(document),
      baseCatalog: catalog,
      planId: 'plan-1',
    );
    return switch (result) {
      Ok(value: final decoded) => decoded,
      Err(failure: final failure) => fail('expected a plan, got $failure'),
    };
  }

  NutritionFailure decodeFailure(Map<String, Object?> document) {
    final result = codec.decode(
      jsonEncode(document),
      baseCatalog: catalog,
      planId: 'plan-1',
    );
    return switch (result) {
      Ok() => fail('expected a failure, got a plan'),
      Err(failure: final failure) => failure,
    };
  }

  /// A meal built from foods, the way an import writes one.
  Map<String, Object?> foodMeal({String label = 'Lunch', String? slotId}) => {
    'slotId': ?slotId,
    'label': label,
    'sections': [
      {
        'label': 'PRIMER PLATO',
        'components': [
          {
            'alternatives': [
              {
                'foodRef': 'rice_white_raw',
                'quantity': {'grams': 100},
                'rawText': '100 g arroz',
              },
              {
                'foodRef': 'chicken_breast_grilled',
                'quantity': {'grams': 100},
                'rawText': '100 g pollo',
              },
            ],
          },
        ],
      },
    ],
  };

  /// A meal that states its macros outright, the way the in-app editor writes one.
  Map<String, Object?> targetMeal({
    required String slotId,
    String label = 'Breakfast',
    String? time,
    List<String> notes = const [],
  }) => {
    'slotId': slotId,
    'label': label,
    'time': ?time,
    if (notes.isNotEmpty) 'notes': notes,
    'target': {
      'energyKcal': 500,
      'proteinG': 30,
      'carbsG': 55,
      'fatG': 15,
    },
  };

  Map<String, Object?> document({
    required List<Map<String, Object?>> meals,
    int schemaVersion = 2,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
    num? declaredDailyEnergyKcal,
  }) => {
    'schemaVersion': schemaVersion,
    'diet': {
      'name': 'Test diet',
      'declaredDailyEnergyKcal': ?declaredDailyEnergyKcal,
      'dayGroups': [
        {'label': 'EVERY DAY', 'weekdays': weekdays, 'meals': meals},
      ],
    },
  };

  group('schema version', () {
    test('reads both the version imports wrote and the current one', () {
      for (final version in DietPlanCodec.readableSchemaVersions) {
        final decoded = decode(
          document(meals: [foodMeal()], schemaVersion: version),
        );
        expect(decoded.plan.name, 'Test diet');
      }
    });

    test('refuses a version this build does not know', () {
      final failure = decodeFailure(
        document(meals: [foodMeal()], schemaVersion: 99),
      );
      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('99'));
    });
  });

  group('slot ids', () {
    test('fall back to the positional id when the document states none', () {
      // v1 documents have no slotId, and their planned meals and selections are
      // already keyed to the positional form. It must not move.
      final decoded = decode(
        document(meals: [foodMeal(), foodMeal(label: 'Dinner')]),
      );
      final slots = decoded.plan.dayGroups.single.template.slots;
      expect(slots.map((s) => s.id), ['plan-1:g0:m0', 'plan-1:g0:m1']);
    });

    test('use the stated id, and derive component ids from it', () {
      final decoded = decode(
        document(meals: [foodMeal(slotId: 'manual-breakfast')]),
      );
      final slot = decoded.plan.dayGroups.single.template.slots.single;
      expect(slot.id, 'manual-breakfast');
      // Selections are keyed by component id, so it has to follow the slot
      // rather than the position — otherwise reordering meals reassigns swaps.
      expect(slot.components.single.id, 'manual-breakfast:c0');
      expect(
        slot.components.single.options.map((o) => o.id),
        ['manual-breakfast:c0:o0', 'manual-breakfast:c0:o1'],
      );
    });

    test('survive a meal being inserted before them', () {
      final before = decode(
        document(meals: [targetMeal(slotId: 'lunch', label: 'Lunch')]),
      );
      final after = decode(
        document(
          meals: [
            targetMeal(slotId: 'breakfast'),
            targetMeal(slotId: 'lunch', label: 'Lunch'),
          ],
        ),
      );

      expect(before.plan.dayGroups.single.template.slots.single.id, 'lunch');
      final lunch = after.plan.dayGroups.single.template.slots.last;
      expect(lunch.id, 'lunch');
      // The position moved, the identity did not: history keyed to `lunch`
      // still resolves.
      expect(lunch.position, 1);
    });
  });

  group('hand-entered meals', () {
    test('take their target from the document instead of from foods', () {
      final decoded = decode(
        document(meals: [targetMeal(slotId: 'breakfast', time: '08:30')]),
      );
      final slot = decoded.plan.dayGroups.single.template.slots.single;

      expect(slot.isDerived, isFalse);
      expect(slot.components, isEmpty);
      expect(slot.target.energy.kcal, 500);
      expect(slot.target.macros.proteinG, 30);
      expect(slot.timeOfDay, '08:30');
    });

    test('sum into the day group target alongside food-first meals', () {
      final decoded = decode(
        document(meals: [targetMeal(slotId: 'breakfast'), foodMeal()]),
      );
      final template = decoded.plan.dayGroups.single.template;

      // 500 hand-entered + 360 derived from 100 g of the fixture rice.
      expect(template.dailyTarget.energy.kcal, 860);
    });

    test('are refused when a meal states both foods and a target', () {
      final ambiguous = {...foodMeal(slotId: 'both'), 'target': {}};
      final failure = decodeFailure(document(meals: [ambiguous]));

      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('both'));
    });

    test('are refused when a meal states neither', () {
      final failure = decodeFailure(
        document(meals: [{'slotId': 'empty', 'label': 'Nothing'}]),
      );

      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('neither'));
    });
  });

  group('encoding a hand-authored diet', () {
    DietPlan handAuthored() => DietPlan(
      id: 'manual-1',
      name: 'My own diet',
      declaredDailyEnergyKcal: 2000,
      dayGroups: [
        DietPlanDayGroup(
          label: 'EVERY DAY',
          weekdays: {1, 2, 3, 4, 5, 6, 7},
          template: DietTemplate.derived(
            id: 'manual-1:g0',
            name: 'My own diet — EVERY DAY',
            declaredDailyEnergyKcal: 2000,
            slots: [
              DietMealSlot(
                id: 'manual-1:breakfast',
                label: 'Breakfast',
                position: 0,
                timeOfDay: '08:00',
                notes: const ['Soak the oats overnight'],
                target: NutritionTarget(
                  energy: Energy(kcal: 500),
                  macros: Macros(proteinG: 30, carbsG: 55, fatG: 15),
                ),
              ),
              DietMealSlot(
                id: 'manual-1:lunch',
                label: 'Lunch',
                position: 1,
                target: NutritionTarget(
                  energy: Energy(kcal: 700),
                  macros: Macros(proteinG: 45, carbsG: 70, fatG: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    test('round-trips through a decode unchanged', () {
      final encoded = codec.encode(handAuthored());
      final source = switch (encoded) {
        Ok(value: final value) => value,
        Err(failure: final failure) => fail('encode failed: $failure'),
      };

      final result = codec.decode(
        source,
        baseCatalog: catalog,
        planId: 'manual-1',
      );
      final decoded = switch (result) {
        Ok(value: final value) => value.plan,
        Err(failure: final failure) => fail('decode failed: $failure'),
      };

      expect(decoded.name, 'My own diet');
      expect(decoded.declaredDailyEnergyKcal, 2000);
      expect(decoded.coversWholeWeek, isTrue);

      final slots = decoded.dayGroups.single.template.slots;
      expect(slots.map((s) => s.id), [
        'manual-1:breakfast',
        'manual-1:lunch',
      ]);
      expect(slots.map((s) => s.label), ['Breakfast', 'Lunch']);
      expect(slots.first.timeOfDay, '08:00');
      expect(slots.first.notes, ['Soak the oats overnight']);
      expect(slots.map((s) => s.target.energy.kcal), [500, 700]);
      expect(slots.last.target.macros.proteinG, 45);
    });

    test('refuses a food-first plan rather than dropping its recipes', () {
      // The recipes a plan defines live in the catalog the decode built, not on
      // the plan, so encoding one would quietly replace prescribed foods with
      // bare totals.
      final imported = decode(document(meals: [foodMeal()])).plan;
      final result = codec.encode(imported);

      expect(result.isErr, isTrue);
      final failure = (result as Err<String, NutritionFailure>).failure;
      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('recipes'));
    });
  });
}
