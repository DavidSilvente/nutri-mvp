import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('DietTemplate', () {
    final breakfastTarget = NutritionTarget(
      energy: Energy(kcal: 700),
      macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
    );
    final lunchTarget = NutritionTarget(
      energy: Energy(kcal: 800),
      macros: Macros(proteinG: 50, carbsG: 80, fatG: 30),
    );
    final dailyTarget = NutritionTarget(
      energy: Energy(kcal: 1500),
      macros: Macros(proteinG: 90, carbsG: 140, fatG: 50),
    );

    test('builds a template with a daily total and per-meal macro targets', () {
      final template = DietTemplate(
        id: 'template-1',
        name: 'Cut-A',
        dailyTarget: dailyTarget,
        slots: [
          DietMealSlot(
            id: 'slot-1',
            label: 'Breakfast',
            position: 0,
            target: breakfastTarget,
          ),
          DietMealSlot(
            id: 'slot-2',
            label: 'Lunch',
            position: 1,
            target: lunchTarget,
          ),
        ],
      );

      expect(template.id, 'template-1');
      expect(template.name, 'Cut-A');
      expect(template.dailyTarget, dailyTarget);
      expect(template.slots, hasLength(2));
      expect(template.slots.first.label, 'Breakfast');
      expect(template.slots.first.target, breakfastTarget);
    });

    test('rejects duplicate slot positions', () {
      expect(
        () => DietTemplate(
          id: 'template-1',
          name: 'Cut-A',
          dailyTarget: dailyTarget,
          slots: [
            DietMealSlot(
              id: 'slot-1',
              label: 'Breakfast',
              position: 0,
              target: breakfastTarget,
            ),
            DietMealSlot(
              id: 'slot-2',
              label: 'Lunch',
              position: 0,
              target: lunchTarget,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects slot targets that do not sum to the daily target', () {
      final mismatched = NutritionTarget(
        energy: Energy(kcal: 2000),
        macros: Macros(proteinG: 100, carbsG: 100, fatG: 100),
      );

      expect(
        () => DietTemplate(
          id: 'template-1',
          name: 'Cut-A',
          dailyTarget: mismatched,
          slots: [
            DietMealSlot(
              id: 'slot-1',
              label: 'Breakfast',
              position: 0,
              target: breakfastTarget,
            ),
            DietMealSlot(
              id: 'slot-2',
              label: 'Lunch',
              position: 1,
              target: lunchTarget,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts slot targets within the 0.01 tolerance of the daily target', () {
      final almostDaily = NutritionTarget(
        energy: Energy(kcal: 1500.005),
        macros: Macros(proteinG: 90.005, carbsG: 139.995, fatG: 50),
      );

      final template = DietTemplate(
        id: 'template-1',
        name: 'Cut-A',
        dailyTarget: almostDaily,
        slots: [
          DietMealSlot(
            id: 'slot-1',
            label: 'Breakfast',
            position: 0,
            target: breakfastTarget,
          ),
          DietMealSlot(
            id: 'slot-2',
            label: 'Lunch',
            position: 1,
            target: lunchTarget,
          ),
        ],
      );

      expect(template.slots, hasLength(2));
    });

    test('two templates with the same fields are equal', () {
      final a = DietTemplate(
        id: 'template-1',
        name: 'Cut-A',
        dailyTarget: breakfastTarget,
        slots: [
          DietMealSlot(
            id: 'slot-1',
            label: 'Breakfast',
            position: 0,
            target: breakfastTarget,
          ),
        ],
      );
      final b = DietTemplate(
        id: 'template-1',
        name: 'Cut-A',
        dailyTarget: breakfastTarget,
        slots: [
          DietMealSlot(
            id: 'slot-1',
            label: 'Breakfast',
            position: 0,
            target: breakfastTarget,
          ),
        ],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
