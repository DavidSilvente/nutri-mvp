import 'nutrition_day.dart';

/// A single calendar month, used as the query window for the diet calendar.
///
/// Exists so the UI can ask for "July 2026" instead of juggling first/last
/// day arithmetic at every call site — and so month boundaries are computed
/// in exactly one place.
class CalendarMonth {
  CalendarMonth({required this.year, required this.month}) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be between 1 and 12');
    }
  }

  /// The month containing [dateTime].
  factory CalendarMonth.fromDateTime(DateTime dateTime) =>
      CalendarMonth(year: dateTime.year, month: dateTime.month);

  /// The month containing [day].
  factory CalendarMonth.fromDay(NutritionDay day) =>
      CalendarMonth(year: day.year, month: day.month);

  final int year;
  final int month;

  NutritionDay get firstDay =>
      NutritionDay.fromDateTime(DateTime(year, month, 1));

  /// The last day of the month. `DateTime(y, m + 1, 0)` normalises to the
  /// final day of month `m`, which also handles December and leap years.
  NutritionDay get lastDay =>
      NutritionDay.fromDateTime(DateTime(year, month + 1, 0));

  int get lengthInDays => DateTime(year, month + 1, 0).day;

  /// Weekday of [firstDay], Monday == 1 through Sunday == 7. Used to compute
  /// the leading blanks of a Monday-first calendar grid.
  int get firstWeekday => DateTime(year, month, 1).weekday;

  /// Every day of the month, in ascending order.
  List<NutritionDay> get days => List.unmodifiable([
    for (var d = 1; d <= lengthInDays; d++)
      NutritionDay.fromDateTime(DateTime(year, month, d)),
  ]);

  bool contains(NutritionDay day) => day.year == year && day.month == month;

  /// The month before this one, rolling the year over at January.
  CalendarMonth get previous => month == 1
      ? CalendarMonth(year: year - 1, month: 12)
      : CalendarMonth(year: year, month: month - 1);

  /// The month after this one, rolling the year over at December.
  CalendarMonth get next => month == 12
      ? CalendarMonth(year: year + 1, month: 1)
      : CalendarMonth(year: year, month: month + 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarMonth && other.year == year && other.month == month);

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() =>
      'CalendarMonth($year-${month.toString().padLeft(2, '0')})';
}
