/// Macronutrient breakdown of an intake, in grams.
///
/// [proteinG], [carbsG] and [fatG] MUST all be non-negative.
class Macros {
  Macros({required this.proteinG, required this.carbsG, required this.fatG}) {
    if (proteinG < 0) {
      throw ArgumentError.value(proteinG, 'proteinG', 'must be >= 0');
    }
    if (carbsG < 0) {
      throw ArgumentError.value(carbsG, 'carbsG', 'must be >= 0');
    }
    if (fatG < 0) {
      throw ArgumentError.value(fatG, 'fatG', 'must be >= 0');
    }
  }

  final num proteinG;
  final num carbsG;
  final num fatG;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Macros &&
          other.proteinG == proteinG &&
          other.carbsG == carbsG &&
          other.fatG == fatG);

  @override
  int get hashCode => Object.hash(proteinG, carbsG, fatG);

  @override
  String toString() =>
      'Macros(proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG)';
}
