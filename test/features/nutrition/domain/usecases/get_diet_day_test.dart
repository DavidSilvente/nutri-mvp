import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_plan_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_diet_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/resolve_active_diet.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

import '../../_fakes/fake_diet_plan_store.dart';

/// Focused regression test for [GetDietDay]'s option resolution, NOT a rewrite
/// of its behaviour. Before this change, [GetDietDay] only read day-scoped
/// selections, so a user who set "always beef" on a component would see beef
/// on the day plan screen (which already read `ComponentDefaults` via
/// `GetDayPlan`) but still see chicken here — the same day, two different
/// answers. These two scenarios pin the fix: preference applies when no day
/// selection exists, and a day selection still outranks it.
void main() {
  const codec = DietPlanCodec();
  final day = NutritionDay.fromDateTime(DateTime.utc(2026, 8, 3));

  // One meal, one component, two alternatives — chicken is the plan's default
  // (first-listed), beef is the alternative. Component/option ids follow the
  // codec's positional derivation: no stated slotId means `<planId>:g0:m0`.
  const componentId = 'plan-1:g0:m0:c0';
  const chickenOptionId = 'plan-1:g0:m0:c0:o0';
  const beefOptionId = 'plan-1:g0:m0:c0:o1';

  final planDocument = jsonEncode({
    'schemaVersion': 2,
    'diet': {
      'name': 'Test diet',
      'dayGroups': [
        {
          'label': 'EVERY DAY',
          'weekdays': [1, 2, 3, 4, 5, 6, 7],
          'meals': [
            {
              'label': 'Lunch',
              'sections': [
                {
                  'components': [
                    {
                      'alternatives': [
                        {
                          'foodRef': 'chicken_breast_grilled',
                          'quantity': {'grams': 100},
                          'rawText': '100 g chicken',
                        },
                        {
                          'foodRef': 'beef_loin',
                          'quantity': {'grams': 100},
                          'rawText': '100 g beef',
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
  });

  late FakeDietPlanStore store;
  late GetDietDay useCase;

  setUp(() async {
    store = FakeDietPlanStore();
    await store.savePlan(
      StoredDietPlan(
        id: 'plan-1',
        name: 'Test diet',
        document: planDocument,
        importedAt: DateTime.utc(2026, 1, 1),
        isDefault: true,
      ),
    );

    final resolveActiveDiet = ResolveActiveDiet(
      store: store,
      decode: DecodeStoredDiet(
        foodTable: FakeFoodTableSource(),
        decoder: codec,
      ),
    );
    useCase = GetDietDay(store: store, activeDiet: resolveActiveDiet);
  });

  String foodIdOf(DietDay dietDay) =>
      dietDay.meals.single.components.single.food.id;

  test(
    'falls back to the plan default with no selection or preference',
    () async {
      final result = await useCase(day);
      final dietDay = switch (result) {
        Ok(value: final value) => value!,
        Err(failure: final failure) => fail('expected a day, got $failure'),
      };

      expect(foodIdOf(dietDay), 'chicken_breast_grilled');
    },
  );

  test(
    'a standing preference applies when no day selection overrides it',
    () async {
      await store.setPreferredOption(
        componentId: componentId,
        optionId: beefOptionId,
      );

      final result = await useCase(day);
      final dietDay = switch (result) {
        Ok(value: final value) => value!,
        Err(failure: final failure) => fail('expected a day, got $failure'),
      };

      expect(foodIdOf(dietDay), 'beef_loin');
    },
  );

  test("a day selection outranks a standing preference — today's swap "
      'still wins (regression)', () async {
    await store.setPreferredOption(
      componentId: componentId,
      optionId: beefOptionId,
    );
    await store.selectOption(
      day: day,
      componentId: componentId,
      optionId: chickenOptionId,
    );

    final result = await useCase(day);
    final dietDay = switch (result) {
      Ok(value: final value) => value!,
      Err(failure: final failure) => fail('expected a day, got $failure'),
    };

    expect(foodIdOf(dietDay), 'chicken_breast_grilled');
  });
}
