import 'dart:typed_data';

import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../ports/diet_pdf_importer.dart';
import '../services/extracted_food_resolver.dart';
import '../services/import_review.dart';
import 'import_diet_document.dart';

/// Reads a diet PDF in two phases, with the user in the middle.
///
/// [prepare] renders the pages, extracts a draft, and matches every food line
/// against the table. [complete] takes the decisions back and stores the plan.
///
/// The split is not ceremony. A plan written by someone else names foods in
/// prose, and some of those lines are genuinely ambiguous; the only honest
/// options are to ask or to guess. Guessing would attach invented macros to a
/// real meal, so the import stops and asks.
///
/// The steps stay separate ports so each can fail for its own reason and the
/// user gets told which one broke — "could not read the file", "could not make
/// sense of the plan", "the plan mentions foods we do not know" are three very
/// different problems with three different fixes.
class ImportDietPdf implements DietPdfImporter {
  ImportDietPdf({
    required PdfPageRasterizer rasterizer,
    required DietPlanExtractor extractor,
    required DietPlanDraftCodec draftCodec,
    required ExtractedFoodResolver resolver,
    required ImportDietDocument importDocument,
    required DateTime Function() now,
    required String Function() newPlanId,
  })  : _rasterizer = rasterizer,
        _extractor = extractor,
        _draftCodec = draftCodec,
        _resolver = resolver,
        _importDocument = importDocument,
        _now = now,
        _newPlanId = newPlanId;

  final PdfPageRasterizer _rasterizer;
  final DietPlanExtractor _extractor;
  final DietPlanDraftCodec _draftCodec;
  final ExtractedFoodResolver _resolver;
  final ImportDietDocument _importDocument;
  final DateTime Function() _now;
  final String Function() _newPlanId;

  @override
  Future<Result<DietImportDraft, NutritionFailure>> prepare(
    Uint8List pdfBytes,
  ) async {
    final rasterized = await _rasterizer.rasterize(pdfBytes);
    final List<PdfPageImage> pages;
    switch (rasterized) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        if (value.isEmpty) {
          return const Err(
            MalformedPlanFailure('the PDF has no pages to read'),
          );
        }
        pages = value;
    }

    final extracted = await _extractor.extract(pages);
    final String draft;
    switch (extracted) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        draft = value;
    }

    final read = _draftCodec.readPendingFoods(draft);
    final List<PendingFood> pending;
    switch (read) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        pending = value;
    }

    // Matching happens HERE, locally, against a published table — never in the
    // model. That is what keeps every macro figure traceable to a source.
    final resolutions = _resolver.resolveAll(
      pending.map((food) => food.extracted),
    );

    return Ok(DietImportDraft(
      document: draft,
      pendingFoods: pending,
      resolutions: resolutions,
    ));
  }

  /// Returns the stored plan's id on success.
  @override
  Future<Result<String, NutritionFailure>> complete(
    DietImportDraft draft,
    List<ReviewedFood> decisions, {
    required String sourceLabel,
    bool makeActive = false,
  }) async {
    if (decisions.length != draft.pendingFoods.length) {
      // A caller-side defect, not bad input: failing loudly beats storing a plan
      // whose foods silently shifted by one.
      throw ArgumentError.value(
        decisions.length,
        'decisions',
        'expected one decision per pending food '
            '(${draft.pendingFoods.length})',
      );
    }

    final chosen = <String, String>{
      for (var i = 0; i < decisions.length; i++)
        draft.pendingFoods[i].ref: decisions[i].food.id,
    };

    final rewritten = _draftCodec.resolveRefs(draft.document, chosen);
    final String document;
    switch (rewritten) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        document = value;
    }

    // Validation lives in ImportDietDocument, which refuses to store a document
    // it cannot decode. So a plan that still mentions an unknown food fails
    // HERE, while the user is in the import flow, rather than becoming a diet
    // that cannot be opened.
    final planId = _newPlanId();
    final stored = await _importDocument(
      id: planId,
      document: document,
      importedAt: _now(),
      sourceLabel: sourceLabel,
      makeActive: makeActive,
    );
    return switch (stored) {
      Ok() => Ok(planId),
      Err(failure: final failure) => Err(failure),
    };
  }
}
