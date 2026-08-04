import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_plan_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/save_manual_diet.dart';

import '../../_fakes/diet_fixture.dart';
import '../../_fakes/fake_diet_plan_store.dart';

void main() {
  late FakeDietPlanStore store;
  late SaveManualDiet useCase;

  final start = DateTime.utc(2026, 8, 4, 10);

  /// An ADVANCING clock. A new diet's id is `manual-<microseconds>`, so a frozen
  /// clock would hand two diets the same id and every "two diets" test would
  /// silently become a "one diet, edited twice" test.
  late DateTime now;

  setUp(() {
    store = FakeDietPlanStore();
    now = start;
    useCase = SaveManualDiet(
      store: store,
      encoder: const DietPlanCodec(),
      now: () {
        now = now.add(const Duration(seconds: 1));
        return now;
      },
    );
  });

  StoredDietPlan ok(Result<StoredDietPlan, NutritionFailure> result) =>
      switch (result) {
        Ok(value: final plan) => plan,
        Err(failure: final failure) => fail('expected a plan, got $failure'),
      };

  NutritionFailure err(Result<StoredDietPlan, NutritionFailure> result) =>
      switch (result) {
        Ok() => fail('expected a failure, got a plan'),
        Err(failure: final failure) => failure,
      };

  group('SaveManualDiet', () {
    test('stores the diet as a document the decoder can read back', () async {
      final result = await useCase(
        name: '  My own diet  ',
        slots: [
          mealSlot(id: 'slot-breakfast', label: 'Breakfast', position: 0),
          mealSlot(id: 'slot-lunch', label: 'Lunch', position: 1, kcal: 700),
        ],
      );

      final stored = ok(result);
      expect(stored.name, 'My own diet', reason: 'the name is trimmed');
      expect(stored.sourceLabel, SaveManualDiet.manualSourceLabel);
      expect(stored.importedAt.isAfter(start), isTrue);

      // The point of storing a document: it goes back through the SAME decoder
      // an imported plan uses, so everything downstream reads one shape.
      final decoded = const DietPlanCodec().decode(
        stored.document,
        baseCatalog: FoodCatalog(const []),
        planId: stored.id,
      );
      final plan = switch (decoded) {
        Ok(value: final value) => value.plan,
        Err(failure: final failure) => fail('decode failed: $failure'),
      };

      expect(plan.name, 'My own diet');
      expect(plan.coversWholeWeek, isTrue);
      final slots = plan.dayGroups.single.template.slots;
      expect(slots.map((s) => s.id), ['slot-breakfast', 'slot-lunch']);
      // The daily target is the sum of the meals, not a second figure that could
      // disagree with them.
      expect(plan.dayGroups.single.template.dailyTarget.energy.kcal, 1200);
    });

    test('a new diet becomes the active one', () async {
      final stored = ok(
        await useCase(
          name: 'First',
          slots: [mealSlot(id: 's1')],
        ),
      );

      expect(stored.isDefault, isTrue);
    });

    test('editing keeps the id, so planned meals still resolve', () async {
      final created = ok(
        await useCase(
          name: 'Cut',
          slots: [mealSlot(id: 'slot-a', label: 'Breakfast')],
        ),
      );

      final edited = ok(
        await useCase(
          planId: created.id,
          name: 'Cut',
          slots: [
            mealSlot(id: 'slot-a', label: 'Breakfast, bigger', kcal: 600),
            mealSlot(id: 'slot-b', label: 'Snack', position: 1, kcal: 200),
          ],
          makeActive: false,
        ),
      );

      expect(edited.id, created.id);
      final plans = switch (await store.listPlans()) {
        Ok(value: final value) => value,
        Err() => fail('listPlans failed'),
      };
      expect(plans, hasLength(1), reason: 'an edit replaces, it does not add');
    });

    test('editing does not switch the user off the diet they follow', () async {
      // Two diets, the second active. Editing the FIRST must not promote it.
      final first = ok(
        await useCase(
          name: 'A',
          slots: [mealSlot(id: 's1')],
        ),
      );
      await useCase(
        name: 'B',
        slots: [mealSlot(id: 's2')],
      );

      await useCase(
        planId: first.id,
        name: 'A',
        slots: [mealSlot(id: 's1', kcal: 550)],
        makeActive: false,
      );

      final active = switch (await store.activePlan()) {
        Ok(value: final value) => value,
        Err() => fail('activePlan failed'),
      };
      expect(active?.name, 'B');
    });

    test('refuses a diet with no meals', () async {
      final failure = err(await useCase(name: 'Empty', slots: const []));

      expect(failure, isA<MalformedPlanFailure>());
      expect(
        (failure as MalformedPlanFailure).reason,
        contains('at least one meal'),
      );
    });

    test('refuses a blank name', () async {
      final failure = err(
        await useCase(
          name: '   ',
          slots: [mealSlot(id: 's1')],
        ),
      );

      expect(failure, isA<MalformedPlanFailure>());
    });

    test('refuses two meals sharing an id', () async {
      // Two meals on one slot id would collapse into a single planned meal per
      // day, silently dropping one of them from the calendar.
      final failure = err(
        await useCase(
          name: 'Clash',
          slots: [
            mealSlot(id: 'same', label: 'Breakfast', position: 0),
            mealSlot(id: 'same', label: 'Lunch', position: 1),
          ],
        ),
      );

      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('same id'));
    });

    test('surfaces the name clash the store reports', () async {
      await useCase(
        name: 'Cut',
        slots: [mealSlot(id: 's1')],
      );

      final failure = err(
        await useCase(
          name: 'Cut',
          slots: [mealSlot(id: 's2')],
        ),
      );

      expect(failure, isA<ConflictFailure>());
    });
  });
}
