import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/food_table_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/extracted_food_resolver.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_matcher.dart';

ExtractedFood extracted(
  String canonicalName, {
  String preparation = 'raw',
  String? rawText,
  num grams = 100,
}) {
  return ExtractedFood(
    rawText: rawText ?? '$grams gramos de $canonicalName',
    canonicalName: canonicalName,
    preparation: preparation,
    grams: grams,
  );
}

void main() {
  late ExtractedFoodResolver resolver;

  setUpAll(() {
    final decoded = const FoodTableCodec().decode(
      File('assets/nutrition/food_table.json').readAsStringSync(),
    );
    final catalog = switch (decoded) {
      Ok(value: final foods) => FoodCatalog(foods),
      Err(failure: final failure) => fail('food table: $failure'),
    };
    resolver = ExtractedFoodResolver(FoodMatcher(catalog));
  });

  group('resolving lines from an arbitrary plan', () {
    test('places common foods confidently', () {
      for (final food in [
        extracted('chicken breast', preparation: 'grilled'),
        extracted('white rice', preparation: 'raw'),
        extracted('atlantic salmon'),
        extracted('whole egg'),
        extracted('blueberries'),
      ]) {
        final resolution = resolver.resolve(food);
        expect(resolution.isResolved, isTrue, reason: food.canonicalName);
        expect(
          resolution.needsReview,
          isFalse,
          reason:
              '${food.canonicalName} -> ${resolution.food?.name} '
              '(${resolution.best?.score.toStringAsFixed(2)})',
        );
      }
    });

    test('honours the stated preparation when picking the entry', () {
      final raw = resolver.resolve(extracted('white rice', preparation: 'raw'));
      final boiled = resolver.resolve(
        extracted('white rice', preparation: 'boiled'),
      );

      expect(raw.food, isNotNull);
      expect(boiled.food, isNotNull);
      expect(raw.food!.id, isNot(boiled.food!.id));
      expect(raw.food!.per100g.energy.kcal, greaterThan(300));
      expect(boiled.food!.per100g.energy.kcal, lessThan(200));
    });
  });

  group('refusing to guess', () {
    test('reports an unknown food as unresolved, not as a bad match', () {
      final resolution = resolver.resolve(extracted('zzqq imaginary thing'));

      expect(resolution.isResolved, isFalse);
      expect(resolution.food, isNull);
      expect(resolution.needsReview, isTrue);
      expect(resolution.candidates, isEmpty);
    });

    test('flags a merely plausible match for review', () {
      // A vague line can still find something, but accepting it silently would
      // attach guessed macros to the user's meal without ever saying so.
      final resolution = ExtractedFoodResolver(
        FoodMatcher(FoodCatalog(const [])),
        reviewThreshold: 0.99,
      ).resolve(extracted('anything'));
      expect(resolution.needsReview, isTrue);
    });

    test('keeps candidates so the user can settle a doubtful line', () {
      final resolution = resolver.resolve(extracted('cheese'));
      expect(resolution.candidates.length, greaterThan(1));
      // Ranked best first, so a picker can show them in order.
      for (var i = 1; i < resolution.candidates.length; i++) {
        expect(
          resolution.candidates[i - 1].score,
          greaterThanOrEqualTo(resolution.candidates[i].score),
        );
      }
    });
  });

  group('tolerating extractor output', () {
    test('an unknown preparation word does not abort resolution', () {
      // A model may return something outside our enum; that must degrade to
      // "unstated", not break the import.
      final resolution = resolver.resolve(
        extracted('chicken breast', preparation: 'sous-vide'),
      );
      expect(resolution.isResolved, isTrue);
    });

    test('a preparation phrase is still understood', () {
      final resolution = resolver.resolve(
        extracted('white rice', preparation: 'hervido'),
      );
      expect(resolution.food, isNotNull);
      expect(resolution.food!.per100g.energy.kcal, lessThan(200));
    });

    test('resolveAll keeps input order', () {
      final resolutions = resolver.resolveAll([
        extracted('honey'),
        extracted('zzqq imaginary thing'),
        extracted('strawberries'),
      ]);

      expect(resolutions, hasLength(3));
      expect(resolutions[0].isResolved, isTrue);
      expect(resolutions[1].isResolved, isFalse);
      expect(resolutions[2].isResolved, isTrue);
      expect(resolutions[1].extracted.canonicalName, 'zzqq imaginary thing');
    });
  });
}
