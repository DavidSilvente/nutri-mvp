import '../entities/food_item.dart';
import '../ports/diet_pdf_importer.dart';
import 'extracted_food_resolver.dart';

/// A plan line the user has settled: what the plan said, and which food it will
/// be imported as.
///
/// This is the import's output contract. Once every line has one of these, the
/// plan can be turned into a document whose macros all come from catalog
/// entries — nothing left guessed.
class ReviewedFood {
  const ReviewedFood({
    required this.extracted,
    required this.food,
    required this.chosenByUser,
  });

  final ExtractedFood extracted;
  final FoodItem food;

  /// Whether the user picked this food rather than accepting the match the
  /// resolver was already confident about. Kept because a plan the user
  /// corrected by hand is worth a different note in the import summary.
  final bool chosenByUser;
}

/// One plan line, with the decision currently attached to it.
class ImportReviewEntry {
  const ImportReviewEntry({
    required this.resolution,
    required this.food,
    required this.score,
    required this.chosenByUser,
  });

  /// The line as the resolver left it, candidates included.
  final FoodResolution resolution;

  /// The food this line will import as, or null while it is unsettled.
  final FoodItem? food;

  /// Matcher confidence in [food], or null when the food did not come from a
  /// scored candidate.
  final double? score;

  final bool chosenByUser;

  ExtractedFood get extracted => resolution.extracted;

  bool get isSettled => food != null;

  /// Whether the user still has to look at this line before the import can run.
  bool get needsAttention => !isSettled;

  /// Starts from the resolver's own verdict: a confident match is pre-filled, a
  /// doubtful or missing one is left blank on purpose.
  ///
  /// Pre-filling a doubtful match would defeat the whole screen — the user would
  /// tap through a list that already looks decided.
  factory ImportReviewEntry.from(FoodResolution resolution) {
    final accepted = resolution.needsReview ? null : resolution.best;
    return ImportReviewEntry(
      resolution: resolution,
      food: accepted?.food,
      score: accepted?.score,
      chosenByUser: false,
    );
  }

  ImportReviewEntry withFood(FoodItem food, {double? score}) {
    return ImportReviewEntry(
      resolution: resolution,
      food: food,
      score: score,
      chosenByUser: true,
    );
  }
}

/// The state of an import awaiting the user's decisions.
///
/// Exists so the review screen holds no logic of its own: what is pending, when
/// the import may proceed, and what it produces are all decided here, where they
/// can be tested without a widget tree.
///
/// Immutable — every change returns a new review, so a rebuild cannot observe a
/// half-applied selection.
class ImportReview {
  const ImportReview._(this.entries);

  factory ImportReview.from(Iterable<FoodResolution> resolutions) {
    return ImportReview._([
      for (final resolution in resolutions) ImportReviewEntry.from(resolution),
    ]);
  }

  final List<ImportReviewEntry> entries;

  int get length => entries.length;

  /// Lines still waiting for a decision.
  List<ImportReviewEntry> get pending =>
      [for (final entry in entries) if (entry.needsAttention) entry];

  int get pendingCount => pending.length;

  /// Whether every line has a food, so the import may run.
  bool get isComplete => pendingCount == 0;

  /// How many lines the user settled by hand.
  int get correctedCount =>
      entries.where((entry) => entry.chosenByUser).length;

  /// Attaches [food] to the line at [index].
  ImportReview select(int index, FoodItem food, {double? score}) {
    final updated = [...entries];
    updated[index] = entries[index].withFood(food, score: score);
    return ImportReview._(updated);
  }

  /// The settled lines, in plan order.
  ///
  /// Throws when the review is incomplete: an import that silently dropped the
  /// lines nobody settled would produce a plan missing the very foods that were
  /// hardest to read.
  List<ReviewedFood> get decisions {
    if (!isComplete) {
      throw StateError(
        '$pendingCount of $length lines still need a food; '
        'the import cannot run until they are settled',
      );
    }
    return [
      for (final entry in entries)
        ReviewedFood(
          extracted: entry.extracted,
          food: entry.food!,
          chosenByUser: entry.chosenByUser,
        ),
    ];
  }
}
