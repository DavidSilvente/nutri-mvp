import 'nutrition_target.dart';

/// Per-macro tolerance: a component is within tolerance when its deviation
/// is at most the larger of [floorG] grams or [relativeFraction] of the
/// target — the same "relative OR absolute floor, whichever is more
/// generous" shape as [AdherenceTolerance], applied to a single macro.
class MacroTolerance {
  const MacroTolerance({required this.relativeFraction, required this.floorG})
    : assert(relativeFraction >= 0, 'relativeFraction must be >= 0'),
      assert(floorG >= 0, 'floorG must be >= 0');

  /// Fraction of the target accepted as drift (0.10 == +/-10%).
  final double relativeFraction;

  /// Absolute grams always accepted, regardless of target size.
  final num floorG;

  /// Whether [actualG] is close enough to [targetG].
  bool accepts({required num targetG, required num actualG}) {
    final drift = (actualG.toDouble() - targetG.toDouble()).abs();
    if (drift <= floorG.toDouble()) return true;
    return drift <= targetG.toDouble().abs() * relativeFraction;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MacroTolerance &&
          other.relativeFraction == relativeFraction &&
          other.floorG == floorG);

  @override
  int get hashCode => Object.hash(relativeFraction, floorG);
}

/// Signed per-macro deltas (candidate minus target) and whether any of them
/// breaches a [SwapTolerance].
class MacroDeviation {
  const MacroDeviation({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.isOffTarget,
  });

  /// Candidate protein minus target protein, in grams. Positive means the
  /// candidate has more protein than the meal it would replace.
  final double proteinG;

  /// Candidate carbs minus target carbs, in grams.
  final double carbsG;

  /// Candidate fat minus target fat, in grams.
  final double fatG;

  /// Whether protein, carbs, or fat breaches its own [MacroTolerance].
  final bool isOffTarget;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MacroDeviation &&
          other.proteinG == proteinG &&
          other.carbsG == carbsG &&
          other.fatG == fatG &&
          other.isOffTarget == isOffTarget);

  @override
  int get hashCode => Object.hash(proteinG, carbsG, fatG, isOffTarget);

  @override
  String toString() =>
      'MacroDeviation(proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, '
      'isOffTarget: $isOffTarget)';
}

/// How far a ranked swap candidate (a plan substitute or a saved meal) may
/// drift from the planned meal's target macros before it is labelled "off
/// target".
///
/// Deliberately NOT [AdherenceTolerance]: that measures whether a LOGGED day
/// counted as met, using one symmetric fraction/floor plus an energy term
/// over stored history. This is a pre-decision hint rendered on a candidate
/// row before the user picks anything, with tighter, per-macro numbers and no
/// energy term (`SubstitutionEngine` already excludes energy from ranking).
/// Widening `AdherenceTolerance` to also cover this would silently change
/// what "met" means for logged days that have nothing to do with browsing
/// alternatives.
class SwapTolerance {
  const SwapTolerance({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Protein: +/-10% or +/-3 g, whichever is more generous. Carbs and fat:
  /// +/-15% or +/-5 g. Protein gets the tighter band because it is usually
  /// the macro a swap is chosen to protect.
  static const standard = SwapTolerance(
    protein: MacroTolerance(relativeFraction: 0.10, floorG: 3),
    carbs: MacroTolerance(relativeFraction: 0.15, floorG: 5),
    fat: MacroTolerance(relativeFraction: 0.15, floorG: 5),
  );

  final MacroTolerance protein;
  final MacroTolerance carbs;
  final MacroTolerance fat;

  /// Evaluates [candidate]'s macros against [target], returning the signed
  /// per-macro deltas and whether any of them breaches its own tolerance.
  MacroDeviation evaluate({
    required NutritionTarget target,
    required NutritionTarget candidate,
  }) {
    final targetMacros = target.macros;
    final candidateMacros = candidate.macros;

    final proteinDelta =
        candidateMacros.proteinG.toDouble() - targetMacros.proteinG.toDouble();
    final carbsDelta =
        candidateMacros.carbsG.toDouble() - targetMacros.carbsG.toDouble();
    final fatDelta =
        candidateMacros.fatG.toDouble() - targetMacros.fatG.toDouble();

    final proteinOk = protein.accepts(
      targetG: targetMacros.proteinG,
      actualG: candidateMacros.proteinG,
    );
    final carbsOk = carbs.accepts(
      targetG: targetMacros.carbsG,
      actualG: candidateMacros.carbsG,
    );
    final fatOk = fat.accepts(
      targetG: targetMacros.fatG,
      actualG: candidateMacros.fatG,
    );

    return MacroDeviation(
      proteinG: proteinDelta,
      carbsG: carbsDelta,
      fatG: fatDelta,
      isOffTarget: !proteinOk || !carbsOk || !fatOk,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SwapTolerance &&
          other.protein == protein &&
          other.carbs == carbs &&
          other.fat == fat);

  @override
  int get hashCode => Object.hash(protein, carbs, fat);
}
