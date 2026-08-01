/// How much of a food a meal component calls for.
///
/// [grams] is the single source of truth for every macro calculation, because
/// the food table is expressed per 100 g. [count] and [unit] are the
/// human-facing wording the plan used ("2 porciones", "1 lata redonda
/// pequeña"), kept so the UI can echo the plan verbatim instead of translating
/// everything into grams.
///
/// A diet plan that writes `3 unidades medianas de huevo de gallina (150 g)`
/// means 150 g IN TOTAL, not 150 g each. Parsers MUST treat a parenthesised
/// weight as the total for the whole quantity, never as a per-unit weight.
class FoodQuantity {
  FoodQuantity({required this.grams, this.count, this.unit}) {
    if (grams <= 0) {
      throw ArgumentError.value(grams, 'grams', 'must be > 0');
    }
    if (count != null && count! <= 0) {
      throw ArgumentError.value(count, 'count', 'must be > 0 when present');
    }
    if (unit != null && unit!.trim().isEmpty) {
      throw ArgumentError.value(unit, 'unit', 'must not be blank when present');
    }
  }

  /// Total weight in grams, for the whole quantity.
  final num grams;

  /// Number of human-facing units, when the plan expressed one (e.g. `2` for
  /// "2 porciones"). May be fractional (`0.5` for "1/2 unidad").
  final num? count;

  /// The human-facing unit the plan used (e.g. `porcion`, `unidad mediana`).
  final String? unit;

  /// The multiplier to apply to a per-100 g macro value.
  double get per100gFactor => grams.toDouble() / 100.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodQuantity &&
          other.grams == grams &&
          other.count == count &&
          other.unit == unit);

  @override
  int get hashCode => Object.hash(grams, count, unit);

  @override
  String toString() =>
      'FoodQuantity(grams: $grams, count: $count, unit: $unit)';
}
