import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/adherence_tolerance.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

NutritionTarget target({
  required num kcal,
  required num protein,
  required num carbs,
  required num fat,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
  );
}

PlannedMeal plannedMeal({
  required String id,
  NutritionDay? day,
  NutritionTarget? snapshot,
}) {
  return PlannedMeal(
    id: id,
    slotId: 'slot-$id',
    day: day,
    targetSnapshot:
        snapshot ?? target(kcal: 600, protein: 40, carbs: 60, fat: 20),
  );
}

NutritionEntry entry({
  required String id,
  required num kcal,
  required num protein,
  required num carbs,
  required num fat,
  String? plannedMealId,
  DateTime? recordedAt,
}) {
  return NutritionEntry(
    id: id,
    recordedAt: recordedAt ?? DateTime(2026, 7, 24, 13),
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
    plannedMealId: plannedMealId,
  );
}

void main() {
  final today = NutritionDay.fromDateTime(DateTime(2026, 7, 24));
  final yesterday = NutritionDay.fromDateTime(DateTime(2026, 7, 23));
  final tomorrow = NutritionDay.fromDateTime(DateTime(2026, 7, 25));

  group('AdherenceEvaluator.evaluateMeal', () {
    test('is pending when nothing was logged against the meal', () {
      final meal = plannedMeal(id: 'm1');

      final result = AdherenceEvaluator.evaluateMeal(meal: meal, entries: []);

      expect(result.status, MealAdherenceStatus.pending);
      expect(result.entryCount, 0);
      expect(result.logged, target(kcal: 0, protein: 0, carbs: 0, fat: 0));
    });

    test('is onTarget when every component lands within tolerance', () {
      final meal = plannedMeal(id: 'm1');

      final result = AdherenceEvaluator.evaluateMeal(
        meal: meal,
        entries: [
          entry(
            id: 'e1',
            kcal: 640,
            protein: 44,
            carbs: 56,
            fat: 22,
            plannedMealId: 'm1',
          ),
        ],
      );

      expect(result.status, MealAdherenceStatus.onTarget);
      expect(result.entryCount, 1);
    });

    test('is off when a single component falls out of tolerance', () {
      final meal = plannedMeal(id: 'm1');

      // Energy, protein and carbs are fine; fat is 20 -> 40 g, which beats
      // both the 15% and the 7 g allowances.
      final result = AdherenceEvaluator.evaluateMeal(
        meal: meal,
        entries: [
          entry(
            id: 'e1',
            kcal: 620,
            protein: 40,
            carbs: 60,
            fat: 40,
            plannedMealId: 'm1',
          ),
        ],
      );

      expect(result.status, MealAdherenceStatus.off);
    });

    test('sums every entry linked to the same meal before judging', () {
      final meal = plannedMeal(id: 'm1');

      // Neither half is on target alone; together they are.
      final result = AdherenceEvaluator.evaluateMeal(
        meal: meal,
        entries: [
          entry(
            id: 'e1',
            kcal: 300,
            protein: 20,
            carbs: 30,
            fat: 10,
            plannedMealId: 'm1',
          ),
          entry(
            id: 'e2',
            kcal: 300,
            protein: 20,
            carbs: 30,
            fat: 10,
            plannedMealId: 'm1',
          ),
        ],
      );

      expect(result.status, MealAdherenceStatus.onTarget);
      expect(result.entryCount, 2);
      expect(result.logged, target(kcal: 600, protein: 40, carbs: 60, fat: 20));
    });

    test('ignores entries linked to a different meal', () {
      final meal = plannedMeal(id: 'm1');

      final result = AdherenceEvaluator.evaluateMeal(
        meal: meal,
        entries: [
          entry(
            id: 'e1',
            kcal: 600,
            protein: 40,
            carbs: 60,
            fat: 20,
            plannedMealId: 'other-meal',
          ),
        ],
      );

      expect(result.status, MealAdherenceStatus.pending);
      expect(result.entryCount, 0);
    });

    test('ignores unlinked entries — they never count towards adherence', () {
      final meal = plannedMeal(id: 'm1');

      final result = AdherenceEvaluator.evaluateMeal(
        meal: meal,
        entries: [entry(id: 'e1', kcal: 600, protein: 40, carbs: 60, fat: 20)],
      );

      expect(result.status, MealAdherenceStatus.pending);
    });

    test('judges a small meal against the absolute floor, so a snack is not '
        'impossible to hit', () {
      final meal = plannedMeal(
        id: 'm1',
        snapshot: target(kcal: 120, protein: 10, carbs: 8, fat: 4),
      );

      // Every macro drifts more than 15% but stays inside the 7 g floor,
      // and energy stays inside the 75 kcal floor.
      final result = AdherenceEvaluator.evaluateMeal(
        meal: meal,
        entries: [
          entry(
            id: 'e1',
            kcal: 180,
            protein: 16,
            carbs: 13,
            fat: 9,
            plannedMealId: 'm1',
          ),
        ],
      );

      expect(result.status, MealAdherenceStatus.onTarget);
    });

    test(
      'judges against the frozen snapshot, honouring a custom tolerance',
      () {
        final meal = plannedMeal(id: 'm1');

        final result = AdherenceEvaluator.evaluateMeal(
          meal: meal,
          entries: [
            entry(
              id: 'e1',
              kcal: 640,
              protein: 44,
              carbs: 56,
              fat: 22,
              plannedMealId: 'm1',
            ),
          ],
          tolerance: const AdherenceTolerance(
            relativeFraction: 0.01,
            macroFloorG: 0,
            energyFloorKcal: 0,
          ),
        );

        expect(result.status, MealAdherenceStatus.off);
        expect(result.target, meal.targetSnapshot);
      },
    );
  });

  group('AdherenceEvaluator.evaluateDay', () {
    test('is unplanned when the day has no planned meals', () {
      final result = AdherenceEvaluator.evaluateDay(
        day: yesterday,
        plannedMeals: [],
        entries: [],
        today: today,
      );

      expect(result.status, DayAdherenceStatus.unplanned);
      expect(result.plannedCount, 0);
      expect(result.completionRatio, 0);
    });

    test('is complete when every planned meal is on target', () {
      final meals = [
        plannedMeal(id: 'm1', day: yesterday),
        plannedMeal(id: 'm2', day: yesterday),
      ];

      final result = AdherenceEvaluator.evaluateDay(
        day: yesterday,
        plannedMeals: meals,
        entries: [
          entry(
            id: 'e1',
            kcal: 600,
            protein: 40,
            carbs: 60,
            fat: 20,
            plannedMealId: 'm1',
          ),
          entry(
            id: 'e2',
            kcal: 600,
            protein: 40,
            carbs: 60,
            fat: 20,
            plannedMealId: 'm2',
          ),
        ],
        today: today,
      );

      expect(result.status, DayAdherenceStatus.complete);
      expect(result.onTargetCount, 2);
      expect(result.completionRatio, 1);
    });

    test('is upcoming for a future day, never a failure', () {
      final result = AdherenceEvaluator.evaluateDay(
        day: tomorrow,
        plannedMeals: [plannedMeal(id: 'm1', day: tomorrow)],
        entries: [],
        today: today,
      );

      expect(result.status, DayAdherenceStatus.upcoming);
    });

    test('is inProgress for the reference day while meals remain', () {
      final meals = [
        plannedMeal(id: 'm1', day: today),
        plannedMeal(id: 'm2', day: today),
      ];

      final result = AdherenceEvaluator.evaluateDay(
        day: today,
        plannedMeals: meals,
        entries: [
          entry(
            id: 'e1',
            kcal: 600,
            protein: 40,
            carbs: 60,
            fat: 20,
            plannedMealId: 'm1',
          ),
        ],
        today: today,
      );

      expect(result.status, DayAdherenceStatus.inProgress);
      expect(result.onTargetCount, 1);
      expect(result.completionRatio, 0.5);
    });

    test('is partial for a settled day where some meals were met', () {
      final meals = [
        plannedMeal(id: 'm1', day: yesterday),
        plannedMeal(id: 'm2', day: yesterday),
      ];

      final result = AdherenceEvaluator.evaluateDay(
        day: yesterday,
        plannedMeals: meals,
        entries: [
          entry(
            id: 'e1',
            kcal: 600,
            protein: 40,
            carbs: 60,
            fat: 20,
            plannedMealId: 'm1',
          ),
        ],
        today: today,
      );

      expect(result.status, DayAdherenceStatus.partial);
    });

    test('is missed for a settled day where no meal was met', () {
      final result = AdherenceEvaluator.evaluateDay(
        day: yesterday,
        plannedMeals: [plannedMeal(id: 'm1', day: yesterday)],
        entries: [],
        today: today,
      );

      expect(result.status, DayAdherenceStatus.missed);
      expect(result.completionRatio, 0);
    });

    test('counts a logged-but-out-of-tolerance meal as attempted, not met', () {
      final result = AdherenceEvaluator.evaluateDay(
        day: yesterday,
        plannedMeals: [plannedMeal(id: 'm1', day: yesterday)],
        entries: [
          entry(
            id: 'e1',
            kcal: 1500,
            protein: 90,
            carbs: 150,
            fat: 70,
            plannedMealId: 'm1',
          ),
        ],
        today: today,
      );

      expect(result.status, DayAdherenceStatus.missed);
      expect(result.meals.single.status, MealAdherenceStatus.off);
      expect(result.meals.single.entryCount, 1);
    });

    test('preserves the order in which planned meals were supplied', () {
      final meals = [
        plannedMeal(id: 'dinner', day: yesterday),
        plannedMeal(id: 'breakfast', day: yesterday),
      ];

      final result = AdherenceEvaluator.evaluateDay(
        day: yesterday,
        plannedMeals: meals,
        entries: [],
        today: today,
      );

      expect(result.meals.map((m) => m.plannedMeal.id), [
        'dinner',
        'breakfast',
      ]);
    });
  });
}
