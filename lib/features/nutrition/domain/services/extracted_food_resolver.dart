import '../entities/food_item.dart';
import '../ports/diet_pdf_importer.dart';
import 'food_matcher.dart';

/// The outcome of resolving one extracted plan line against the food table.
class FoodResolution {
  const FoodResolution({
    required this.extracted,
    required this.candidates,
    required this.reviewThreshold,
  });

  final ExtractedFood extracted;

  /// Ranked candidates, best first. Empty when nothing plausible was found.
  final List<FoodMatch> candidates;

  /// Score at or above which a match is trusted without asking the user.
  final double reviewThreshold;

  /// The chosen match, or null when nothing was plausible.
  FoodMatch? get best => candidates.isEmpty ? null : candidates.first;

  bool get isResolved => best != null;

  /// Whether a human should look at this line before the plan is trusted.
  ///
  /// True both when nothing matched and when the best match is merely plausible.
  /// A silently-accepted weak match is worse than an unresolved one: the user
  /// never learns the macros attached to their lunch were a guess.
  bool get needsReview => best == null || best!.score < reviewThreshold;

  FoodItem? get food => best?.food;
}

/// Resolves extracted plan lines to food-table entries.
///
/// This is what lets the app read a plan written by someone else. The extractor
/// reports what the page SAYS ("140 gramos de pollo, pechuga, plancha" ->
/// canonical "chicken breast", preparation grilled); this service decides which
/// catalog entry that is, so the macros come from a published table rather than
/// from a model's opinion.
///
/// It never invents a food. A line it cannot place comes back unresolved with its
/// candidate list attached, for the user to settle.
class ExtractedFoodResolver {
  ExtractedFoodResolver(
    this._matcher, {
    this.reviewThreshold = defaultReviewThreshold,
    this.candidateCount = 5,
  });

  final FoodMatcher _matcher;

  /// Best-match score below which the line is flagged for review.
  ///
  /// Higher than the matcher's own floor: the matcher decides what is plausible
  /// enough to show, this decides what is safe enough to accept unattended.
  final double reviewThreshold;

  final int candidateCount;

  static const double defaultReviewThreshold = 0.75;

  FoodResolution resolve(ExtractedFood extracted) {
    final preparation = _parsePreparation(extracted.preparation);
    final candidates = _matcher.search(
      extracted.canonicalName,
      preparation: preparation,
      limit: candidateCount,
    );
    return FoodResolution(
      extracted: extracted,
      candidates: candidates,
      reviewThreshold: reviewThreshold,
    );
  }

  List<FoodResolution> resolveAll(Iterable<ExtractedFood> extracted) => [
    for (final food in extracted) resolve(food),
  ];

  /// Reads a preparation string, tolerating an unknown value.
  ///
  /// A model returning an unexpected word must not abort the whole import, so an
  /// unrecognized value is treated as "unstated" and the matcher falls back to
  /// whatever the name itself implies.
  static FoodPreparation? _parsePreparation(String raw) {
    try {
      return FoodPreparation.parse(raw);
    } on ArgumentError {
      return FoodMatcher.statedPreparation(raw);
    }
  }
}
