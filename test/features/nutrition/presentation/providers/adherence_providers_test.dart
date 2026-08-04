import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/adherence_tolerance.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/calendar_month.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';

import '../../_fakes/diet_fixture.dart';
import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_nutrition_source.dart';

NutritionTarget target() => NutritionTarget(
  energy: Energy(kcal: 600),
  macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
);

void main() {
  final day = NutritionDay.fromDateTime(DateTime(2026, 7, 24));
  final today = NutritionDay.fromDateTime(DateTime(2026, 7, 25));

  late FakeDietPlanSource dietSource;
  late FakeMealSlotDirectory slotDirectory;
  late FakeNutritionSource nutritionSource;

  setUp(() async {
    dietSource = FakeDietPlanSource();
    nutritionSource = FakeNutritionSource();

    slotDirectory = FakeMealSlotDirectory(
      slots: [
        mealSlot(id: 'slot-1', label: 'Lunch', position: 0),
      ],
    );
    await dietSource.savePlannedMeal(
      PlannedMeal(
        id: 'pm-1',
        slotId: 'slot-1',
        day: day,
        targetSnapshot: target(),
      ),
    );
  });

  ProviderContainer container({List<Override> overrides = const []}) {
    final c = ProviderContainer(
      overrides: [
        nutritionSourceProvider.overrideWithValue(nutritionSource),
        dietPlanSourceProvider.overrideWithValue(dietSource),
        mealSlotDirectoryProvider.overrideWithValue(slotDirectory),
        todayProvider.overrideWithValue(today),
        ...overrides,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('dayPlanProvider', () {
    test('exposes the day\'s plan and its adherence', () async {
      final plan = await container().read(dayPlanProvider(day).future);

      expect(plan.meals, hasLength(1));
      expect(plan.meals.single.label, 'Lunch');
      expect(plan.status, DayAdherenceStatus.missed);
    });

    test('re-runs after an intake is recorded, without manual invalidation', () async {
      final c = container();

      final before = await c.read(dayPlanProvider(day).future);
      expect(before.meals.single.status, MealAdherenceStatus.pending);

      await c.read(nutritionControllerProvider.notifier).record(
        NutritionEntry(
          id: 'e1',
          recordedAt: DateTime(2026, 7, 24, 13),
          energy: Energy(kcal: 600),
          macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
          plannedMealId: 'pm-1',
        ),
      );

      final after = await c.read(dayPlanProvider(day).future);
      expect(after.meals.single.status, MealAdherenceStatus.onTarget);
    });

    test('surfaces a source failure as a HealthFailureException', () async {
      final c = container(
        overrides: [
          nutritionSourceProvider.overrideWithValue(_FailingNutritionSource()),
        ],
      );

      expect(
        () => c.read(dayPlanProvider(day).future),
        throwsA(isA<HealthFailureException>()),
      );
    });

    test('honours an overridden tolerance', () async {
      await nutritionSource.record(
        NutritionEntry(
          id: 'e1',
          recordedAt: DateTime(2026, 7, 24, 13),
          energy: Energy(kcal: 640),
          macros: Macros(proteinG: 44, carbsG: 56, fatG: 22),
          plannedMealId: 'pm-1',
        ),
      );

      final lenient = await container().read(dayPlanProvider(day).future);
      expect(lenient.meals.single.status, MealAdherenceStatus.onTarget);

      final strict = await container(
        overrides: [
          adherenceToleranceProvider.overrideWithValue(
            const AdherenceTolerance(
              relativeFraction: 0.01,
              macroFloorG: 0,
              energyFloorKcal: 0,
            ),
          ),
        ],
      ).read(dayPlanProvider(day).future);
      expect(strict.meals.single.status, MealAdherenceStatus.off);
    });
  });

  group('monthAdherenceProvider', () {
    test('evaluates the month containing the planned day', () async {
      final month = await container().read(
        monthAdherenceProvider(CalendarMonth(year: 2026, month: 7)).future,
      );

      expect(month.plannedDays, 1);
      expect(month.forDay(day)!.status, DayAdherenceStatus.missed);
    });

    test('re-runs after a planning write', () async {
      final c = container();
      final month = CalendarMonth(year: 2026, month: 7);

      expect((await c.read(monthAdherenceProvider(month).future)).plannedDays, 1);

      await c.read(dietPlanControllerProvider.notifier).assignMealToDay(
        PlannedMeal(
          id: 'pm-2',
          slotId: 'slot-1',
          day: NutritionDay.fromDateTime(DateTime(2026, 7, 26)),
          targetSnapshot: target(),
        ),
      );

      expect((await c.read(monthAdherenceProvider(month).future)).plannedDays, 2);
    });
  });
}

class _FailingNutritionSource extends FakeNutritionSource {
  @override
  Future<Result<List<NutritionEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  ) async {
    return const Err(StorageFailure('disk full'));
  }
}
