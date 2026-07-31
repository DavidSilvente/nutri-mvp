import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('PlannedMeal', () {
    final snapshot = NutritionTarget(
      energy: Energy(kcal: 700),
      macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
    );

    test('builds a planned meal with a slot snapshot and a day', () {
      final meal = PlannedMeal(
        id: 'meal-1',
        slotId: 'slot-1',
        day: NutritionDay.fromDateTime(DateTime(2026, 8, 1)),
        targetSnapshot: snapshot,
      );

      expect(meal.id, 'meal-1');
      expect(meal.slotId, 'slot-1');
      expect(meal.day, NutritionDay.fromDateTime(DateTime(2026, 8, 1)));
      expect(meal.targetSnapshot, snapshot);
    });

    test('allows a planned meal without an assigned day', () {
      final meal = PlannedMeal(
        id: 'meal-1',
        slotId: 'slot-1',
        targetSnapshot: snapshot,
      );

      expect(meal.day, isNull);
    });

    test('two planned meals with the same fields are equal', () {
      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final a = PlannedMeal(
        id: 'meal-1',
        slotId: 'slot-1',
        day: day,
        targetSnapshot: snapshot,
      );
      final b = PlannedMeal(
        id: 'meal-1',
        slotId: 'slot-1',
        day: day,
        targetSnapshot: snapshot,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('planned meals with different ids are not equal', () {
      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final a = PlannedMeal(
        id: 'meal-1',
        slotId: 'slot-1',
        day: day,
        targetSnapshot: snapshot,
      );
      final b = PlannedMeal(
        id: 'meal-2',
        slotId: 'slot-1',
        day: day,
        targetSnapshot: snapshot,
      );

      expect(a, isNot(b));
    });

  });
}
