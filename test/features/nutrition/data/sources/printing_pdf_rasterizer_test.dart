import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/printing_pdf_rasterizer.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:printing/printing.dart';

/// A 2x2 opaque raster, small enough that encoding it stays cheap.
PdfRaster raster() {
  return PdfRaster(
    2,
    2,
    Uint8List.fromList(List<int>.filled(2 * 2 * 4, 0xFF)),
  );
}

Uint8List pdfBytes([int extra = 8]) =>
    Uint8List.fromList([0x25, 0x50, 0x44, 0x46, ...List.filled(extra, 0)]);

void main() {
  // toPng() decodes through dart:ui, so the test binding has to exist.
  TestWidgetsFlutterBinding.ensureInitialized();

  List<PdfPageImage> pagesOf(
    Result<List<PdfPageImage>, NutritionFailure> result,
  ) {
    return switch (result) {
      Ok(value: final value) => value,
      Err(failure: final failure) => fail('$failure'),
    };
  }

  NutritionFailure failureOf(
    Result<List<PdfPageImage>, NutritionFailure> result,
  ) {
    return switch (result) {
      Ok() => fail('expected a failure'),
      Err(failure: final failure) => failure,
    };
  }

  test('numbers pages from one, so extraction can cite them', () async {
    final rasterizer = PrintingPdfRasterizer(
      raster: (_, _) => Stream.fromIterable([raster(), raster(), raster()]),
    );

    final pages = pagesOf(await rasterizer.rasterize(pdfBytes()));

    expect(pages.map((page) => page.pageNumber), [1, 2, 3]);
    expect(pages.every((page) => page.mimeType == 'image/png'), isTrue);
    // Real PNG bytes, not the raw pixels handed in.
    expect(pages.first.bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  test('renders at 150 DPI unless told otherwise', () async {
    // Small print on a scanned plan has to survive for a vision model to read
    // it, and the page images still have to fit in one request.
    double? seenDpi;
    final rasterizer = PrintingPdfRasterizer(
      raster: (_, dpi) {
        seenDpi = dpi;
        return Stream.fromIterable([raster()]);
      },
    );

    await rasterizer.rasterize(pdfBytes());

    expect(seenDpi, 150);
  });

  test('stops at maxPages instead of rendering the whole file', () async {
    // A mistakenly picked 300-page file must not become a 300-image request.
    var produced = 0;
    final rasterizer = PrintingPdfRasterizer(
      raster: (_, _) async* {
        for (var i = 0; i < 300; i++) {
          produced++;
          yield raster();
        }
      },
    );

    final pages = pagesOf(await rasterizer.rasterize(pdfBytes(), maxPages: 3));

    expect(pages, hasLength(3));
    // The stream is cancelled, not drained and then trimmed.
    expect(produced, lessThan(300));
  });

  test('rejects a file that is not a PDF before touching the plugin', () async {
    // "You picked the wrong file" and "this PDF is broken" have different fixes,
    // so they must not surface as the same error.
    var called = false;
    final rasterizer = PrintingPdfRasterizer(
      raster: (_, _) {
        called = true;
        return const Stream.empty();
      },
    );

    final failure = failureOf(
      await rasterizer.rasterize(Uint8List.fromList([1, 2, 3, 4, 5])),
    );

    expect(failure, isA<MalformedPlanFailure>());
    expect((failure as MalformedPlanFailure).reason, contains('not a PDF'));
    expect(called, isFalse);
  });

  test('reports a render failure as storage, not as a bad plan', () async {
    final rasterizer = PrintingPdfRasterizer(
      raster: (_, _) => Stream.error(StateError('pdfium said no')),
    );

    final failure = failureOf(await rasterizer.rasterize(pdfBytes()));

    expect(failure, isA<StorageFailure>());
    expect((failure as StorageFailure).reason, contains('pdfium said no'));
  });

  test('a PDF with no renderable pages comes back empty, not broken', () async {
    // The use case turns this into "the PDF has no pages to read"; the adapter
    // does not get to editorialize.
    final rasterizer = PrintingPdfRasterizer(
      raster: (_, _) => const Stream.empty(),
    );

    expect(pagesOf(await rasterizer.rasterize(pdfBytes())), isEmpty);
  });

  test('refuses a non-positive page cap', () async {
    final rasterizer = PrintingPdfRasterizer(
      raster: (_, _) => const Stream.empty(),
    );

    expect(
      () => rasterizer.rasterize(pdfBytes(), maxPages: 0),
      throwsArgumentError,
    );
  });
}
