/// How far a logged intake may drift from its planned target and still count
/// as met.
///
/// A component is accepted when it is within [relativeFraction] of the target
/// **OR** within an absolute floor — whichever is more generous. The absolute
/// floor exists because a pure percentage is unusable on small components: 15%
/// of an 8 g fat target is 1.2 g, which no one can hit by hand, so every day
/// would read as a failure. A criterion that is never met does not measure
/// adherence, it just demotivates.
///
/// This is deliberately NOT [NutritionTarget.equalsWithinTolerance], which
/// uses an ABSOLUTE 0.01-unit tolerance to validate that template slot targets
/// sum exactly to the daily target. That is an arithmetic invariant; this is a
/// human one. Conflating them would silently loosen template validation.
class AdherenceTolerance {
  const AdherenceTolerance({
    this.relativeFraction = 0.15,
    this.macroFloorG = 7,
    this.energyFloorKcal = 75,
  }) : assert(relativeFraction >= 0, 'relativeFraction must be >= 0'),
       assert(macroFloorG >= 0, 'macroFloorG must be >= 0'),
       assert(energyFloorKcal >= 0, 'energyFloorKcal must be >= 0');

  /// The default criterion: ±15% or ±7 g per macro, ±15% or ±75 kcal.
  static const standard = AdherenceTolerance();

  /// The day-verdict criterion: a tighter ±10% with no absolute floor.
  ///
  /// Unlike [standard], this is judged against a DAILY total, not a single
  /// small component, so the floor that keeps a snack achievable is noise
  /// here — the whole point of a floor is to rescue small numbers, and a
  /// day's total is never small.
  static const daily = AdherenceTolerance(
    relativeFraction: 0.10,
    macroFloorG: 0,
    energyFloorKcal: 0,
  );

  /// Fraction of the target accepted as drift (0.15 == ±15%).
  final double relativeFraction;

  /// Absolute grams always accepted per macro, regardless of target size.
  final num macroFloorG;

  /// Absolute kcal always accepted, regardless of target size.
  final num energyFloorKcal;

  /// Whether [actual] grams are close enough to [target] grams.
  bool acceptsMacro({required num target, required num actual}) =>
      _accepts(target: target, actual: actual, floor: macroFloorG);

  /// Whether [actual] kcal are close enough to [target] kcal.
  bool acceptsEnergy({required num target, required num actual}) =>
      _accepts(target: target, actual: actual, floor: energyFloorKcal);

  bool _accepts({
    required num target,
    required num actual,
    required num floor,
  }) {
    final drift = (actual.toDouble() - target.toDouble()).abs();
    if (drift <= floor.toDouble()) return true;
    return drift <= target.toDouble().abs() * relativeFraction;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdherenceTolerance &&
          other.relativeFraction == relativeFraction &&
          other.macroFloorG == macroFloorG &&
          other.energyFloorKcal == energyFloorKcal);

  @override
  int get hashCode =>
      Object.hash(relativeFraction, macroFloorG, energyFloorKcal);

  @override
  String toString() =>
      'AdherenceTolerance(relativeFraction: $relativeFraction, '
      'macroFloorG: $macroFloorG, energyFloorKcal: $energyFloorKcal)';
}
