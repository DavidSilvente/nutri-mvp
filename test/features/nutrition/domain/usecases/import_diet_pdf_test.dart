import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_plan_codec.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/food_table_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/import_diet_document.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/import_diet_pdf.dart';

import '../../_fakes/fake_diet_plan_store.dart';

class _FakeRasterizer implements PdfPageRasterizer {
  // Both fields are set after construction by the tests that need them.
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

class _FakeExtractor implements DietPlanExtractor {
  _FakeExtractor({this.document});

  String? document;
  NutritionFailure? failWith;
  List<PdfPageImage>? receivedPages;
  List<String>? receivedKnownFoodIds;

  @override
  Future<Result<String, NutritionFailure>> extract(
    List<PdfPageImage> pages, {
    required List<String> knownFoodIds,
  }) async {
    receivedPages = pages;
    receivedKnownFoodIds = knownFoodIds;
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(document!);
  }
}

void main() {
  late String realDocument;
  late FakeFoodTableSource foodTable;

  setUpAll(() {
    realDocument =
        File('assets/diets/nutrium_david_2950kcal.json').readAsStringSync();
    final decoded = const FoodTableCodec()
        .decode(File('assets/nutrition/food_table.json').readAsStringSync());
    foodTable = FakeFoodTableSource(
      foods: switch (decoded) {
        Ok(value: final foods) => foods,
        Err(failure: final failure) => fail('food table: $failure'),
      },
    );
  });

  ({
    ImportDietPdf importer,
    FakeDietPlanStore store,
    _FakeRasterizer rasterizer,
    _FakeExtractor extractor,
  }) build({String? document, FakeFoodTableSource? table}) {
    final store = FakeDietPlanStore();
    final rasterizer = _FakeRasterizer();
    final extractor = _FakeExtractor(document: document ?? realDocument);
    final resolvedTable = table ?? foodTable;
    return (
      importer: ImportDietPdf(
        rasterizer: rasterizer,
        extractor: extractor,
        foodTable: resolvedTable,
        importDocument: ImportDietDocument(
          store: store,
          foodTable: resolvedTable,
          decoder: const DietPlanCodec(),
        ),
        now: () => DateTime.utc(2026, 8, 1, 10),
        newPlanId: () => 'imported-1',
      ),
      store: store,
      rasterizer: rasterizer,
      extractor: extractor,
    );
  }

  final pdfBytes = Uint8List.fromList([37, 80, 68, 70]); // "%PDF"

  test('renders the pages, extracts, and stores the plan', () async {
    final harness = build();

    final result = await harness.importer.import(
      pdfBytes,
      sourceLabel: 'AJUSTE 2950KCAL.pdf',
      makeActive: true,
    );

    expect(result, isA<Ok<String, NutritionFailure>>());
    expect((result as Ok<String, NutritionFailure>).value, 'imported-1');

    expect(harness.rasterizer.received, pdfBytes);
    expect(harness.extractor.receivedPages, hasLength(3));

    final stored = await harness.store.activePlan();
    final plan = switch (stored) {
      Ok(value: final value) => value,
      Err(failure: final failure) => fail('$failure'),
    };
    expect(plan, isNotNull);
    expect(plan!.id, 'imported-1');
    expect(plan.name, 'Ajuste 2950 kcal');
    expect(plan.sourceLabel, 'AJUSTE 2950KCAL.pdf');
    expect(plan.declaredDailyEnergyKcal, 2950);
    expect(plan.importedAt, DateTime.utc(2026, 8, 1, 10));
  });

  test('tells the extractor which foods are already known', () async {
    // Without this the model would coin new ids for foods the app can already
    // price, and every one of them would come back as unresolved.
    final harness = build();
    await harness.importer.import(pdfBytes, sourceLabel: 'x.pdf');

    expect(harness.extractor.receivedKnownFoodIds, contains('rice_white_raw'));
    expect(
      harness.extractor.receivedKnownFoodIds,
      hasLength(foodTable.foods.length),
    );
  });

  test('does not store anything when rendering fails', () async {
    final harness = build();
    harness.rasterizer.failWith = const StorageFailure('unreadable file');

    final result = await harness.importer.import(pdfBytes, sourceLabel: 'x.pdf');

    expect(result, isA<Err<String, NutritionFailure>>());
    expect(
      (result as Err<String, NutritionFailure>).failure,
      isA<StorageFailure>(),
    );
    final plans = await harness.store.listPlans();
    expect(switch (plans) {
      Ok(value: final value) => value,
      Err() => fail('expected Ok'),
    }, isEmpty);
  });

  test('reports an empty PDF as a malformed plan', () async {
    final harness = build();
    harness.rasterizer.pageCount = 0;

    final result = await harness.importer.import(pdfBytes, sourceLabel: 'x.pdf');

    expect(
      (result as Err<String, NutritionFailure>).failure,
      isA<MalformedPlanFailure>(),
    );
  });

  test('does not store anything when extraction fails', () async {
    final harness = build();
    harness.extractor.failWith =
        const MalformedPlanFailure('model returned prose, not a plan');

    final result = await harness.importer.import(pdfBytes, sourceLabel: 'x.pdf');

    expect(result, isA<Err<String, NutritionFailure>>());
    final plans = await harness.store.listPlans();
    expect(switch (plans) {
      Ok(value: final value) => value,
      Err() => fail('expected Ok'),
    }, isEmpty);
  });

  test('refuses a plan whose foods the app cannot resolve', () async {
    // The critical guard: a document that mentions unknown foods must fail AT
    // IMPORT, not become a stored diet that explodes when opened.
    final harness = build(
      table: FakeFoodTableSource(foods: [FakeFoodTableSource.food('only_one')]),
    );

    final result = await harness.importer.import(pdfBytes, sourceLabel: 'x.pdf');

    expect(result, isA<Err<String, NutritionFailure>>());
    final failure = (result as Err<String, NutritionFailure>).failure;
    expect(failure, isA<UnknownFoodFailure>());
    // Every gap is reported at once, not just the first.
    expect((failure as UnknownFoodFailure).foodIds.length, greaterThan(1));

    final plans = await harness.store.listPlans();
    expect(switch (plans) {
      Ok(value: final value) => value,
      Err() => fail('expected Ok'),
    }, isEmpty);
  });

  test('rejects a document that is not valid JSON', () async {
    final harness = build(document: 'I could not read the PDF, sorry!');

    final result = await harness.importer.import(pdfBytes, sourceLabel: 'x.pdf');

    expect(
      (result as Err<String, NutritionFailure>).failure,
      isA<MalformedPlanFailure>(),
    );
  });

  test('rejects a document declaring an unsupported schema version', () async {
    final harness = build(
      document: '{"schemaVersion":99,"diet":{"name":"x","dayGroups":[]}}',
    );

    final result = await harness.importer.import(pdfBytes, sourceLabel: 'x.pdf');

    final failure = (result as Err<String, NutritionFailure>).failure;
    expect(failure, isA<MalformedPlanFailure>());
    expect(
      (failure as MalformedPlanFailure).reason,
      contains('schemaVersion'),
    );
  });
}
