import 'dart:typed_data';

import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../services/extracted_food_resolver.dart';
import '../services/import_review.dart';
import '../value_objects/food_quantity.dart';

/// One rendered page of a source PDF.
class PdfPageImage {
  const PdfPageImage({
    required this.pageNumber,
    required this.bytes,
    required this.mimeType,
  });

  /// 1-based page number, so extraction can cite where a value came from.
  final int pageNumber;

  final Uint8List bytes;

  /// e.g. `image/png`.
  final String mimeType;
}

/// Renders a PDF's pages as images.
///
/// A port because the only diet PDFs that matter in practice have NO text layer
/// (a Nutrium export is 14 pages of images produced by wkhtmltopdf), so reading
/// one means looking at pixels. Rasterization is platform work; the domain only
/// needs the pages.
abstract interface class PdfPageRasterizer {
  /// Renders [pdfBytes] to one image per page.
  ///
  /// [maxPages] guards against a mistakenly picked 300-page file turning into a
  /// huge extraction request.
  Future<Result<List<PdfPageImage>, NutritionFailure>> rasterize(
    Uint8List pdfBytes, {
    int maxPages = 40,
  });
}

/// A food as the extractor read it off the page, BEFORE it is matched to a known
/// composition-table entry.
///
/// Deliberately not a `FoodItem`: at this stage the app knows what the plan
/// says, not yet what the food's macros are. Conflating the two is what leads to
/// invented numbers.
class ExtractedFood {
  const ExtractedFood({
    required this.rawText,
    required this.canonicalName,
    required this.preparation,
    required this.grams,
    this.count,
    this.unit,
    this.brandNormalizedFrom,
  });

  /// The plan's wording, verbatim.
  final String rawText;

  /// A generic, brand-free English name for matching against the food table,
  /// e.g. `chicken breast`. Brands are stripped because a composition table has
  /// no entry for a specific supermarket product.
  final String canonicalName;

  /// Preparation state as stated by the plan (`raw`, `boiled`, ...), which must
  /// survive matching: raw and cooked forms differ by up to 3x in energy.
  final String preparation;

  /// Total weight for this quantity, in grams.
  final num grams;

  final num? count;
  final String? unit;

  /// The brand-bearing wording this was normalized from, kept so the UI can
  /// explain the substitution.
  final String? brandNormalizedFrom;
}

/// A food the extractor described but did not place in the catalog, tagged with
/// the reference the draft document uses for it.
///
/// The reference is what makes the round trip possible: the plan's meals point
/// at it, and once the user settles which catalog entry it is, every mention is
/// rewritten at once.
class PendingFood {
  const PendingFood({required this.ref, required this.extracted});

  /// The draft-local id the document's `foodRef` fields use, e.g. `x1`.
  final String ref;

  final ExtractedFood extracted;
}

/// Turns rendered pages into a DRAFT plan document.
///
/// Implementations are expected to use a multimodal model. The contract is
/// deliberately narrow: return the document text, or a failure. Everything about
/// prompts, retries and providers stays inside the adapter.
///
/// The model is asked to DESCRIBE foods, never to name catalog ids. It has no
/// way to know what `usda_167512` is, and listing the table for it would mean
/// shipping roughly 470 KB of ids and names on every import — to do a matching
/// job [FoodMatcher] already does locally, deterministically, and traceably.
abstract interface class DietPlanExtractor {
  /// Extracts a draft plan document from [pages].
  ///
  /// The returned string MUST be a document `DietPlanDraftCodec` can read: the
  /// normal plan shape, plus an `extractedFoods` section whose refs the meals
  /// point at.
  Future<Result<String, NutritionFailure>> extract(List<PdfPageImage> pages);
}

/// What one draft ref resolved to, once the user settled it.
class SettledFood {
  const SettledFood({required this.foodId, this.quantity});

  /// The catalog id every mention of this ref becomes.
  final String foodId;

  /// The quantity to write over the document's own, or null to leave each
  /// mention's quantity as the extraction read it.
  ///
  /// Null is not "the same numbers". One described food can appear in several
  /// meals at different weights, so writing a single quantity everywhere would
  /// rewrite meals the user never looked at — an override happens only when the
  /// user actually corrected the amount.
  final FoodQuantity? quantity;
}

/// Reads and rewrites the draft document produced by extraction.
///
/// A port because the draft's JSON is a data-layer concern, while the import use
/// case needs only two things from it: which foods are still unplaced, and a
/// document with the user's choices baked in.
abstract interface class DietPlanDraftCodec {
  /// The foods [draft] describes but has not placed, in document order.
  Result<List<PendingFood>, NutritionFailure> readPendingFoods(String draft);

  /// Rewrites [draft] with every pending ref replaced by what the user settled
  /// it to, yielding a document `DietPlanDecoder` can decode.
  ///
  /// [settled] maps a [PendingFood.ref] to its outcome.
  Result<String, NutritionFailure> resolveRefs(
    String draft,
    Map<String, SettledFood> settled,
  );
}

/// Everything the review screen needs, plus the draft it came from.
class DietImportDraft {
  const DietImportDraft({
    required this.document,
    required this.pendingFoods,
    required this.resolutions,
  });

  /// The draft document, refs still unresolved.
  final String document;

  final List<PendingFood> pendingFoods;

  /// The resolver's verdict for each entry in [pendingFoods], same order.
  final List<FoodResolution> resolutions;
}

/// Reads a diet PDF in two phases, because the user stands between them.
///
/// A plan the app cannot fully place is the normal case, not the exception, so
/// import cannot be one call: [prepare] gets as far as "here is what the plan
/// says and what we think each line is", the user settles the rest, and
/// [complete] stores it.
abstract interface class DietPdfImporter {
  /// Renders [pdfBytes], extracts a draft, and resolves what it can.
  Future<Result<DietImportDraft, NutritionFailure>> prepare(Uint8List pdfBytes);

  /// Stores [draft] with [decisions] applied, returning the stored plan's id.
  ///
  /// [decisions] must line up with [DietImportDraft.pendingFoods], one per
  /// entry and in the same order.
  ///
  /// [sourceLabel] is the origin shown to the user, normally the file name.
  Future<Result<String, NutritionFailure>> complete(
    DietImportDraft draft,
    List<ReviewedFood> decisions, {
    required String sourceLabel,
    bool makeActive = false,
  });
}
