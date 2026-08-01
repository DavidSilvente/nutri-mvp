import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/calendar_month.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

void main() {
  group('CalendarMonth', () {
    test('rejects a month outside 1..12', () {
      expect(
        () => CalendarMonth(year: 2026, month: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => CalendarMonth(year: 2026, month: 13),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('exposes first and last day of a 31-day month', () {
      final july = CalendarMonth(year: 2026, month: 7);

      expect(july.firstDay, NutritionDay.fromDateTime(DateTime(2026, 7, 1)));
      expect(july.lastDay, NutritionDay.fromDateTime(DateTime(2026, 7, 31)));
      expect(july.lengthInDays, 31);
    });

    test('handles February in a leap year', () {
      final february = CalendarMonth(year: 2028, month: 2);

      expect(february.lengthInDays, 29);
      expect(
        february.lastDay,
        NutritionDay.fromDateTime(DateTime(2028, 2, 29)),
      );
    });

    test('handles February in a non-leap year', () {
      expect(CalendarMonth(year: 2026, month: 2).lengthInDays, 28);
    });

    test('handles December, where the next month rolls the year', () {
      final december = CalendarMonth(year: 2026, month: 12);

      expect(december.lengthInDays, 31);
      expect(
        december.lastDay,
        NutritionDay.fromDateTime(DateTime(2026, 12, 31)),
      );
      expect(december.next, CalendarMonth(year: 2027, month: 1));
    });

    test('rolls the year backwards at January', () {
      expect(
        CalendarMonth(year: 2026, month: 1).previous,
        CalendarMonth(year: 2025, month: 12),
      );
    });

    test('lists every day of the month in ascending order', () {
      final days = CalendarMonth(year: 2026, month: 2).days;

      expect(days, hasLength(28));
      expect(days.first, NutritionDay.fromDateTime(DateTime(2026, 2, 1)));
      expect(days.last, NutritionDay.fromDateTime(DateTime(2026, 2, 28)));
    });

    test('reports the weekday the month starts on, Monday first', () {
      // 1 July 2026 is a Wednesday.
      expect(CalendarMonth(year: 2026, month: 7).firstWeekday, 3);
    });

    test('contains only days of its own month and year', () {
      final july = CalendarMonth(year: 2026, month: 7);

      expect(
        july.contains(NutritionDay.fromDateTime(DateTime(2026, 7, 31))),
        isTrue,
      );
      expect(
        july.contains(NutritionDay.fromDateTime(DateTime(2026, 8, 1))),
        isFalse,
      );
      expect(
        july.contains(NutritionDay.fromDateTime(DateTime(2025, 7, 15))),
        isFalse,
      );
    });

    test('builds from a DateTime or a NutritionDay', () {
      expect(
        CalendarMonth.fromDateTime(DateTime(2026, 7, 24, 18)),
        CalendarMonth(year: 2026, month: 7),
      );
      expect(
        CalendarMonth.fromDay(NutritionDay.fromDateTime(DateTime(2026, 7, 24))),
        CalendarMonth(year: 2026, month: 7),
      );
    });
  });
}
