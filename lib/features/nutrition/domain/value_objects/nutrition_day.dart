/// A calendar-only day (no time-of-day, no timezone drift), used to group
/// and query nutrition entries by day.
class NutritionDay {
  NutritionDay._(this.year, this.month, this.day);

  /// Builds a [NutritionDay] from a [DateTime], discarding the time
  /// component and keeping only the calendar date.
  factory NutritionDay.fromDateTime(DateTime dateTime) {
    return NutritionDay._(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Rebuilds a [NutritionDay] from the [epochDay] key.
  ///
  /// The inverse of [epochDay], so a day round-trips through local storage
  /// without going back through a `DateTime` in local time.
  factory NutritionDay.fromEpochDay(int epochDay) {
    final utc = DateTime.fromMillisecondsSinceEpoch(
      epochDay * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return NutritionDay._(utc.year, utc.month, utc.day);
  }

  final int year;
  final int month;
  final int day;

  /// A stable integer key for this calendar date, suitable for indexing
  /// (e.g. as a column in local storage).
  int get epochDay =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// ISO weekday, 1 = Monday .. 7 = Sunday.
  ///
  /// Read in UTC deliberately: this value object has no timezone, and computing
  /// it from a local `DateTime` would shift the weekday for dates near
  /// midnight in some zones.
  int get weekday => DateTime.utc(year, month, day).weekday;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionDay &&
          other.year == year &&
          other.month == month &&
          other.day == day);

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      'NutritionDay($year-${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')})';
}
