import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/data_revision_provider.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

import '../../_fakes/fake_diet_plan_store.dart';

/// Counts how many times [activePlan] runs, so a test can prove the day
/// controller re-read its dependencies after an invalidation rather than
/// merely surviving one.
class _CountingStore extends FakeDietPlanStore {
  int activePlanCalls = 0;

  @override
  Future<Result<StoredDietPlan?, NutritionFailure>> activePlan() {
    activePlanCalls++;
    return super.activePlan();
  }
}

/// A store whose write methods always fail, so error propagation is exercised
/// rather than assumed. Reads always succeed with empty maps.
class _AlwaysFailingStore extends FakeDietPlanStore {
  @override
  Future<Result<void, NutritionFailure>> selectOption({
    required NutritionDay day,
    required String componentId,
    required String optionId,
  }) async => const Err(StorageFailure('disk full'));

  @override
  Future<Result<void, NutritionFailure>> clearSelection({
    required NutritionDay day,
    required String componentId,
  }) async => const Err(StorageFailure('disk full'));

  @override
  Future<Result<void, NutritionFailure>> setPreferredOption({
    required String componentId,
    required String optionId,
  }) async => const Err(StorageFailure('disk full'));

  @override
  Future<Result<void, NutritionFailure>> clearPreferredOption(
    String componentId,
  ) async => const Err(StorageFailure('disk full'));
}

void main() {
  final monday = NutritionDay.fromDateTime(DateTime(2026, 8, 3));

  late FakeDietPlanStore store;

  setUp(() => store = FakeDietPlanStore());

  ProviderContainer container({DietPlanStore? override}) {
    final c = ProviderContainer(
      overrides: [dietPlanStoreProvider.overrideWithValue(override ?? store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('ComponentChoiceController.selectOption', () {
    test('writes a day-scoped selection via DietPlanStore', () async {
      final c = container();

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .selectOption(componentId: 'protein', optionId: 'beef_loin');

      final selections =
          (await store.selectionsFor(monday)
                  as Ok<Map<String, String>, NutritionFailure>)
              .value;
      expect(selections['protein'], 'beef_loin');
    });

    test('bumps the data revision so derived views refresh', () async {
      final c = container();
      final before = c.read(dataRevisionProvider);

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .selectOption(componentId: 'protein', optionId: 'beef_loin');

      expect(c.read(dataRevisionProvider), before + 1);
    });

    test('invalidates the day controller for the same day', () async {
      final counting = _CountingStore();
      final c = container(override: counting);
      // Await it once, so a rebuild that never happened would be observable
      // as the call count staying flat instead of climbing.
      await c.read(dietDayControllerProvider(monday).future);
      expect(counting.activePlanCalls, 1);

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .selectOption(componentId: 'protein', optionId: 'beef_loin');
      await c.read(dietDayControllerProvider(monday).future);

      expect(counting.activePlanCalls, 2);
    });

    test('surfaces a write failure instead of swallowing it', () async {
      final c = container(override: _AlwaysFailingStore());

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .selectOption(componentId: 'protein', optionId: 'beef_loin');

      final state = c.read(componentChoiceControllerProvider(monday));
      expect(state.hasError, isTrue);
      expect(state.error, isA<HealthFailureException>());
    });
  });

  group('ComponentChoiceController.setPreference', () {
    test('writes a standing preference via DietPlanStore', () async {
      final c = container();

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .setPreference(componentId: 'protein', optionId: 'beef_loin');

      final preferences =
          (await store.preferredOptions()
                  as Ok<Map<String, String>, NutritionFailure>)
              .value;
      expect(preferences['protein'], 'beef_loin');
    });

    test(
      'bumps the data revision and invalidates the day controller',
      () async {
        final counting = _CountingStore();
        final c = container(override: counting);
        final revisionBefore = c.read(dataRevisionProvider);
        await c.read(dietDayControllerProvider(monday).future);

        await c
            .read(componentChoiceControllerProvider(monday).notifier)
            .setPreference(componentId: 'protein', optionId: 'beef_loin');
        await c.read(dietDayControllerProvider(monday).future);

        expect(c.read(dataRevisionProvider), revisionBefore + 1);
        expect(counting.activePlanCalls, 2);
      },
    );

    test('surfaces a write failure instead of swallowing it', () async {
      final c = container(override: _AlwaysFailingStore());

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .setPreference(componentId: 'protein', optionId: 'beef_loin');

      final state = c.read(componentChoiceControllerProvider(monday));
      expect(state.hasError, isTrue);
      expect(state.error, isA<HealthFailureException>());
    });
  });

  group('ComponentChoiceController.clearSelection', () {
    test('drops a day-scoped selection via DietPlanStore', () async {
      final c = container();
      await store.selectOption(
        day: monday,
        componentId: 'protein',
        optionId: 'beef_loin',
      );

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .clearSelection('protein');

      final selections =
          (await store.selectionsFor(monday)
                  as Ok<Map<String, String>, NutritionFailure>)
              .value;
      expect(selections.containsKey('protein'), isFalse);
    });

    test(
      'bumps the data revision and invalidates the day controller',
      () async {
        final counting = _CountingStore();
        final c = container(override: counting);
        await c.read(dietDayControllerProvider(monday).future);

        await c
            .read(componentChoiceControllerProvider(monday).notifier)
            .clearSelection('protein');
        await c.read(dietDayControllerProvider(monday).future);

        expect(counting.activePlanCalls, 2);
      },
    );

    test('surfaces a write failure instead of swallowing it', () async {
      final c = container(override: _AlwaysFailingStore());

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .clearSelection('protein');

      final state = c.read(componentChoiceControllerProvider(monday));
      expect(state.hasError, isTrue);
      expect(state.error, isA<HealthFailureException>());
    });
  });

  group('ComponentChoiceController.clearPreference', () {
    test('drops a standing preference via DietPlanStore', () async {
      final c = container();
      await store.setPreferredOption(componentId: 'protein', optionId: 'x');

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .clearPreference('protein');

      final preferences =
          (await store.preferredOptions()
                  as Ok<Map<String, String>, NutritionFailure>)
              .value;
      expect(preferences.containsKey('protein'), isFalse);
    });

    test('surfaces a write failure instead of swallowing it', () async {
      final c = container(override: _AlwaysFailingStore());

      await c
          .read(componentChoiceControllerProvider(monday).notifier)
          .clearPreference('protein');

      final state = c.read(componentChoiceControllerProvider(monday));
      expect(state.hasError, isTrue);
      expect(state.error, isA<HealthFailureException>());
    });
  });
}
