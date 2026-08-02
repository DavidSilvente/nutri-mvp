import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/pdf_file_picker.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_library_screen.dart';

import '../../../../_helpers/fake_overrides.dart';
import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_diet_import.dart';
import '../../_fakes/fake_diet_plan_store.dart';

/// A draft naming one food by description, the way an extraction would.
///
/// `pollo pechuga` matches the fake table's `chicken_breast_grilled`, so the
/// happy path exercises real matching rather than a stubbed decision. The
/// preparation has to agree with the table entry's: a raw/cooked contradiction
/// costs the match 45% of its score, which is exactly what sends a line to
/// review — see [FoodMatcher].
String draft({
  String canonicalName = 'pollo pechuga',
  String preparation = 'raw',
}) {
  return '''
{
  "schemaVersion": 1,
  "diet": {
    "name": "Plan de prueba",
    "declaredDailyEnergyKcal": 2000,
    "extractedFoods": [
      {
        "ref": "x1",
        "rawText": "140 g de pollo a la plancha",
        "canonicalName": "$canonicalName",
        "preparation": "$preparation",
        "grams": 140,
        "count": null,
        "unit": null,
        "brandNormalizedFrom": null
      }
    ],
    "recipes": [],
    "dayGroups": [
      {
        "label": "TODOS",
        "weekdays": [1, 2, 3, 4, 5, 6, 7],
        "meals": [
          {
            "time": "14:00",
            "label": "COMIDA",
            "notes": [],
            "sections": [
              {
                "label": null,
                "components": [
                  {
                    "alternatives": [
                      {
                        "rawText": "140 g de pollo a la plancha",
                        "foodRef": "x1",
                        "quantity": {"grams": 140, "count": null, "unit": null}
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}''';
}

void main() {
  late FakePdfFilePicker picker;
  late FakePdfRasterizer rasterizer;
  late FakeDietPlanExtractor extractor;
  late FakeDietPlanStore store;

  setUp(() {
    picker = FakePdfFilePicker(
      pick: PickedPdf(
        name: 'plan-julio.pdf',
        bytes: Uint8List.fromList([37, 80, 68, 70]), // "%PDF"
      ),
    );
    rasterizer = FakePdfRasterizer();
    extractor = FakeDietPlanExtractor(document: draft());
    store = FakeDietPlanStore();
  });

  Future<void> openLibrary(WidgetTester tester, {bool configured = true}) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      const DietLibraryScreen(),
      overrides: [
        ...fakeAppOverrides(dietPlanStore: store),
        canImportDietPdfProvider.overrideWithValue(configured),
        pdfFilePickerProvider.overrideWithValue(picker),
        pdfRasterizerProvider.overrideWithValue(rasterizer),
        dietPlanExtractorProvider.overrideWithValue(extractor),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<List<StoredDietPlan>> storedPlans() async {
    return switch (await store.listPlans()) {
      Ok(value: final plans) => plans,
      Err(failure: final failure) => fail('$failure'),
    };
  }

  group('offering the import at all', () {
    testWidgets('hides the entry point when no key is configured', (
      tester,
    ) async {
      // Offering an import that would fail on its first request is worse than
      // not offering it: the user cannot tell a missing key from a bad plan.
      await openLibrary(tester, configured: false);

      expect(find.byKey(const Key('importDietPdfButton')), findsNothing);
      expect(find.byKey(const Key('importFirstDietButton')), findsNothing);
    });

    testWidgets('offers it from the toolbar and the empty state', (
      tester,
    ) async {
      await openLibrary(tester);

      expect(find.byKey(const Key('importDietPdfButton')), findsOneWidget);
      expect(find.byKey(const Key('importFirstDietButton')), findsOneWidget);
    });
  });

  group('reading a plan end to end', () {
    testWidgets('picks, reads, reviews, and stores the plan', (tester) async {
      await openLibrary(tester);

      await tester.tap(find.byKey(const Key('importDietPdfButton')));
      await tester.pumpAndSettle();

      // The review screen is reached with what the plan says.
      expect(find.text('plan-julio.pdf'), findsOneWidget);
      expect(find.text('140 g de pollo a la plancha'), findsOneWidget);
      expect(rasterizer.received, isNotNull);
      expect(extractor.receivedPages, hasLength(3));
      // Nothing is stored until the user confirms.
      expect(await storedPlans(), isEmpty);

      await tester.tap(find.byKey(const Key('confirmImportButton')));
      await tester.pumpAndSettle();

      final plans = await storedPlans();
      expect(plans, hasLength(1));
      expect(plans.single.name, 'Plan de prueba');
      expect(plans.single.sourceLabel, 'plan-julio.pdf');
      expect(plans.single.isDefault, isTrue);
      expect(find.text('Imported plan-julio.pdf'), findsOneWidget);
    });

    testWidgets('shows what it is doing while reading', (tester) async {
      // Reading a scanned plan is minutes of work, so the wait has to be
      // legible rather than a frozen screen.
      extractor.gate = Completer<void>();
      await openLibrary(tester);

      await tester.tap(find.byKey(const Key('importDietPdfButton')));
      // Not pumpAndSettle: the progress indicator animates forever, so settling
      // would time out while the read is deliberately held open.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('importBarrier')), findsOneWidget);
      expect(find.textContaining('Reading plan-julio.pdf'), findsOneWidget);
      // The entry point cannot be triggered twice while one import runs.
      final button = tester.widget<IconButton>(
        find.byKey(const Key('importDietPdfButton')),
      );
      expect(button.onPressed, isNull);

      extractor.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('importBarrier')), findsNothing);
      expect(find.text('plan-julio.pdf'), findsOneWidget); // the review screen
    });

    testWidgets('the food the user settles on is the one stored', (
      tester,
    ) async {
      // A line the matcher cannot place must not block the import, and what the
      // user picks is what the plan derives its macros from.
      extractor.document = draft(canonicalName: 'zzqq imaginary thing');
      await openLibrary(tester);

      await tester.tap(find.byKey(const Key('importDietPdfButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Nothing in the food table matched this line'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('chooseFoodButton-0')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('foodSearchField')), 'arroz');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('candidateOption-rice_white_raw')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmImportButton')));
      await tester.pumpAndSettle();

      expect(await storedPlans(), hasLength(1));
      expect(find.text('Imported plan-julio.pdf'), findsOneWidget);
    });
  });

  group('backing out and breaking down', () {
    testWidgets('cancelling the picker is silent', (tester) async {
      picker.pick = null;
      await openLibrary(tester);

      await tester.tap(find.byKey(const Key('importDietPdfButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byKey(const Key('importBarrier')), findsNothing);
      expect(await storedPlans(), isEmpty);
    });

    testWidgets('leaving the review without confirming stores nothing', (
      tester,
    ) async {
      await openLibrary(tester);
      await tester.tap(find.byKey(const Key('importDietPdfButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(await storedPlans(), isEmpty);
      expect(find.byKey(const Key('importDietPdfButton')), findsOneWidget);
    });

    testWidgets('says which step broke when rendering fails', (tester) async {
      rasterizer.failWith = const StorageFailure('that file is not a PDF');
      await openLibrary(tester);

      await tester.tap(find.byKey(const Key('importDietPdfButton')));
      await tester.pumpAndSettle();

      expect(find.text('that file is not a PDF'), findsOneWidget);
      expect(find.byKey(const Key('importBarrier')), findsNothing);
      expect(await storedPlans(), isEmpty);
    });

    testWidgets('says the plan could not be read when extraction fails', (
      tester,
    ) async {
      extractor.failWith = const MalformedPlanFailure('the model returned prose');
      await openLibrary(tester);

      await tester.tap(find.byKey(const Key('importDietPdfButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not read the plan: the model returned prose'),
        findsOneWidget,
      );
      expect(await storedPlans(), isEmpty);
    });

    testWidgets('reports a picker failure instead of hanging', (tester) async {
      picker.failWith = const StorageFailure('could not open the file picker');
      await openLibrary(tester);

      await tester.tap(find.byKey(const Key('importDietPdfButton')));
      await tester.pumpAndSettle();

      expect(find.text('could not open the file picker'), findsOneWidget);
      expect(find.byKey(const Key('importBarrier')), findsNothing);
    });
  });
}
