import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

void main() {
  group('NutritionDay', () {
    test(
      'normalizes a DateTime with time-of-day to just the calendar date',
      () {
        final day = NutritionDay.fromDateTime(
          DateTime(2026, 7, 23, 18, 45, 30),
        );

        expect(day.year, 2026);
        expect(day.month, 7);
        expect(day.day, 23);
      },
    );

    test('two days built from different times on the same date are equal', () {
      final morning = NutritionDay.fromDateTime(DateTime(2026, 7, 23, 8));
      final night = NutritionDay.fromDateTime(DateTime(2026, 7, 23, 23, 59));

      expect(morning, night);
      expect(morning.hashCode, night.hashCode);
    });

    test('two days on different dates are not equal', () {
      final day1 = NutritionDay.fromDateTime(DateTime(2026, 7, 23));
      final day2 = NutritionDay.fromDateTime(DateTime(2026, 7, 24));

      expect(day1, isNot(day2));
    });

    test(
      'epochDay is stable for the same calendar date regardless of time',
      () {
        final morning = NutritionDay.fromDateTime(DateTime(2026, 7, 23, 1));
        final night = NutritionDay.fromDateTime(DateTime(2026, 7, 23, 23));

        expect(morning.epochDay, night.epochDay);
      },
    );
  });
}
