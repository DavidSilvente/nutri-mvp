import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/extracted_food_resolver.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_matcher.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/import_review.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/import_review_screen.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_diet_plan_store.dart';

ExtractedFood extracted(String canonicalName, {num grams = 100}) {
  return ExtractedFood(
    rawText: '$grams g de $canonicalName',
    canonicalName: canonicalName,
    preparation: 'raw',
    grams: grams,
  );
}

FoodResolution resolution(
  String canonicalName, {
  List<(String, double)> candidates = const [],
}) {
  return FoodResolution(
    extracted: extracted(canonicalName),
    candidates: [
      for (final (id, score) in candidates)
        FoodMatch(
          food: FakeFoodTableSource.food(id, name: _names[id] ?? id),
          score: score,
        ),
    ],
    reviewThreshold: 0.75,
  );
}

const _names = {
  'chicken_breast_grilled': 'Pollo, pechuga',
  'rice_white_raw': 'Arroz blanco',
  'beef_loin': 'Ternera, lomo',
  'ham_serrano': 'Jamón serrano',
};

void main() {
  /// Mounts the screen on its own route, the way the import flow will push it.
  Future<void> openScreen(
    WidgetTester tester,
    List<FoodResolution> resolutions,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      ImportReviewScreen(
        resolutions: resolutions,
        sourceLabel: 'plan-julio.pdf',
      ),
      overrides: [
        foodTableSourceProvider.overrideWithValue(FakeFoodTableSource()),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('showing what the plan says', () {
    testWidgets('lists every line with its quantity and source label', (
      tester,
    ) async {
      await openScreen(tester, [
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
        resolution('zzqq imaginary'),
      ]);

      expect(find.text('plan-julio.pdf'), findsOneWidget);
      expect(find.byKey(const Key('reviewLine-0')), findsOneWidget);
      expect(find.byKey(const Key('reviewLine-1')), findsOneWidget);
      expect(find.text('100 g de chicken breast'), findsOneWidget);
      expect(find.text('100 g · chicken breast, raw'), findsOneWidget);
    });

    testWidgets('shows the confident match and how sure it was', (
      tester,
    ) async {
      await openScreen(tester, [
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
      ]);

      expect(find.text('Pollo, pechuga'), findsOneWidget);
      expect(find.text('Match 90%'), findsOneWidget);
      expect(find.text('Change food'), findsOneWidget);
    });

    testWidgets('says a doubtful line is unsettled instead of showing a pick', (
      tester,
    ) async {
      await openScreen(tester, [
        resolution('cheese', candidates: [('rice_white_raw', 0.6)]),
      ]);

      // The 0.6 match exists but is below the threshold: it must not appear as
      // a decision, or the user would accept guessed macros without knowing.
      expect(find.text('Arroz blanco'), findsNothing);
      expect(find.text('No confident match — 1 option to check'), findsOneWidget);
      expect(find.text('Choose a food'), findsOneWidget);
    });

    testWidgets('says so when nothing in the table matched at all', (
      tester,
    ) async {
      await openScreen(tester, [resolution('zzqq imaginary')]);

      expect(
        find.text('Nothing in the food table matched this line'),
        findsOneWidget,
      );
    });
  });

  group('blocking the import until every line is settled', () {
    testWidgets('the confirm button is disabled while lines are pending', (
      tester,
    ) async {
      await openScreen(tester, [
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
        resolution('zzqq imaginary'),
      ]);

      expect(find.text('1 of 2 lines need your call'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('confirmImportButton')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('1 line still needs a food'), findsOneWidget);
    });

    testWidgets('the confirm button is live when every line has a food', (
      tester,
    ) async {
      await openScreen(tester, [
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
      ]);

      expect(find.text('Every line is settled'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('confirmImportButton')),
      );
      expect(button.onPressed, isNotNull);
      expect(find.text('Import 1 food'), findsOneWidget);
    });
  });

  group('settling a line', () {
    testWidgets('picking a candidate resolves it and unblocks the import', (
      tester,
    ) async {
      await openScreen(tester, [
        resolution('cheese', candidates: [('rice_white_raw', 0.6)]),
      ]);

      await tester.tap(find.byKey(const Key('chooseFoodButton-0')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('candidateOption-rice_white_raw')));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco'), findsOneWidget);
      expect(find.text('Your pick'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('confirmImportButton')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('a line with no candidates can be settled by searching', (
      tester,
    ) async {
      // Without free-text search this line could never be settled, so the
      // import would be blocked forever.
      await openScreen(tester, [resolution('zzqq imaginary')]);

      await tester.tap(find.byKey(const Key('chooseFoodButton-0')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Nothing matched this line automatically. '
          'Search for the food above.',
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('foodSearchField')), 'jamon');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('candidateOption-ham_serrano')));
      await tester.pumpAndSettle();

      expect(find.text('Jamón serrano'), findsOneWidget);
      expect(find.text('Import 1 food'), findsOneWidget);
    });

    testWidgets('backing out of the picker leaves the line untouched', (
      tester,
    ) async {
      await openScreen(tester, [resolution('zzqq imaginary')]);

      await tester.tap(find.byKey(const Key('chooseFoodButton-0')));
      await tester.pumpAndSettle();
      // Tap the scrim above the sheet.
      await tester.tapAt(const Offset(500, 20));
      await tester.pumpAndSettle();

      expect(find.text('1 of 1 lines need your call'), findsOneWidget);
    });
  });

  testWidgets('confirming hands back every decision in plan order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    List<ReviewedFood>? popped;
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<List<ReviewedFood>>(
                MaterialPageRoute(
                  builder: (_) => ImportReviewScreen(
                    sourceLabel: 'plan-julio.pdf',
                    resolutions: [
                      resolution(
                        'chicken breast',
                        candidates: [('chicken_breast_grilled', 0.9)],
                      ),
                      resolution('zzqq imaginary'),
                    ],
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [
        foodTableSourceProvider.overrideWithValue(FakeFoodTableSource()),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chooseFoodButton-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('foodSearchField')), 'ternera');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('candidateOption-beef_loin')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirmImportButton')));
    await tester.pumpAndSettle();

    expect(popped, hasLength(2));
    expect(popped![0].food.id, 'chicken_breast_grilled');
    expect(popped![0].chosenByUser, isFalse);
    expect(popped![0].extracted.canonicalName, 'chicken breast');
    expect(popped![1].food.id, 'beef_loin');
    expect(popped![1].chosenByUser, isTrue);
  });
}
