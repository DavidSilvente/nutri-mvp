import 'dart:typed_data';

import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../ports/diet_pdf_importer.dart';
import '../ports/food_table_source.dart';
import 'import_diet_document.dart';

/// Reads a diet PDF and stores it: render the pages, extract a normalized
/// document, validate it, persist it.
///
/// The steps stay separate ports so each can fail for its own reason and the
/// user gets told which one broke — "could not read the file", "could not make
/// sense of the plan", "the plan mentions foods we do not know" are three very
/// different problems with three different fixes.
class ImportDietPdf implements DietPdfImporter {
  ImportDietPdf({
    required PdfPageRasterizer rasterizer,
    required DietPlanExtractor extractor,
    required FoodTableSource foodTable,
    required ImportDietDocument importDocument,
    required DateTime Function() now,
    required String Function() newPlanId,
  })  : _rasterizer = rasterizer,
        _extractor = extractor,
        _foodTable = foodTable,
        _importDocument = importDocument,
        _now = now,
        _newPlanId = newPlanId;

  final PdfPageRasterizer _rasterizer;
  final DietPlanExtractor _extractor;
  final FoodTableSource _foodTable;
  final ImportDietDocument _importDocument;
  final DateTime Function() _now;
  final String Function() _newPlanId;

  /// Returns the stored plan's id on success.
  @override
  Future<Result<String, NutritionFailure>> import(
    Uint8List pdfBytes, {
    required String sourceLabel,
    bool makeActive = false,
  }) async {
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

    // The extractor is told which foods are already known so it can reuse those
    // ids instead of inventing new ones for foods the app can already price.
    final foods = await _foodTable.loadFoods();
    final List<String> knownFoodIds;
    switch (foods) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final items):
        knownFoodIds = items.map((food) => food.id).toList(growable: false);
    }

    final extracted = await _extractor.extract(
      pages,
      knownFoodIds: knownFoodIds,
    );
    final String document;
    switch (extracted) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        document = value;
    }

    // Validation lives in ImportDietDocument, which refuses to store a document
    // it cannot decode. So a plan that mentions an unknown food fails HERE,
    // while the user is still in the import flow, rather than becoming a diet
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
