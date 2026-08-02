import 'dart:typed_data';

import 'package:nutri_mvp/core/result.dart';
import 'package:printing/printing.dart';

import '../../domain/failures/nutrition_failure.dart';
import '../../domain/ports/diet_pdf_importer.dart';

/// Renders a page stream for [bytes] at [dpi].
///
/// A seam over `Printing.raster`, which is a static call into a native plugin.
/// Injecting it is what lets the page mapping, the cap, and the failure paths be
/// tested without a device.
typedef PdfRasterStream = Stream<PdfRaster> Function(
  Uint8List bytes,
  double dpi,
);

/// Rasterizes a PDF with the `printing` plugin.
///
/// The diet PDFs that matter have NO text layer — a Nutrium export is 14 pages
/// of images produced by wkhtmltopdf — so reading one means looking at pixels.
///
/// `printing` was chosen over a viewer package because `Printing.raster` is
/// exactly this operation (document in, pages out at a chosen DPI) with no
/// widget tree involved, and it covers every platform the app targets.
class PrintingPdfRasterizer implements PdfPageRasterizer {
  PrintingPdfRasterizer({PdfRasterStream? raster, this.dpi = defaultDpi})
      : _raster = raster ?? _printingRaster;

  final PdfRasterStream _raster;

  /// Render resolution.
  ///
  /// 150 DPI is the point where a scanned plan's small print stays legible to a
  /// vision model without the page images growing large enough to dominate the
  /// extraction request.
  final double dpi;

  static const double defaultDpi = 150;

  /// The first bytes of every PDF file.
  static const List<int> _magic = [0x25, 0x50, 0x44, 0x46]; // %PDF

  @override
  Future<Result<List<PdfPageImage>, NutritionFailure>> rasterize(
    Uint8List pdfBytes, {
    int maxPages = 40,
  }) async {
    if (maxPages <= 0) {
      throw ArgumentError.value(maxPages, 'maxPages', 'must be positive');
    }
    if (!_looksLikePdf(pdfBytes)) {
      // Worth telling apart from a render failure: "you picked the wrong file"
      // and "this PDF is broken" have different fixes.
      return const Err(
        MalformedPlanFailure('that file is not a PDF'),
      );
    }

    final pages = <PdfPageImage>[];
    try {
      // `take` stops consuming once the cap is reached, so a mistakenly picked
      // 300-page file does not turn into a 300-image extraction request.
      await for (final raster in _raster(pdfBytes, dpi).take(maxPages)) {
        pages.add(PdfPageImage(
          pageNumber: pages.length + 1,
          bytes: await raster.toPng(),
          mimeType: 'image/png',
        ));
      }
    } on Object catch (error) {
      // Plugin failures arrive as platform exceptions, decoding errors, or
      // whatever the host threw; none of them should escape a port that
      // promises a Result.
      return Err(StorageFailure('could not render the PDF: $error'));
    }

    return Ok(pages);
  }

  static bool _looksLikePdf(Uint8List bytes) {
    if (bytes.length < _magic.length) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) return false;
    }
    return true;
  }

  static Stream<PdfRaster> _printingRaster(Uint8List bytes, double dpi) =>
      Printing.raster(bytes, dpi: dpi);
}
