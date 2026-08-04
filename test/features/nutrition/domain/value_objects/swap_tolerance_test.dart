import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/swap_tolerance.dart';

NutritionTarget _target({
  num kcal = 500,
  required num protein,
  required num carbs,
  required num fat,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
  );
}

void main() {
  group('SwapTolerance', () {
    const tolerance = SwapTolerance.standard;

    test('defaults to protein max(3g,10%); carbs/fat max(5g,15%)', () {
      expect(tolerance.protein.floorG, 3);
      expect(tolerance.protein.relativeFraction, 0.10);
      expect(tolerance.carbs.floorG, 5);
      expect(tolerance.carbs.relativeFraction, 0.15);
      expect(tolerance.fat.floorG, 5);
      expect(tolerance.fat.relativeFraction, 0.15);
    });

    group('protein — floor wins on small targets', () {
      // 10% of 20 g is 2 g, so the 3 g floor is the more generous one.
      test('exact 3 g boundary is on target', () {
        final target = _target(protein: 20, carbs: 100, fat: 100);
        final candidate = _target(protein: 23, carbs: 100, fat: 100);

        final deviation = tolerance.evaluate(
          target: target,
          candidate: candidate,
        );

        expect(deviation.proteinG, 3);
        expect(deviation.isOffTarget, isFalse);
      });

      test('just beyond the 3 g floor is off target', () {
        final target = _target(protein: 20, carbs: 100, fat: 100);
        final candidate = _target(protein: 23.1, carbs: 100, fat: 100);

        final deviation = tolerance.evaluate(
          target: target,
          candidate: candidate,
        );

        expect(deviation.isOffTarget, isTrue);
      });
    });

    group('protein — relative fraction wins on large targets', () {
      // 10% of 100 g is 10 g, which beats the 3 g floor.
      test('exact 10% boundary is on target', () {
        final target = _target(protein: 100, carbs: 200, fat: 200);
        final candidate = _target(protein: 110, carbs: 200, fat: 200);

        final deviation = tolerance.evaluate(
          target: target,
          candidate: candidate,
        );

        expect(deviation.proteinG, 10);
        expect(deviation.isOffTarget, isFalse);
      });

      test('just beyond the 10% boundary is off target', () {
        final target = _target(protein: 100, carbs: 200, fat: 200);
        final candidate = _target(protein: 110.1, carbs: 200, fat: 200);

        final deviation = tolerance.evaluate(
          target: target,
          candidate: candidate,
        );

        expect(deviation.isOffTarget, isTrue);
      });
    });

    group('carbs and fat — floor wins on small targets', () {
      // 15% of 20 g is 3 g, so the 5 g floor is the more generous one.
      test('exact 5 g boundary on both is on target', () {
        final target = _target(protein: 100, carbs: 20, fat: 20);
        final candidate = _target(protein: 100, carbs: 25, fat: 15);

        final deviation = tolerance.evaluate(
          target: target,
          candidate: candidate,
        );

        expect(deviation.carbsG, 5);
        expect(deviation.fatG, -5);
        expect(deviation.isOffTarget, isFalse);
      });

      test('just beyond the 5 g floor on carbs alone is off target', () {
        final target = _target(protein: 100, carbs: 20, fat: 20);
        final candidate = _target(protein: 100, carbs: 25.1, fat: 20);

        final deviation = tolerance.evaluate(
          target: target,
          candidate: candidate,
        );

        expect(deviation.isOffTarget, isTrue);
      });
    });

    test('carbs and fat use the relative fraction on large targets', () {
      // 15% of 100 g is 15 g, which beats the 5 g floor.
      final target = _target(protein: 100, carbs: 100, fat: 100);
      final onBoundary = _target(protein: 100, carbs: 115, fat: 115);
      final beyond = _target(protein: 100, carbs: 115.1, fat: 100);

      expect(
        tolerance.evaluate(target: target, candidate: onBoundary).isOffTarget,
        isFalse,
      );
      expect(
        tolerance.evaluate(target: target, candidate: beyond).isOffTarget,
        isTrue,
      );
    });

    test('deltas are signed: candidate minus target', () {
      final target = _target(protein: 40, carbs: 60, fat: 20);
      final candidate = _target(protein: 30, carbs: 70, fat: 20);

      final deviation = tolerance.evaluate(
        target: target,
        candidate: candidate,
      );

      expect(deviation.proteinG, -10);
      expect(deviation.carbsG, 10);
      expect(deviation.fatG, 0);
    });

    test('an exact match is never off target', () {
      final target = _target(protein: 40, carbs: 60, fat: 20);

      final deviation = tolerance.evaluate(target: target, candidate: target);

      expect(deviation.proteinG, 0);
      expect(deviation.carbsG, 0);
      expect(deviation.fatG, 0);
      expect(deviation.isOffTarget, isFalse);
    });
  });
}
