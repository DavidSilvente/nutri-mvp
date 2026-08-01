/// Formatting helpers for nutrition amounts.
///
/// Stored values are doubles, so a plain `toString()` renders "500.0 kcal" and
/// "39.99999999 g". Both read as noise in a UI where one decimal is already
/// more precision than a kitchen scale gives.
class NutritionFormat {
  const NutritionFormat._();

  /// Renders [amount] with at most one decimal, dropping a trailing ".0".
  static String amount(num amount) {
    final rounded = (amount * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toStringAsFixed(1);
  }

  /// "540 kcal"
  static String kcal(num value) => '${amount(value)} kcal';

  /// "40 g"
  static String grams(num value) => '${amount(value)} g';

  /// "540 / 600 kcal"
  static String kcalOf(num value, num target) =>
      '${amount(value)} / ${amount(target)} kcal';
}
