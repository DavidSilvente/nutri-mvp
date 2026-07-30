import 'energy.dart';
import 'macros.dart';

/// A nutritional target composed of an energy value and a macronutrient
/// breakdown.
///
/// The value objects are validated independently (non-negative values) by
/// [Energy] and [Macros]. This object adds component-wise composition and
/// approximate comparison with a configurable tolerance, which is used when
/// validating that a collection of targets (e.g. meal slots) sums to a daily
/// total.
class NutritionTarget {
  const NutritionTarget({required this.energy, required this.macros});

  final Energy energy;
  final Macros macros;

  /// Returns a new [NutritionTarget] whose fields are the sums of the given
  /// [targets]. An empty iterable yields a zero target.
  factory NutritionTarget.sum(Iterable<NutritionTarget> targets) {
    var energyKcal = 0.0;
    var proteinG = 0.0;
    var carbsG = 0.0;
    var fatG = 0.0;
    for (final target in targets) {
      energyKcal += target.energy.kcal.toDouble();
      proteinG += target.macros.proteinG.toDouble();
      carbsG += target.macros.carbsG.toDouble();
      fatG += target.macros.fatG.toDouble();
    }
    return NutritionTarget(
      energy: Energy(kcal: energyKcal),
      macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
    );
  }

  /// Returns `true` when every component of [other] is within [tolerance] of
  /// this target's corresponding component. The default tolerance is 0.01, the
  /// precision agreed for macro/energy sum validation.
  bool equalsWithinTolerance(NutritionTarget other, {num tolerance = 0.01}) {
    final t = tolerance.toDouble();
    return (_diff(energy.kcal, other.energy.kcal) <= t) &&
        (_diff(macros.proteinG, other.macros.proteinG) <= t) &&
        (_diff(macros.carbsG, other.macros.carbsG) <= t) &&
        (_diff(macros.fatG, other.macros.fatG) <= t);
  }

  static double _diff(num a, num b) => (a.toDouble() - b.toDouble()).abs();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionTarget &&
          other.energy == energy &&
          other.macros == macros);

  @override
  int get hashCode => Object.hash(energy, macros);

  @override
  String toString() =>
      'NutritionTarget(energy: $energy, macros: $macros)';
}
