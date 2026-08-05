import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/adherence_tolerance.dart';

void main() {
  group('AdherenceTolerance', () {
    const tolerance = AdherenceTolerance.standard;

    test('defaults to +/-15% with a 7 g / 75 kcal absolute floor', () {
      expect(tolerance.relativeFraction, 0.15);
      expect(tolerance.macroFloorG, 7);
      expect(tolerance.energyFloorKcal, 75);
    });

    group('acceptsMacro', () {
      test('accepts an exact match', () {
        expect(tolerance.acceptsMacro(target: 40, actual: 40), isTrue);
      });

      test('accepts drift inside the relative fraction', () {
        // 15% of 100 g is 15 g.
        expect(tolerance.acceptsMacro(target: 100, actual: 114), isTrue);
        expect(tolerance.acceptsMacro(target: 100, actual: 86), isTrue);
      });

      test('accepts drift exactly on the relative boundary', () {
        expect(tolerance.acceptsMacro(target: 100, actual: 115), isTrue);
        expect(tolerance.acceptsMacro(target: 100, actual: 85), isTrue);
      });

      test('rejects drift beyond the relative fraction on a large target', () {
        expect(tolerance.acceptsMacro(target: 100, actual: 116), isFalse);
        expect(tolerance.acceptsMacro(target: 100, actual: 84), isFalse);
      });

      test('accepts small-target drift via the absolute floor, where a pure '
          'percentage would be unachievable', () {
        // 15% of 8 g is 1.2 g — nobody hits that by hand. The 7 g floor is
        // what keeps small meals from failing every single day.
        expect(tolerance.acceptsMacro(target: 8, actual: 14), isTrue);
        expect(tolerance.acceptsMacro(target: 8, actual: 2), isTrue);
      });

      test('rejects small-target drift beyond the absolute floor', () {
        expect(tolerance.acceptsMacro(target: 8, actual: 16), isFalse);
      });

      test('accepts anything within the floor of a zero target', () {
        expect(tolerance.acceptsMacro(target: 0, actual: 7), isTrue);
        expect(tolerance.acceptsMacro(target: 0, actual: 8), isFalse);
      });
    });

    group('acceptsEnergy', () {
      test('uses the kcal floor, not the macro floor', () {
        // 15% of 300 kcal is 45 kcal, so the 75 kcal floor is the generous one.
        expect(tolerance.acceptsEnergy(target: 300, actual: 370), isTrue);
        expect(tolerance.acceptsEnergy(target: 300, actual: 376), isFalse);
      });

      test('uses the relative fraction on large targets', () {
        // 15% of 1000 kcal is 150 kcal, which beats the 75 kcal floor.
        expect(tolerance.acceptsEnergy(target: 1000, actual: 1140), isTrue);
        expect(tolerance.acceptsEnergy(target: 1000, actual: 1160), isFalse);
      });
    });

    test('honours a custom, stricter criterion', () {
      const strict = AdherenceTolerance(
        relativeFraction: 0.05,
        macroFloorG: 1,
        energyFloorKcal: 10,
      );

      expect(strict.acceptsMacro(target: 100, actual: 106), isFalse);
      expect(strict.acceptsMacro(target: 100, actual: 104), isTrue);
    });

    test('two tolerances with the same fields are equal', () {
      expect(
        const AdherenceTolerance(),
        const AdherenceTolerance(
          relativeFraction: 0.15,
          macroFloorG: 7,
          energyFloorKcal: 75,
        ),
      );
    });
  });

  group('AdherenceTolerance.daily', () {
    const dailyTolerance = AdherenceTolerance.daily;

    test('is a tighter 10% band with zero macro and energy floors', () {
      expect(dailyTolerance.relativeFraction, 0.10);
      expect(dailyTolerance.macroFloorG, 0);
      expect(dailyTolerance.energyFloorKcal, 0);
    });

    test('rejects any drift on a zero target — no floor to rescue it', () {
      expect(dailyTolerance.acceptsMacro(target: 0, actual: 0), isTrue);
      expect(dailyTolerance.acceptsMacro(target: 0, actual: 1), isFalse);
    });

    test('accepts drift inside 10% of a large target', () {
      expect(dailyTolerance.acceptsEnergy(target: 2000, actual: 2200), isTrue);
      expect(dailyTolerance.acceptsEnergy(target: 2000, actual: 1800), isTrue);
    });

    test('rejects drift just beyond the 10% boundary', () {
      expect(
        dailyTolerance.acceptsEnergy(target: 2000, actual: 2201),
        isFalse,
      );
    });

    test('is a distinct, independent criterion from .standard', () {
      expect(dailyTolerance, isNot(AdherenceTolerance.standard));
    });
  });
}
