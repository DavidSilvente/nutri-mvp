import 'dart:math';

import '../value_objects/nutrition_target.dart';

/// A candidate option that can be ranked against a nutritional target.
///
/// The ranking is driven by the [target] macronutrient values; the energy
/// value stored on the target is not part of the distance calculation.
class MacroCandidate {
  MacroCandidate({required this.id, required this.label, required this.target});

  final String id;
  final String label;
  final NutritionTarget target;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MacroCandidate &&
          other.id == id &&
          other.label == label &&
          other.target == target);

  @override
  int get hashCode => Object.hash(id, label, target);

  @override
  String toString() =>
      'MacroCandidate(id: $id, label: $label, target: $target)';
}

/// A [MacroCandidate] ranked against a target, carrying the computed distance
/// and protein delta used for sorting.
class RankedOption {
  RankedOption({
    required this.id,
    required this.label,
    required this.target,
    required this.distance,
    required this.proteinDelta,
  });

  final String id;
  final String label;
  final NutritionTarget target;
  final double distance;
  final double proteinDelta;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RankedOption &&
          other.id == id &&
          other.label == label &&
          other.target == target &&
          other.distance == distance &&
          other.proteinDelta == proteinDelta);

  @override
  int get hashCode => Object.hash(id, label, target, distance, proteinDelta);

  @override
  String toString() =>
      'RankedOption(id: $id, label: $label, distance: $distance, '
      'proteinDelta: $proteinDelta)';
}

/// Pure domain service that ranks candidate options against a nutritional
/// target.
///
/// Ranking uses ascending Euclidean distance over protein, carbs and fat.
/// Ties are broken by protein proximity (smaller absolute protein delta wins),
/// and remaining ties are broken by the candidate's original input index to
/// guarantee deterministic, stable ordering.
class SubstitutionEngine {
  const SubstitutionEngine._();

  /// Ranks [candidates] against [target] and returns a new sorted list.
  ///
  /// The input list is never mutated. An empty candidate list returns an empty
  /// result.
  static List<RankedOption> rank(
    NutritionTarget target,
    List<MacroCandidate> candidates,
  ) {
    if (candidates.isEmpty) return const [];

    final targetMacros = target.macros;

    final scored =
        <({int index, RankedOption option, double squaredDistance})>[];
    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final macros = candidate.target.macros;
      final pDiff =
          macros.proteinG.toDouble() - targetMacros.proteinG.toDouble();
      final cDiff = macros.carbsG.toDouble() - targetMacros.carbsG.toDouble();
      final fDiff = macros.fatG.toDouble() - targetMacros.fatG.toDouble();
      final squaredDistance = pDiff * pDiff + cDiff * cDiff + fDiff * fDiff;
      final proteinDelta = pDiff.abs();

      scored.add((
        index: i,
        option: RankedOption(
          id: candidate.id,
          label: candidate.label,
          target: candidate.target,
          distance: sqrt(squaredDistance),
          proteinDelta: proteinDelta,
        ),
        squaredDistance: squaredDistance,
      ));
    }

    scored.sort((a, b) {
      final distanceCmp = a.squaredDistance.compareTo(b.squaredDistance);
      if (distanceCmp != 0) return distanceCmp;
      final proteinCmp = a.option.proteinDelta.compareTo(b.option.proteinDelta);
      if (proteinCmp != 0) return proteinCmp;
      return a.index.compareTo(b.index);
    });

    return scored.map((s) => s.option).toList(growable: false);
  }
}
