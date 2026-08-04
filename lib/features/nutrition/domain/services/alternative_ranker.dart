import '../value_objects/nutrition_target.dart';
import '../value_objects/swap_tolerance.dart';
import 'substitution_engine.dart';

/// Where a ranked alternative came from: the diet plan's own substitutes, or
/// the user's saved-meal catalogue.
///
/// The two are NEVER merged into one list — a user's off-plan meal must never
/// look like something the dietitian prescribed.
enum AlternativeOrigin { plan, savedMeal }

/// A [RankedOption] annotated with what [SubstitutionEngine] cannot know:
/// which catalogue it came from, and how it deviates from the planned meal
/// under [SwapTolerance].
class AlternativeOption {
  const AlternativeOption({
    required this.ranked,
    required this.origin,
    required this.deviation,
  });

  final RankedOption ranked;
  final AlternativeOrigin origin;
  final MacroDeviation deviation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlternativeOption &&
          other.ranked == ranked &&
          other.origin == origin &&
          other.deviation == deviation);

  @override
  int get hashCode => Object.hash(ranked, origin, deviation);
}

/// One origin's ranked options, in [SubstitutionEngine]'s order.
class AlternativeGroup {
  const AlternativeGroup({required this.origin, required this.options});

  final AlternativeOrigin origin;
  final List<AlternativeOption> options;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AlternativeGroup) return false;
    if (other.origin != origin) return false;
    if (other.options.length != options.length) return false;
    for (var i = 0; i < options.length; i++) {
      if (other.options[i] != options[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(origin, Object.hashAll(options));
}

/// Ranks plan substitutes and saved meals against the same frozen target,
/// keeping them in separate, origin-badged groups.
///
/// Calls [SubstitutionEngine.rank] TWICE — once per origin — without ever
/// modifying it: `substitution_engine.dart`'s diff must stay empty. Grouping,
/// origin tagging, and off-target labelling are entirely this class's job, so
/// they stay unit-testable without a widget.
class AlternativeRanker {
  const AlternativeRanker({this.tolerance = SwapTolerance.standard});

  final SwapTolerance tolerance;

  /// Ranks [planCandidates] and [savedCandidates] independently against
  /// [target]. A group with no candidates is OMITTED entirely rather than
  /// returned empty, so "no saved meals yet" is data-driven instead of a
  /// widget conditional.
  List<AlternativeGroup> rank({
    required NutritionTarget target,
    required List<MacroCandidate> planCandidates,
    required List<MacroCandidate> savedCandidates,
  }) {
    final groups = <AlternativeGroup>[];

    final plan = _rankGroup(
      target: target,
      origin: AlternativeOrigin.plan,
      candidates: planCandidates,
    );
    if (plan != null) groups.add(plan);

    final saved = _rankGroup(
      target: target,
      origin: AlternativeOrigin.savedMeal,
      candidates: savedCandidates,
    );
    if (saved != null) groups.add(saved);

    return groups;
  }

  AlternativeGroup? _rankGroup({
    required NutritionTarget target,
    required AlternativeOrigin origin,
    required List<MacroCandidate> candidates,
  }) {
    if (candidates.isEmpty) return null;

    final ranked = SubstitutionEngine.rank(target, candidates);
    final options = ranked
        .map(
          (option) => AlternativeOption(
            ranked: option,
            origin: origin,
            deviation: tolerance.evaluate(
              target: target,
              candidate: option.target,
            ),
          ),
        )
        .toList(growable: false);

    return AlternativeGroup(origin: origin, options: options);
  }
}
