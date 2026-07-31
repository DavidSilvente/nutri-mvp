import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/diet_plan_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

import '../../_fakes/fake_diet_plan_source.dart';

/// A local test double that always fails, used ONLY to verify that
/// [DietPlanController] surfaces the port's [Err] as an [AsyncError]
/// instead of swallowing it. [FakeDietPlanSource] is intentionally NOT
/// used for this scenario since it always succeeds.
class _AlwaysFailingSource implements DietPlanSource {
  @override
  Future<Result<List<DietTemplate>, NutritionFailure>> listTemplates() async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<DietTemplate, NutritionFailure>> saveTemplate(
    DietTemplate template,
  ) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<void, NutritionFailure>> deleteTemplate(String id) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> listPlannedMeals({
    String? templateId,
    NutritionDay? day,
  }) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<PlannedMeal, NutritionFailure>> savePlannedMeal(
    PlannedMeal meal,
  ) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<void, NutritionFailure>> deletePlannedMeal(String id) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<List<MealSubstitute>, NutritionFailure>> listSubstitutes(
    String plannedMealId,
  ) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<MealSubstitute, NutritionFailure>> saveSubstitute(
    MealSubstitute substitute,
  ) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<void, NutritionFailure>> deleteSubstitute(String id) async {
    return const Err(StorageFailure('disk full'));
  }
}

/// A test double that returns an empty template list but fails when reading
/// planned meals. Used to exercise the second `_load` error branch.
class _PlannedMealsLoadFailingSource implements DietPlanSource {
  @override
  Future<Result<List<DietTemplate>, NutritionFailure>> listTemplates() async {
    return const Ok([]);
  }

  @override
  Future<Result<DietTemplate, NutritionFailure>> saveTemplate(
    DietTemplate template,
  ) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<void, NutritionFailure>> deleteTemplate(String id) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> listPlannedMeals({
    String? templateId,
    NutritionDay? day,
  }) async {
    return const Err(StorageFailure('planned meals unavailable'));
  }

  @override
  Future<Result<PlannedMeal, NutritionFailure>> savePlannedMeal(
    PlannedMeal meal,
  ) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<void, NutritionFailure>> deletePlannedMeal(String id) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<List<MealSubstitute>, NutritionFailure>> listSubstitutes(
    String plannedMealId,
  ) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<MealSubstitute, NutritionFailure>> saveSubstitute(
    MealSubstitute substitute,
  ) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<void, NutritionFailure>> deleteSubstitute(String id) async {
    return const Err(StorageFailure('disk full'));
  }
}

NutritionTarget _target({
  double kcal = 700,
  double proteinG = 40,
  double carbsG = 60,
  double fatG = 20,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
  );
}

DietTemplate _template({
  required String id,
  required String name,
  NutritionTarget? target,
  List<DietMealSlot>? slots,
}) {
  final resolvedSlots = slots ??
      [
        DietMealSlot(
          id: '${id}_slot',
          label: 'Meal',
          position: 0,
          target: target ?? _target(kcal: 2200),
        ),
      ];
  return DietTemplate(
    id: id,
    name: name,
    dailyTarget: target ?? NutritionTarget.sum(resolvedSlots.map((s) => s.target)),
    slots: resolvedSlots,
  );
}

PlannedMeal _plannedMeal({
  required String id,
  String slotId = 'slot',
  NutritionDay? day,
}) {
  return PlannedMeal(
    id: id,
    slotId: slotId,
    day: day,
    targetSnapshot: _target(),
  );
}

void main() {
  group('DietPlanController', () {
    test('builds with an empty diet plan state when source has no data',
        () async {
      final container = ProviderContainer(
        overrides: [
          dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(dietPlanControllerProvider.future);

      expect(initial.templates, isEmpty);
      expect(initial.plannedMeals, isEmpty);
    });

    test('saveTemplate reflects the created template in the async state',
        () async {
      final container = ProviderContainer(
        overrides: [
          dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(dietPlanControllerProvider.future);

      final template = _template(
        id: 't1',
        name: 'Cut-A',
        target: _target(kcal: 2200),
      );
      await container
          .read(dietPlanControllerProvider.notifier)
          .saveTemplate(template);

      final state = container.read(dietPlanControllerProvider);
      expect(state, isA<AsyncData<DietPlanState>>());
      expect(state.value!.templates, [template]);
      expect(state.value!.plannedMeals, isEmpty);
    });

    test('saveTemplate reflects an edited slot in the async state', () async {
      final container = ProviderContainer(
        overrides: [
          dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(dietPlanControllerProvider.future);

      final original = _template(
        id: 't1',
        name: 'Cut-A',
        target: _target(kcal: 2200),
      );
      await container
          .read(dietPlanControllerProvider.notifier)
          .saveTemplate(original);

      final updated = _template(
        id: 't1',
        name: 'Cut-A',
        slots: [
          DietMealSlot(
            id: 't1_slot',
            label: 'Breakfast',
            position: 0,
            target: _target(kcal: 700),
          ),
          DietMealSlot(
            id: 't1_slot_2',
            label: 'Lunch',
            position: 1,
            target: _target(kcal: 1500),
          ),
        ],
      );
      await container
          .read(dietPlanControllerProvider.notifier)
          .saveTemplate(updated);

      final state = container.read(dietPlanControllerProvider);
      expect(state.value!.templates, [updated]);
    });

    test('assignMealToDay reflects the planned meal in the async state',
        () async {
      final container = ProviderContainer(
        overrides: [
          dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(dietPlanControllerProvider.future);

      final template = _template(
        id: 't1',
        name: 'Cut-A',
        slots: [
          DietMealSlot(
            id: 't1_slot',
            label: 'Breakfast',
            position: 0,
            target: _target(kcal: 700),
          ),
        ],
      );
      await container
          .read(dietPlanControllerProvider.notifier)
          .saveTemplate(template);

      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final meal = PlannedMeal(
        id: 'm1',
        slotId: 't1_slot',
        day: day,
        targetSnapshot: _target(kcal: 700),
      );
      await container
          .read(dietPlanControllerProvider.notifier)
          .assignMealToDay(meal);

      final state = container.read(dietPlanControllerProvider);
      expect(state.value!.plannedMeals, [meal]);
      expect(state.value!.templates, [template]);
    });

    test('duplicate template name surfaces as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(dietPlanControllerProvider.future);

      final first = _template(
        id: 't1',
        name: 'Cut-A',
        target: _target(kcal: 2200),
      );
      final duplicate = _template(
        id: 't2',
        name: 'Cut-A',
        target: _target(kcal: 2200),
      );
      await container
          .read(dietPlanControllerProvider.notifier)
          .saveTemplate(first);
      await container
          .read(dietPlanControllerProvider.notifier)
          .saveTemplate(duplicate);

      final state = container.read(dietPlanControllerProvider);
      expect(state, isA<AsyncError<DietPlanState>>());
      final error = state.error! as HealthFailureException;
      expect(error.failure, isA<ConflictFailure>());
    });

    test('duplicate slot-day assignment surfaces as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(dietPlanControllerProvider.future);

      final template = _template(
        id: 't1',
        name: 'Cut-A',
        slots: [
          DietMealSlot(
            id: 't1_slot',
            label: 'Breakfast',
            position: 0,
            target: _target(kcal: 700),
          ),
        ],
      );
      await container
          .read(dietPlanControllerProvider.notifier)
          .saveTemplate(template);

      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final first = PlannedMeal(
        id: 'm1',
        slotId: 't1_slot',
        day: day,
        targetSnapshot: _target(kcal: 700),
      );
      final duplicate = PlannedMeal(
        id: 'm2',
        slotId: 't1_slot',
        day: day,
        targetSnapshot: _target(kcal: 700),
      );
      await container
          .read(dietPlanControllerProvider.notifier)
          .assignMealToDay(first);
      await container
          .read(dietPlanControllerProvider.notifier)
          .assignMealToDay(duplicate);

      final state = container.read(dietPlanControllerProvider);
      expect(state, isA<AsyncError<DietPlanState>>());
      final error = state.error! as HealthFailureException;
      expect(error.failure, isA<ConflictFailure>());
    });

    test('a failure while loading surfaces as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          dietPlanSourceProvider.overrideWithValue(_AlwaysFailingSource()),
        ],
      );
      addTearDown(container.dispose);

        await expectLater(
          container.read(dietPlanControllerProvider.future),
          throwsA(isA<HealthFailureException>()),
        );
    });

    test(
      'a failure while loading planned meals (with templates OK) '
      'surfaces as AsyncError',
      () async {
        final container = ProviderContainer(
          overrides: [
            dietPlanSourceProvider
                .overrideWithValue(_PlannedMealsLoadFailingSource()),
          ],
        );
        addTearDown(container.dispose);

        await expectLater(
          container.read(dietPlanControllerProvider.future),
          throwsA(isA<HealthFailureException>()),
        );
      },
    );
  });

  group('DietPlanState', () {
    test('an instance equals itself', () {
      const state = DietPlanState(templates: [], plannedMeals: []);
      expect(state == state, isTrue);
    });

    test('two states with empty equal values are equal and share hashCode',
        () {
      const a = DietPlanState(templates: [], plannedMeals: []);
      const b = DietPlanState(templates: [], plannedMeals: []);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('two states with the same non-empty content are equal and share hashCode',
        () {
      final template = _template(id: 't1', name: 'Cut-A');
      final meal = _plannedMeal(
        id: 'm1',
        day: NutritionDay.fromDateTime(DateTime(2026, 8, 1)),
      );
      final a = DietPlanState(templates: [template], plannedMeals: [meal]);
      final b = DietPlanState(templates: [template], plannedMeals: [meal]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('states with different template lengths are not equal', () {
      final a = const DietPlanState(templates: [], plannedMeals: []);
      final b = DietPlanState(
        templates: [_template(id: 't1', name: 'Cut-A')],
        plannedMeals: const [],
      );
      expect(a, isNot(equals(b)));
    });

    test('states with different planned meal lengths are not equal', () {
      final a = const DietPlanState(templates: [], plannedMeals: []);
      final b = DietPlanState(
        templates: const [],
        plannedMeals: [
          _plannedMeal(id: 'm1'),
        ],
      );
      expect(a, isNot(equals(b)));
    });

    test('states with different template content are not equal', () {
      final a = DietPlanState(
        templates: [_template(id: 't1', name: 'Cut-A')],
        plannedMeals: const [],
      );
      final b = DietPlanState(
        templates: [_template(id: 't2', name: 'Cut-B')],
        plannedMeals: const [],
      );
      expect(a, isNot(equals(b)));
    });

    test('states with different planned meal content are not equal', () {
      final a = DietPlanState(
        templates: const [],
        plannedMeals: [_plannedMeal(id: 'm1')],
      );
      final b = DietPlanState(
        templates: const [],
        plannedMeals: [_plannedMeal(id: 'm2')],
      );
      expect(a, isNot(equals(b)));
    });

    test('a state is not equal to an unrelated type', () {
      const state = DietPlanState(templates: [], plannedMeals: []);
      const other = Object();
      expect(state == other, isFalse);
    });

    test('toString includes the type name and fields', () {
      const state = DietPlanState(templates: [], plannedMeals: []);
      final representation = state.toString();
      expect(representation, contains('DietPlanState'));
      expect(representation, contains('templates'));
      expect(representation, contains('plannedMeals'));
    });
  });
}
