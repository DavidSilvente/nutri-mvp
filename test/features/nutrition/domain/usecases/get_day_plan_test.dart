import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_day_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_nutrition_source.dart';

NutritionTarget target({
  num kcal = 600,
  num protein = 40,
  num carbs = 60,
  num fat = 20,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
  );
}

void main() {
  final day = NutritionDay.fromDateTime(DateTime(2026, 7, 24));
  final today = NutritionDay.fromDateTime(DateTime(2026, 7, 25));

  late FakeDietPlanSource dietSource;
  late FakeNutritionSource nutritionSource;
  late GetDayPlan useCase;

  setUp(() {
    dietSource = FakeDietPlanSource();
    nutritionSource = FakeNutritionSource();
    useCase = GetDayPlan(
      dietPlanSource: dietSource,
      nutritionSource: nutritionSource,
    );
  });

  /// Saves a two-slot template whose slots are deliberately stored in reverse
  /// position order, so ordering by position is actually exercised.
  Future<void> saveTemplate() async {
    final slots = [
      DietMealSlot(
        id: 'slot-dinner',
        label: 'Dinner',
        position: 1,
        target: target(),
      ),
      DietMealSlot(
        id: 'slot-breakfast',
        label: 'Breakfast',
        position: 0,
        target: target(),
      ),
    ];
    await dietSource.saveTemplate(
      DietTemplate(
        id: 't1',
        name: 'Plan',
        dailyTarget: NutritionTarget.sum(slots.map((s) => s.target)),
        slots: slots,
      ),
    );
  }

  Future<void> plan(String id, String slotId) {
    return dietSource.savePlannedMeal(
      PlannedMeal(
        id: id,
        slotId: slotId,
        day: day,
        targetSnapshot: target(),
      ),
    );
  }

  Future<void> log({
    required String id,
    String? plannedMealId,
    num kcal = 600,
    num protein = 40,
    num carbs = 60,
    num fat = 20,
    int hour = 13,
  }) {
    return nutritionSource.record(
      NutritionEntry(
        id: id,
        recordedAt: DateTime(2026, 7, 24, hour),
        energy: Energy(kcal: kcal),
        macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
        plannedMealId: plannedMealId,
      ),
    );
  }

  DayPlan unwrap(Result<DayPlan, NutritionFailure> result) =>
      (result as Ok<DayPlan, NutritionFailure>).value;

  group('GetDayPlan', () {
    test('returns an unplanned day when nothing is planned', () async {
      final plan = unwrap(await useCase(day, today: today));

      expect(plan.hasPlan, isFalse);
      expect(plan.meals, isEmpty);
      expect(plan.status, DayAdherenceStatus.unplanned);
      expect(plan.loggedTotal, target(kcal: 0, protein: 0, carbs: 0, fat: 0));
    });

    test('resolves each planned meal label from its template slot', () async {
      await saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await plan('pm-dinner', 'slot-dinner');

      final result = unwrap(await useCase(day, today: today));

      expect(result.meals.map((m) => m.label), ['Breakfast', 'Dinner']);
    });

    test('orders meals by slot position, not by insertion order', () async {
      await saveTemplate();
      await plan('pm-dinner', 'slot-dinner');
      await plan('pm-breakfast', 'slot-breakfast');

      final result = unwrap(await useCase(day, today: today));

      expect(result.meals.map((m) => m.position), [0, 1]);
      expect(result.meals.first.label, 'Breakfast');
    });

    test('attaches the entries logged against each meal', () async {
      await saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await plan('pm-dinner', 'slot-dinner');
      await log(id: 'e1', plannedMealId: 'pm-breakfast', hour: 8);
      await log(id: 'e2', plannedMealId: 'pm-dinner', hour: 21);

      final result = unwrap(await useCase(day, today: today));

      expect(result.meals.first.entries.map((e) => e.id), ['e1']);
      expect(result.meals.last.entries.map((e) => e.id), ['e2']);
      expect(result.meals.first.status, MealAdherenceStatus.onTarget);
    });

    test('separates unplanned entries from the plan', () async {
      await saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await log(id: 'linked', plannedMealId: 'pm-breakfast', hour: 8);
      await log(id: 'snack', kcal: 200, protein: 5, carbs: 25, fat: 8, hour: 17);

      final result = unwrap(await useCase(day, today: today));

      expect(result.unplannedEntries.map((e) => e.id), ['snack']);
      expect(result.meals.single.entries.map((e) => e.id), ['linked']);
    });

    test(
      'treats an entry pointing at another day\'s meal as unplanned',
      () async {
        await saveTemplate();
        await plan('pm-breakfast', 'slot-breakfast');
        await log(id: 'stale', plannedMealId: 'pm-from-another-day', hour: 9);

        final result = unwrap(await useCase(day, today: today));

        expect(result.unplannedEntries.map((e) => e.id), ['stale']);
      },
    );

    test('totals every entry of the day, planned or not', () async {
      await saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await log(
        id: 'linked',
        plannedMealId: 'pm-breakfast',
        kcal: 600,
        protein: 40,
        carbs: 60,
        fat: 20,
      );
      await log(id: 'snack', kcal: 200, protein: 10, carbs: 20, fat: 5);

      final result = unwrap(await useCase(day, today: today));

      expect(
        result.loggedTotal,
        target(kcal: 800, protein: 50, carbs: 80, fat: 25),
      );
      expect(result.plannedTotal, target());
    });

    test('derives the day status from its meals', () async {
      await saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await plan('pm-dinner', 'slot-dinner');
      await log(id: 'e1', plannedMealId: 'pm-breakfast');

      final result = unwrap(await useCase(day, today: today));

      // The day is settled (today is the 25th) with one of two meals met.
      expect(result.status, DayAdherenceStatus.partial);
      expect(result.adherence.completionRatio, 0.5);
    });

    test('propagates a diet source failure unchanged', () async {
      final failing = GetDayPlan(
        dietPlanSource: _FailingDietPlanSource(),
        nutritionSource: nutritionSource,
      );

      final result = await failing(day, today: today);

      expect(
        result,
        const Err<DayPlan, NutritionFailure>(StorageFailure('disk full')),
      );
    });

    test('propagates a nutrition source failure unchanged', () async {
      final failing = GetDayPlan(
        dietPlanSource: dietSource,
        nutritionSource: _FailingNutritionSource(),
      );

      final result = await failing(day, today: today);

      expect(
        result,
        const Err<DayPlan, NutritionFailure>(StorageFailure('read failed')),
      );
    });
  });
}

class _FailingDietPlanSource extends FakeDietPlanSource {
  @override
  Future<Result<List<DietTemplate>, NutritionFailure>> listTemplates() async {
    return const Err(StorageFailure('disk full'));
  }
}

class _FailingNutritionSource extends FakeNutritionSource {
  @override
  Future<Result<List<NutritionEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  ) async {
    return const Err(StorageFailure('read failed'));
  }
}
