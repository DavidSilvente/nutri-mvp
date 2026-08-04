import 'dart:async';
import 'dart:typed_data';

import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/pdf_file_picker.dart';

/// A [PdfPageRasterizer] that renders a fixed number of blank pages, so tests
/// never touch a native plugin.
class FakePdfRasterizer implements PdfPageRasterizer {
  int pageCount = 3;
  NutritionFailure? failWith;
  Uint8List? received;

  @override
  Future<Result<List<PdfPageImage>, NutritionFailure>> rasterize(
    Uint8List pdfBytes, {
    int maxPages = 40,
  }) async {
    received = pdfBytes;
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok([
      for (var page = 1; page <= pageCount; page++)
        PdfPageImage(
          pageNumber: page,
          bytes: Uint8List.fromList([page]),
          mimeType: 'image/png',
        ),
    ]);
  }
}

/// A [DietPlanExtractor] that returns a canned draft, so tests never call a
/// model.
class FakeDietPlanExtractor implements DietPlanExtractor {
  FakeDietPlanExtractor({this.document});

  String? document;
  NutritionFailure? failWith;
  List<PdfPageImage>? receivedPages;

  /// Held open to keep an extraction in flight, so a test can observe what the
  /// UI shows WHILE reading rather than only after it finishes.
  Completer<void>? gate;

  @override
  Future<Result<String, NutritionFailure>> extract(
    List<PdfPageImage> pages,
  ) async {
    receivedPages = pages;
    await gate?.future;
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(document!);
  }
}

/// A [PdfFilePicker] that hands back bytes without a file dialog.
///
/// [pick] set to null stands for the user backing out, which the flow must
/// treat as a decision rather than an error.
class FakePdfFilePicker implements PdfFilePicker {
  FakePdfFilePicker({this.pick});

  PickedPdf? pick;
  NutritionFailure? failWith;
  int calls = 0;

  @override
  Future<Result<PickedPdf?, NutritionFailure>> pickPdf() async {
    calls++;
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(pick);
  }
}
