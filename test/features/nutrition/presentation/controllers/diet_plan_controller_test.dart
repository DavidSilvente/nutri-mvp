import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/apply_diet_to_days.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

import '../../_fakes/diet_fixture.dart';
import '../../_fakes/fake_diet_plan_source.dart';

/// A source that fails every call, so the controller's error surfacing is
/// exercised rather than assumed. [FakeDietPlanSource] always succeeds.
class _AlwaysFailingSource implements DietPlanSource {
  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> listPlannedMeals({
    NutritionDay? day,
  }) async => const Err(StorageFailure('disk full'));

  @override
  Future<Result<List<PlannedMeal>, NutritionFailure>> plannedMealsBetween(
    NutritionDay from,
    NutritionDay to,
  ) async => const Err(StorageFailure('disk full'));

  @override
  Future<Result<PlannedMeal, NutritionFailure>> savePlannedMeal(
    PlannedMeal meal,
  ) async => const Err(StorageFailure('disk full'));

  @override
  Future<Result<void, NutritionFailure>> deletePlannedMeal(String id) async =>
      const Err(StorageFailure('disk full'));

  @override
  Future<Result<List<MealSubstitute>, NutritionFailure>> listSubstitutes(
    String plannedMealId,
  ) async => const Err(StorageFailure('disk full'));

  @override
  Future<Result<MealSubstitute, NutritionFailure>> saveSubstitute(
    MealSubstitute substitute,
  ) async => const Err(StorageFailure('disk full'));

  @override
  Future<Result<void, NutritionFailure>> deleteSubstitute(String id) async =>
      const Err(StorageFailure('disk full'));
}

NutritionTarget _target({num kcal = 500}) => NutritionTarget(
  energy: Energy(kcal: kcal),
  macros: Macros(proteinG: 30, carbsG: 55, fatG: 15),
);

void main() {
  // A Monday, so the weekday arithmetic below reads plainly.
  final monday = NutritionDay.fromDateTime(DateTime(2026, 8, 3));
  NutritionDay dayAfter(int days) =>
      NutritionDay.fromDateTime(DateTime(2026, 8, 3 + days));

  late FakeDietPlanSource source;

  setUp(() => source = FakeDietPlanSource());

  ProviderContainer container({DietPlanSource? override}) {
    final c = ProviderContainer(
      overrides: [dietPlanSourceProvider.overrideWithValue(override ?? source)],
    );
    addTearDown(c.dispose);
    return c;
  }

  List<PlannedMeal> plannedMeals(
    Result<List<PlannedMeal>, NutritionFailure> r,
  ) => (r as Ok<List<PlannedMeal>, NutritionFailure>).value;

  /// A diet whose weekday coverage is explicit, so applying it can be checked
  /// against the days it does and does not speak about.
  DietPlan diet({required Map<String, Set<int>> groups, String id = 'diet-1'}) {
    final entries = groups.entries.toList();
    return DietPlan(
      id: id,
      name: 'Test diet',
      dayGroups: [
        for (var index = 0; index < entries.length; index++)
          DietPlanDayGroup(
            label: entries[index].key,
            weekdays: entries[index].value,
            template: DietTemplate.derived(
              id: '$id:g$index',
              name: 'Test diet — ${entries[index].key}',
              slots: [
                mealSlot(id: '$id:g$index:m0', label: 'Lunch', position: 0),
              ],
            ),
          ),
      ],
    );
  }

  const everyDay = {1, 2, 3, 4, 5, 6, 7};

  group('DietPlanController.applyDiet', () {
    test('writes one planned meal per slot per covered day', () async {
      final c = container();
      final plan = diet(groups: {'EVERY DAY': everyDay});

      final outcome = await c
          .read(dietPlanControllerProvider.notifier)
          .applyDiet(plan: plan, days: [monday, dayAfter(1)]);

      expect(outcome?.mealsWritten, 2);
      expect(outcome?.skippedDays, isEmpty);
      expect(plannedMeals(await source.listPlannedMeals()), hasLength(2));
    });

    test('gives each day the group that covers ITS weekday', () async {
      final c = container();
      // Monday and Tuesday get different menus. Stamping one group across the
      // range — what the old template-based apply did — would put the Monday
      // slot on the Tuesday too.
      final plan = diet(
        groups: {
          'MONDAY': {DateTime.monday},
          'TUESDAY': {DateTime.tuesday},
        },
      );

      await c
          .read(dietPlanControllerProvider.notifier)
          .applyDiet(plan: plan, days: [monday, dayAfter(1)]);

      expect(
        plannedMeals(await source.listPlannedMeals(day: monday)).single.slotId,
        'diet-1:g0:m0',
      );
      expect(
        plannedMeals(
          await source.listPlannedMeals(day: dayAfter(1)),
        ).single.slotId,
        'diet-1:g1:m0',
      );
    });

    test(
      'reports days the diet says nothing about instead of inventing a menu',
      () async {
        final c = container();
        final plan = diet(
          groups: {
            'WEEKDAYS': {1, 2, 3, 4, 5},
          },
        );

        // Monday through Sunday: the weekend is uncovered.
        final outcome = await c
            .read(dietPlanControllerProvider.notifier)
            .applyDiet(
              plan: plan,
              days: [for (var i = 0; i < 7; i++) dayAfter(i)],
            );

        expect(outcome?.mealsWritten, 5);
        expect(outcome?.skippedDays.map((d) => d.weekday), [
          DateTime.saturday,
          DateTime.sunday,
        ]);
      },
    );

    test('is idempotent, so re-applying does not stack duplicates', () async {
      final c = container();
      final plan = diet(groups: {'EVERY DAY': everyDay});
      final notifier = c.read(dietPlanControllerProvider.notifier);

      await notifier.applyDiet(plan: plan, days: [monday]);
      await notifier.applyDiet(plan: plan, days: [monday]);

      final meals = plannedMeals(await source.listPlannedMeals());
      expect(meals, hasLength(1));
      expect(
        meals.single.id,
        ApplyDietToDays.plannedMealId('diet-1:g0:m0', monday),
      );
    });

    test(
      'surfaces a storage failure as an AsyncError and no outcome',
      () async {
        final c = container(override: _AlwaysFailingSource());
        final plan = diet(groups: {'EVERY DAY': everyDay});

        final outcome = await c
            .read(dietPlanControllerProvider.notifier)
            .applyDiet(plan: plan, days: [monday]);

        expect(outcome, isNull);
        final state = c.read(dietPlanControllerProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<HealthFailureException>());
      },
    );
  });

  group('DietPlanController.clearPlan', () {
    test(
      'removes what the same diet wrote, leaving other days alone',
      () async {
        final c = container();
        final plan = diet(groups: {'EVERY DAY': everyDay});
        final notifier = c.read(dietPlanControllerProvider.notifier);

        await notifier.applyDiet(plan: plan, days: [monday, dayAfter(1)]);
        await notifier.clearPlan(plan: plan, days: [monday]);

        expect(
          plannedMeals(await source.listPlannedMeals()).map((m) => m.day),
          [dayAfter(1)],
        );
      },
    );
  });

  group('DietPlanController write paths', () {
    PlannedMeal meal(String id, {String slotId = 'slot-a'}) => PlannedMeal(
      id: id,
      slotId: slotId,
      day: monday,
      targetSnapshot: _target(),
    );

    test('assignMealToDay persists the meal', () async {
      final c = container();

      await c
          .read(dietPlanControllerProvider.notifier)
          .assignMealToDay(meal('pm-1'));

      expect(plannedMeals(await source.listPlannedMeals()).single.id, 'pm-1');
      expect(c.read(dietPlanControllerProvider).hasError, isFalse);
    });

    test('a duplicate slot-day assignment surfaces as an AsyncError', () async {
      final c = container();
      final notifier = c.read(dietPlanControllerProvider.notifier);
      await notifier.assignMealToDay(meal('pm-1'));

      await notifier.assignMealToDay(meal('pm-2'));

      final state = c.read(dietPlanControllerProvider);
      expect(state.hasError, isTrue);
      expect(
        (state.error as HealthFailureException).failure,
        isA<ConflictFailure>(),
      );
    });

    test('deletePlannedMeal removes it', () async {
      final c = container();
      final notifier = c.read(dietPlanControllerProvider.notifier);
      await notifier.assignMealToDay(meal('pm-1'));

      await notifier.deletePlannedMeal('pm-1');

      expect(plannedMeals(await source.listPlannedMeals()), isEmpty);
    });

    test('saveSubstitute and deleteSubstitute round-trip', () async {
      final c = container();
      final notifier = c.read(dietPlanControllerProvider.notifier);
      await notifier.assignMealToDay(meal('pm-1'));

      await notifier.saveSubstitute(
        MealSubstitute(
          id: 'sub-1',
          plannedMealId: 'pm-1',
          label: 'Tofu bowl',
          target: _target(kcal: 480),
        ),
      );
      expect(
        (await source.listSubstitutes('pm-1')
                as Ok<List<MealSubstitute>, NutritionFailure>)
            .value,
        hasLength(1),
      );

      await notifier.deleteSubstitute('sub-1');
      expect(
        (await source.listSubstitutes('pm-1')
                as Ok<List<MealSubstitute>, NutritionFailure>)
            .value,
        isEmpty,
      );
    });

    test('a failing substitute write surfaces as an AsyncError', () async {
      final c = container(override: _AlwaysFailingSource());

      await c
          .read(dietPlanControllerProvider.notifier)
          .saveSubstitute(
            MealSubstitute(
              id: 'sub-1',
              plannedMealId: 'pm-1',
              label: 'Tofu bowl',
              target: _target(),
            ),
          );

      expect(c.read(dietPlanControllerProvider).hasError, isTrue);
    });
  });
}
