import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_draft_codec.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_plan_codec.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/food_table_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/extracted_food_resolver.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_matcher.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/import_review.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/import_diet_document.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/import_diet_pdf.dart';

import '../../_fakes/fake_diet_plan_store.dart';
import '../../_fixtures/draft_document.dart';

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

  @override
  Future<Result<String, NutritionFailure>> extract(
    List<PdfPageImage> pages,
  ) async {
    receivedPages = pages;
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(document!);
  }
}

void main() {
  late String realDocument;
  late String realDraft;
  late FakeFoodTableSource foodTable;
  late ExtractedFoodResolver resolver;

  setUpAll(() {
    realDocument =
        File('assets/diets/nutrium_david_2950kcal.json').readAsStringSync();
    realDraft = draftFromDocument(realDocument);
    final decoded = const FoodTableCodec()
        .decode(File('assets/nutrition/food_table.json').readAsStringSync());
    final foods = switch (decoded) {
      Ok(value: final value) => value,
      Err(failure: final failure) => fail('food table: $failure'),
    };
    foodTable = FakeFoodTableSource(foods: foods);
    resolver = ExtractedFoodResolver(FoodMatcher(FoodCatalog(foods)));
  });

  ({
    ImportDietPdf importer,
    FakeDietPlanStore store,
    _FakeRasterizer rasterizer,
    _FakeExtractor extractor,
  })
  build({String? document, FakeFoodTableSource? table}) {
    final store = FakeDietPlanStore();
    final rasterizer = _FakeRasterizer();
    final extractor = _FakeExtractor(document: document ?? realDraft);
    final resolvedTable = table ?? foodTable;
    return (
      importer: ImportDietPdf(
        rasterizer: rasterizer,
        extractor: extractor,
        draftCodec: const DietDraftCodec(),
        resolver: resolver,
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

  DietImportDraft draftOf(Result<DietImportDraft, NutritionFailure> result) {
    return switch (result) {
      Ok(value: final value) => value,
      Err(failure: final failure) => fail('$failure'),
    };
  }

  /// The decisions a perfect review would produce: every ref settled on the id
  /// the shipped plan actually uses.
  List<ReviewedFood> perfectDecisions(DietImportDraft draft) {
    final ids = originalFoodIds(realDocument);
    final catalog = FoodCatalog(foodTable.foods);
    return [
      for (var i = 0; i < draft.pendingFoods.length; i++)
        ReviewedFood(
          extracted: draft.pendingFoods[i].extracted,
          food: catalog.byId(ids[i])!,
          chosenByUser: true,
        ),
    ];
  }

  group('preparing an import', () {
    test('renders the pages, extracts, and resolves what it can', () async {
      final harness = build();

      final draft = draftOf(await harness.importer.prepare(pdfBytes));

      expect(harness.rasterizer.received, pdfBytes);
      expect(harness.extractor.receivedPages, hasLength(3));
      expect(draft.document, realDraft);
      expect(draft.pendingFoods, isNotEmpty);
      // One verdict per described food, in the same order, so the review screen
      // can pair them by index.
      expect(draft.resolutions, hasLength(draft.pendingFoods.length));
      for (var i = 0; i < draft.pendingFoods.length; i++) {
        expect(
          draft.resolutions[i].extracted.rawText,
          draft.pendingFoods[i].extracted.rawText,
        );
      }
    });

    test('places a real plan\'s foods without asking about all of them', () async {
      // Guards the wiring, not the matcher's accuracy: if resolution silently
      // stopped working, every line would come back needing review and the
      // screen would become a transcription chore.
      //
      // The bar is deliberately low because this fixture is ADVERSARIAL — it
      // derives canonical names from ids and labels every food `raw`, which
      // contradicts the cooked entries and costs them the preparation penalty.
      // A real extractor states the preparation, so it does better than this.
      final harness = build();

      final draft = draftOf(await harness.importer.prepare(pdfBytes));
      final settled =
          draft.resolutions.where((line) => !line.needsReview).length;

      expect(settled, greaterThan(draft.resolutions.length ~/ 3));
      expect(settled, lessThan(draft.resolutions.length));
    });

    test('stores nothing while preparing', () async {
      final harness = build();
      await harness.importer.prepare(pdfBytes);

      final plans = await harness.store.listPlans();
      expect(switch (plans) {
        Ok(value: final value) => value,
        Err() => fail('expected Ok'),
      }, isEmpty);
    });

    test('reports a rendering failure as its own', () async {
      final harness = build();
      harness.rasterizer.failWith = const StorageFailure('unreadable file');

      final result = await harness.importer.prepare(pdfBytes);

      expect(
        (result as Err<DietImportDraft, NutritionFailure>).failure,
        isA<StorageFailure>(),
      );
    });

    test('reports an empty PDF as a malformed plan', () async {
      final harness = build();
      harness.rasterizer.pageCount = 0;

      final result = await harness.importer.prepare(pdfBytes);

      expect(
        (result as Err<DietImportDraft, NutritionFailure>).failure,
        isA<MalformedPlanFailure>(),
      );
    });

    test('reports an extraction failure as its own', () async {
      final harness = build();
      harness.extractor.failWith =
          const MalformedPlanFailure('model returned prose, not a plan');

      final result = await harness.importer.prepare(pdfBytes);

      expect(result, isA<Err<DietImportDraft, NutritionFailure>>());
    });

    test('rejects a draft that is not valid JSON', () async {
      final harness = build(document: 'I could not read the PDF, sorry!');

      final result = await harness.importer.prepare(pdfBytes);

      expect(
        (result as Err<DietImportDraft, NutritionFailure>).failure,
        isA<MalformedPlanFailure>(),
      );
    });
  });

  group('completing an import', () {
    test('bakes the decisions in and stores the plan', () async {
      final harness = build();
      final draft = draftOf(await harness.importer.prepare(pdfBytes));

      final result = await harness.importer.complete(
        draft,
        perfectDecisions(draft),
        sourceLabel: 'AJUSTE 2950KCAL.pdf',
        makeActive: true,
      );

      expect((result as Ok<String, NutritionFailure>).value, 'imported-1');

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

    test('the user\'s choice is the food that gets stored', () async {
      // The point of the whole review: what the user picked is what the plan
      // derives its macros from.
      final harness = build();
      final draft = draftOf(await harness.importer.prepare(pdfBytes));
      final decisions = [...perfectDecisions(draft)];
      final swapped = FoodItem(
        id: 'beef_loin_test',
        name: 'Ternera de prueba',
        preparation: FoodPreparation.raw,
        per100g: decisions.first.food.per100g,
        source: FoodDataSource.usdaSrLegacy,
      );
      decisions[0] = ReviewedFood(
        extracted: decisions[0].extracted,
        food: swapped,
        chosenByUser: true,
      );

      final result = await harness.importer.complete(
        draft,
        decisions,
        sourceLabel: 'x.pdf',
        // The swapped food is not in the table, so storing must fail naming it.
      );

      final failure = (result as Err<String, NutritionFailure>).failure;
      expect(failure, isA<UnknownFoodFailure>());
      expect((failure as UnknownFoodFailure).foodIds, contains('beef_loin_test'));
    });

    test('refuses a decision list that does not match the draft', () async {
      // A caller-side defect: silently importing would shift every food by one.
      final harness = build();
      final draft = draftOf(await harness.importer.prepare(pdfBytes));

      expect(
        () => harness.importer.complete(
          draft,
          perfectDecisions(draft).sublist(1),
          sourceLabel: 'x.pdf',
        ),
        throwsArgumentError,
      );
    });

    test('refuses a plan whose foods the table cannot resolve', () async {
      // The critical guard: a document mentioning unknown foods must fail AT
      // IMPORT, not become a stored diet that explodes when opened.
      final harness = build(
        table: FakeFoodTableSource(foods: [FakeFoodTableSource.food('only')]),
      );
      final draft = draftOf(await harness.importer.prepare(pdfBytes));

      final result = await harness.importer.complete(
        draft,
        perfectDecisions(draft),
        sourceLabel: 'x.pdf',
      );

      expect(
        (result as Err<String, NutritionFailure>).failure,
        isA<UnknownFoodFailure>(),
      );
      final plans = await harness.store.listPlans();
      expect(switch (plans) {
        Ok(value: final value) => value,
        Err() => fail('expected Ok'),
      }, isEmpty);
    });

    test('rejects a draft declaring an unsupported schema version', () async {
      // A model claiming another schema may have changed the shape too, so the
      // draft is refused rather than relabelled.
      final harness = build(
        document: '{"schemaVersion":99,"diet":{"name":"x","dayGroups":[]}}',
      );

      final result = await harness.importer.prepare(pdfBytes);

      final failure =
          (result as Err<DietImportDraft, NutritionFailure>).failure;
      expect(failure, isA<MalformedPlanFailure>());
      expect(
        (failure as MalformedPlanFailure).reason,
        contains('schemaVersion'),
      );
    });
  });
}
