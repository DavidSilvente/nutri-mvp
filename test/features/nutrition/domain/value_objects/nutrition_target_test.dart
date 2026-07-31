import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('NutritionTarget', () {
    test('composes an energy target and a macro target', () {
      final target = NutritionTarget(
        energy: Energy(kcal: 700),
        macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
      );

      expect(target.energy, Energy(kcal: 700));
      expect(target.macros, Macros(proteinG: 40, carbsG: 60, fatG: 20));
    });

    test('two instances with the same values are equal', () {
      final a = NutritionTarget(
        energy: Energy(kcal: 2200),
        macros: Macros(proteinG: 150, carbsG: 250, fatG: 70),
      );
      final b = NutritionTarget(
        energy: Energy(kcal: 2200),
        macros: Macros(proteinG: 150, carbsG: 250, fatG: 70),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('sums a list of targets component by component', () {
      final total = NutritionTarget.sum([
        NutritionTarget(
          energy: Energy(kcal: 700),
          macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
        ),
        NutritionTarget(
          energy: Energy(kcal: 800),
          macros: Macros(proteinG: 50, carbsG: 80, fatG: 30),
        ),
      ]);

      expect(total.energy, Energy(kcal: 1500));
      expect(total.macros, Macros(proteinG: 90, carbsG: 140, fatG: 50));
    });

    test('sum of an empty list yields zero targets', () {
      final total = NutritionTarget.sum([]);

      expect(total.energy, Energy(kcal: 0));
      expect(total.macros, Macros(proteinG: 0, carbsG: 0, fatG: 0));
    });

    test('equalsWithinTolerance accepts values within 0.01 units', () {
      final daily = NutritionTarget(
        energy: Energy(kcal: 2200),
        macros: Macros(proteinG: 150, carbsG: 250, fatG: 70),
      );
      final summed = NutritionTarget(
        energy: Energy(kcal: 2200.005),
        macros: Macros(proteinG: 150.005, carbsG: 249.995, fatG: 70),
      );

      expect(daily.equalsWithinTolerance(summed), isTrue);
    });

    test('equalsWithinTolerance rejects values beyond 0.01 units', () {
      final daily = NutritionTarget(
        energy: Energy(kcal: 2200),
        macros: Macros(proteinG: 150, carbsG: 250, fatG: 70),
      );
      final summed = NutritionTarget(
        energy: Energy(kcal: 2200.02),
        macros: Macros(proteinG: 150, carbsG: 250, fatG: 70),
      );

      expect(daily.equalsWithinTolerance(summed), isFalse);
    });
  });
}
