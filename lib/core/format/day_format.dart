import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// Date wording, kept dependency-free.
///
/// The app has no `intl` dependency and only ever renders English, so a small
/// lookup beats pulling in locale machinery it would not use.
class DayFormat {
  const DayFormat._();

  static const _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String monthName(int month) => _months[month - 1];

  /// "Friday, 24 July"
  static String dayAndMonth(NutritionDay day) {
    final weekday = DateTime(day.year, day.month, day.day).weekday;
    return '${_weekdays[weekday - 1]}, ${day.day} ${monthName(day.month)}';
  }

  /// "24 July 2026"
  static String full(NutritionDay day) =>
      '${day.day} ${monthName(day.month)} ${day.year}';

  /// The heading for a day view: "Today" reads better than the date when it
  /// is in fact today.
  static String heading(NutritionDay day, NutritionDay today) {
    if (day == today) return 'Today';
    if (day.epochDay == today.epochDay - 1) return 'Yesterday';
    if (day.epochDay == today.epochDay + 1) return 'Tomorrow';
    return dayAndMonth(day);
  }
}
