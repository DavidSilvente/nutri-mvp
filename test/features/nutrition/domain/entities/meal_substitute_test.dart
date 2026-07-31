import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('MealSubstitute', () {
    final target = NutritionTarget(
      energy: Energy(kcal: 250),
      macros: Macros(proteinG: 20, carbsG: 30, fatG: 10),
    );

    test('builds a substitute scoped to a planned meal', () {
      final substitute = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-1',
        label: 'Tofu (200g)',
        target: target,
      );

      expect(substitute.id, 'sub-1');
      expect(substitute.plannedMealId, 'meal-1');
      expect(substitute.label, 'Tofu (200g)');
      expect(substitute.target, target);
    });

    test('rejects an empty label', () {
      expect(
        () => MealSubstitute(
          id: 'sub-1',
          plannedMealId: 'meal-1',
          label: '',
          target: target,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('two substitutes with the same fields are equal', () {
      final a = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-1',
        label: 'Tofu (200g)',
        target: target,
      );
      final b = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-1',
        label: 'Tofu (200g)',
        target: target,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('substitutes with different planned meal ids are not equal', () {
      final a = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-1',
        label: 'Tofu (200g)',
        target: target,
      );
      final b = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-2',
        label: 'Tofu (200g)',
        target: target,
      );

      expect(a, isNot(b));
    });
  });
}
