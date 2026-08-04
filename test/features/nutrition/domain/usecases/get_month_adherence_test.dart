import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_month_adherence.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/calendar_month.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

import '../../_fakes/diet_fixture.dart';
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
  final july = CalendarMonth(year: 2026, month: 7);
  final today = NutritionDay.fromDateTime(DateTime(2026, 7, 20));

  NutritionDay day(int d) => NutritionDay.fromDateTime(DateTime(2026, 7, d));

  late FakeDietPlanSource dietSource;
  late FakeNutritionSource nutritionSource;
  late FakeMealSlotDirectory slotDirectory;
  late GetMonthAdherence useCase;

  setUp(() async {
    dietSource = FakeDietPlanSource();
    nutritionSource = FakeNutritionSource();
    slotDirectory = FakeMealSlotDirectory(
      slots: [
        mealSlot(id: 'slot-1', label: 'Lunch', position: 0),
        mealSlot(id: 'slot-2', label: 'Dinner', position: 1),
      ],
    );
    useCase = GetMonthAdherence(
      dietPlanSource: dietSource,
      nutritionSource: nutritionSource,
      slotDirectory: slotDirectory,
    );
  });

  Future<void> plan(String id, String slotId, int dayOfMonth) {
    return dietSource.savePlannedMeal(
      PlannedMeal(
        id: id,
        slotId: slotId,
        day: day(dayOfMonth),
        targetSnapshot: target(),
      ),
    );
  }

  Future<void> log({
    required String id,
    required String plannedMealId,
    required int dayOfMonth,
    num kcal = 600,
    num protein = 40,
    num carbs = 60,
    num fat = 20,
  }) {
    return nutritionSource.record(
      NutritionEntry(
        id: id,
        recordedAt: DateTime(2026, 7, dayOfMonth, 13),
        energy: Energy(kcal: kcal),
        macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
        plannedMealId: plannedMealId,
      ),
    );
  }

  MonthAdherence unwrap(Result<MonthAdherence, NutritionFailure> result) =>
      (result as Ok<MonthAdherence, NutritionFailure>).value;

  group('GetMonthAdherence', () {
    test('covers every day of the month, including unplanned ones', () async {
      final month = unwrap(await useCase(july, today: today));

      for (final d in july.days) {
        expect(month.forDay(d), isNotNull, reason: 'missing $d');
      }
      expect(month.forDay(day(1))!.status, DayAdherenceStatus.unplanned);
      expect(month.plannedDays, 0);
    });

    test('returns null for a day outside the month', () async {
      final month = unwrap(await useCase(july, today: today));

      expect(
        month.forDay(NutritionDay.fromDateTime(DateTime(2026, 8, 1))),
        isNull,
      );
    });

    test('marks a fully met past day as complete', () async {
      await plan('pm-1', 'slot-1', 10);
      await plan('pm-2', 'slot-2', 10);
      await log(id: 'e1', plannedMealId: 'pm-1', dayOfMonth: 10);
      await log(id: 'e2', plannedMealId: 'pm-2', dayOfMonth: 10);

      final month = unwrap(await useCase(july, today: today));

      expect(month.forDay(day(10))!.status, DayAdherenceStatus.complete);
      expect(month.completeDays, 1);
    });

    test('never marks a future planned day as missed', () async {
      await plan('pm-future', 'slot-1', 28);

      final month = unwrap(await useCase(july, today: today));

      expect(month.forDay(day(28))!.status, DayAdherenceStatus.upcoming);
    });

    test('marks the reference day as inProgress while meals remain', () async {
      await plan('pm-today-1', 'slot-1', 20);
      await plan('pm-today-2', 'slot-2', 20);
      await log(id: 'e1', plannedMealId: 'pm-today-1', dayOfMonth: 20);

      final month = unwrap(await useCase(july, today: today));

      expect(month.forDay(day(20))!.status, DayAdherenceStatus.inProgress);
    });

    test('does not leak entries or meals across day boundaries', () async {
      await plan('pm-10', 'slot-1', 10);
      await plan('pm-11', 'slot-1', 11);
      await log(id: 'e-10', plannedMealId: 'pm-10', dayOfMonth: 10);

      final month = unwrap(await useCase(july, today: today));

      expect(month.forDay(day(10))!.status, DayAdherenceStatus.complete);
      expect(month.forDay(day(11))!.status, DayAdherenceStatus.missed);
    });

    test(
      'excludes upcoming and in-progress days from the completion ratio',
      () async {
        // Two settled days: the 10th met, the 11th missed.
        await plan('pm-10', 'slot-1', 10);
        await log(id: 'e-10', plannedMealId: 'pm-10', dayOfMonth: 10);
        await plan('pm-11', 'slot-1', 11);
        // One in-progress day and one upcoming day, neither judged.
        await plan('pm-20', 'slot-1', 20);
        await plan('pm-28', 'slot-1', 28);

        final month = unwrap(await useCase(july, today: today));

        expect(month.plannedDays, 4);
        expect(month.settledDays, 2);
        expect(month.completeDays, 1);
        expect(month.completionRatio, 0.5);
      },
    );

    test('yields a zero ratio when no day has settled yet', () async {
      await plan('pm-28', 'slot-1', 28);

      final month = unwrap(await useCase(july, today: today));

      expect(month.settledDays, 0);
      expect(month.completionRatio, 0);
    });

    test('propagates a source failure unchanged', () async {
      final failing = GetMonthAdherence(
        dietPlanSource: dietSource,
        nutritionSource: _FailingNutritionSource(),
        slotDirectory: slotDirectory,
      );

      final result = await failing(july, today: today);

      expect(
        result,
        const Err<MonthAdherence, NutritionFailure>(
          StorageFailure('range read failed'),
        ),
      );
    });
  });
}

class _FailingNutritionSource extends FakeNutritionSource {
  @override
  Future<Result<List<NutritionEntry>, NutritionFailure>> entriesBetween(
    NutritionDay from,
    NutritionDay to,
  ) async {
    return const Err(StorageFailure('range read failed'));
  }
}
