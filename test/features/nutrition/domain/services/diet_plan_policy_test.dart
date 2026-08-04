import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/diet_plan_policy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('DietPlanPolicy', () {
    final target = NutritionTarget(
      energy: Energy(kcal: 700),
      macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
    );

    final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));

    test('allows a unique planned meal for a day', () {
      final meal = PlannedMeal(
        id: 'meal-1',
        slotId: 'slot-1',
        day: day,
        targetSnapshot: target,
      );

      final result = DietPlanPolicy.ensureUniqueSameDaySlot(
        meal,
        [],
      );

      expect(result, isA<Ok<PlannedMeal, NutritionFailure>>());
      final ok = result as Ok<PlannedMeal, NutritionFailure>;
      expect(ok.value, meal);
    });

    test('rejects a duplicate same-day slot assignment', () {
      final existing = [
        PlannedMeal(
          id: 'meal-1',
          slotId: 'slot-1',
          day: day,
          targetSnapshot: target,
        ),
      ];

      final candidate = PlannedMeal(
        id: 'meal-2',
        slotId: 'slot-1',
        day: day,
        targetSnapshot: target,
      );

      final result = DietPlanPolicy.ensureUniqueSameDaySlot(
        candidate,
        existing,
      );

      expect(result, isA<Err<PlannedMeal, NutritionFailure>>());
      final err = result as Err<PlannedMeal, NutritionFailure>;
      expect(err.failure, isA<ConflictFailure>());
      expect(
        (err.failure as ConflictFailure).reason,
        'Slot is already planned for this day',
      );
    });

    test('allows the same slot on different days', () {
      final existing = [
        PlannedMeal(
          id: 'meal-1',
          slotId: 'slot-1',
          day: day,
          targetSnapshot: target,
        ),
      ];

      final candidate = PlannedMeal(
        id: 'meal-2',
        slotId: 'slot-1',
        day: NutritionDay.fromDateTime(DateTime(2026, 8, 2)),
        targetSnapshot: target,
      );

      final result = DietPlanPolicy.ensureUniqueSameDaySlot(
        candidate,
        existing,
      );

      expect(result, isA<Ok<PlannedMeal, NutritionFailure>>());
    });

    test('allows the same day with different slots', () {
      final existing = [
        PlannedMeal(
          id: 'meal-1',
          slotId: 'slot-1',
          day: day,
          targetSnapshot: target,
        ),
      ];

      final candidate = PlannedMeal(
        id: 'meal-2',
        slotId: 'slot-2',
        day: day,
        targetSnapshot: target,
      );

      final result = DietPlanPolicy.ensureUniqueSameDaySlot(
        candidate,
        existing,
      );

      expect(result, isA<Ok<PlannedMeal, NutritionFailure>>());
    });

    test('allows updating an existing planned meal', () {
      final meal = PlannedMeal(
        id: 'meal-1',
        slotId: 'slot-1',
        day: day,
        targetSnapshot: target,
      );

      final result = DietPlanPolicy.ensureUniqueSameDaySlot(
        meal,
        [meal],
      );

      expect(result, isA<Ok<PlannedMeal, NutritionFailure>>());
    });

    test('does not constrain meals without a day', () {
      final existing = [
        PlannedMeal(
          id: 'meal-1',
          slotId: 'slot-1',
          targetSnapshot: target,
        ),
      ];

      final candidate = PlannedMeal(
        id: 'meal-2',
        slotId: 'slot-1',
        targetSnapshot: target,
      );

      final result = DietPlanPolicy.ensureUniqueSameDaySlot(
        candidate,
        existing,
      );

      expect(result, isA<Ok<PlannedMeal, NutritionFailure>>());
    });
  });
}
