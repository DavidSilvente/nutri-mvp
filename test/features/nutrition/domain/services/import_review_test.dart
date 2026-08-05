import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/extracted_food_resolver.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_matcher.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/import_review.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';

import '../../_fakes/fake_diet_plan_store.dart';

ExtractedFood extracted(String canonicalName, {num grams = 100}) {
  return ExtractedFood(
    rawText: '$grams gramos de $canonicalName',
    canonicalName: canonicalName,
    preparation: 'raw',
    grams: grams,
  );
}

/// A resolution with a hand-built candidate list, so the review's own rules can
/// be tested without depending on how the matcher scores today.
FoodResolution resolution(
  String canonicalName, {
  List<(String, double)> candidates = const [],
  double reviewThreshold = 0.75,
}) {
  return FoodResolution(
    extracted: extracted(canonicalName),
    candidates: [
      for (final (id, score) in candidates)
        FoodMatch(food: FakeFoodTableSource.food(id), score: score),
    ],
    reviewThreshold: reviewThreshold,
  );
}

void main() {
  group('starting a review', () {
    test('pre-fills the lines the resolver was confident about', () {
      final review = ImportReview.from([
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
      ]);

      final entry = review.entries.single;
      expect(entry.isSettled, isTrue);
      expect(entry.food!.id, 'chicken_breast_grilled');
      expect(entry.score, 0.9);
      expect(entry.chosenByUser, isFalse);
      expect(review.isComplete, isTrue);
    });

    test('leaves a merely plausible match blank rather than pre-filling it', () {
      // The whole point of the screen: a match below the threshold is a guess,
      // and pre-selecting it would let the user tap through without deciding.
      final review = ImportReview.from([
        resolution('cheese', candidates: [('rice_white_raw', 0.6)]),
      ]);

      final entry = review.entries.single;
      expect(entry.isSettled, isFalse);
      expect(entry.food, isNull);
      expect(entry.resolution.candidates, hasLength(1));
      expect(review.isComplete, isFalse);
    });

    test('leaves a line with no candidates blank', () {
      final review = ImportReview.from([resolution('zzqq imaginary')]);

      expect(review.entries.single.isSettled, isFalse);
      expect(review.pendingCount, 1);
    });

    test('keeps plan order and counts what is pending', () {
      final review = ImportReview.from([
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
        resolution('zzqq imaginary'),
        resolution('white rice', candidates: [('rice_white_raw', 0.88)]),
      ]);

      expect(review.length, 3);
      expect(review.pendingCount, 1);
      expect(review.pending.single.extracted.canonicalName, 'zzqq imaginary');
      expect(review.isComplete, isFalse);
    });
  });

  group('settling a line', () {
    late ImportReview review;

    setUp(() {
      review = ImportReview.from([
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
        resolution('zzqq imaginary'),
      ]);
    });

    test('completes the review once every line has a food', () {
      final settled = review.select(1, FakeFoodTableSource.food('beef_loin'));

      expect(settled.isComplete, isTrue);
      expect(settled.entries[1].food!.id, 'beef_loin');
      expect(settled.entries[1].chosenByUser, isTrue);
    });

    test('does not mutate the review it came from', () {
      review.select(1, FakeFoodTableSource.food('beef_loin'));

      expect(review.isComplete, isFalse);
      expect(review.entries[1].food, isNull);
    });

    test('overriding a confident match marks it as the user\'s pick', () {
      final settled = review.select(
        0,
        FakeFoodTableSource.food('beef_loin'),
        score: 0.42,
      );

      expect(settled.entries[0].food!.id, 'beef_loin');
      expect(settled.entries[0].score, 0.42);
      expect(settled.entries[0].chosenByUser, isTrue);
      expect(settled.correctedCount, 1);
    });
  });

  group('correcting how much a line calls for', () {
    late ImportReview review;

    setUp(() {
      review = ImportReview.from([
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
      ]);
    });

    test(
      'starts from what the extraction read, without claiming a correction',
      () {
        final entry = review.entries.single;

        expect(entry.quantityWasCorrected, isFalse);
        expect(entry.quantity, isNull);
        expect(entry.effectiveQuantity.grams, 100);
        expect(review.requantifiedCount, 0);
      },
    );

    test('records a correction as an override', () {
      // Null and "the same numbers" mean different things downstream: only an
      // override is written over the document's own quantities.
      final corrected = review.setQuantity(
        0,
        FoodQuantity(grams: 110, count: 2, unit: 'porcion'),
      );

      final entry = corrected.entries.single;
      expect(entry.quantityWasCorrected, isTrue);
      expect(entry.effectiveQuantity.grams, 110);
      expect(entry.effectiveQuantity.count, 2);
      expect(corrected.requantifiedCount, 1);
      expect(corrected.decisions.single.quantity, isNotNull);
    });

    test('a line nobody corrected hands back no quantity at all', () {
      expect(review.decisions.single.quantity, isNull);
    });

    test('does not mutate the review it came from', () {
      review.setQuantity(0, FoodQuantity(grams: 999));

      expect(review.entries.single.quantityWasCorrected, isFalse);
    });

    test('survives changing the food afterwards', () {
      // The two corrections are independent: picking a different food must not
      // silently undo a weight the user already fixed.
      final corrected = review
          .setQuantity(0, FoodQuantity(grams: 110))
          .select(0, FakeFoodTableSource.food('beef_loin'));

      expect(corrected.entries.single.food!.id, 'beef_loin');
      expect(corrected.entries.single.effectiveQuantity.grams, 110);
    });

    test('refuses a weight that cannot be eaten', () {
      expect(() => FoodQuantity(grams: 0), throwsArgumentError);
      expect(() => FoodQuantity(grams: -5), throwsArgumentError);
    });
  });

  group('handing decisions to the import', () {
    test('refuses to produce decisions while a line is unsettled', () {
      // Dropping the unsettled lines instead would silently import a plan
      // missing exactly the foods that were hardest to read.
      final review = ImportReview.from([
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
        resolution('zzqq imaginary'),
      ]);

      expect(() => review.decisions, throwsStateError);
    });

    test('returns every line in plan order, saying which the user picked', () {
      final review = ImportReview.from([
        resolution(
          'chicken breast',
          candidates: [('chicken_breast_grilled', 0.9)],
        ),
        resolution('zzqq imaginary'),
      ]).select(1, FakeFoodTableSource.food('ham_serrano'));

      final decisions = review.decisions;
      expect(decisions, hasLength(2));
      expect(decisions[0].food.id, 'chicken_breast_grilled');
      expect(decisions[0].chosenByUser, isFalse);
      expect(decisions[0].extracted.canonicalName, 'chicken breast');
      expect(decisions[1].food.id, 'ham_serrano');
      expect(decisions[1].chosenByUser, isTrue);
    });

    test('an empty plan is complete and produces nothing', () {
      final review = ImportReview.from(const <FoodResolution>[]);

      expect(review.isComplete, isTrue);
      expect(review.decisions, isEmpty);
    });
  });

  test('a real resolver feeds the review directly', () {
    // The screen is built on whatever the resolver produces, so the two must
    // actually fit together — not just in a hand-built fixture.
    // A tiny catalog, so this never loads the shipped 6910-food table.
    final resolver = ExtractedFoodResolver(
      FoodMatcher(FoodCatalog(FakeFoodTableSource.defaultFoods())),
    );
    final review = ImportReview.from(
      resolver.resolveAll([extracted('zzqq imaginary'), extracted('arroz')]),
    );

    expect(review.length, 2);
    expect(review.entries[0].isSettled, isFalse);
    expect(review.entries[0].resolution.candidates, isEmpty);
  });
}
