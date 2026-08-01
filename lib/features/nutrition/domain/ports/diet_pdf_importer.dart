import 'dart:typed_data';

import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';

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

/// Turns rendered pages into a normalized plan document.
///
/// Implementations are expected to use a multimodal model. The contract is
/// deliberately narrow: return the document text, or a failure. Everything about
/// prompts, retries and providers stays inside the adapter.
abstract interface class DietPlanExtractor {
  /// Extracts a normalized plan document from [pages].
  ///
  /// The returned string MUST be a document `DietPlanDecoder` can decode.
  Future<Result<String, NutritionFailure>> extract(
    List<PdfPageImage> pages, {
    required List<String> knownFoodIds,
  });
}

/// Reads a diet PDF end to end: render, extract, validate, store.
abstract interface class DietPdfImporter {
  /// Imports the plan in [pdfBytes].
  ///
  /// [sourceLabel] is the origin shown to the user, normally the file name.
  Future<Result<String, NutritionFailure>> import(
    Uint8List pdfBytes, {
    required String sourceLabel,
    bool makeActive = false,
  });
}
