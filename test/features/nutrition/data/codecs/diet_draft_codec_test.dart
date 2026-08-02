import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_draft_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';

import '../../_fixtures/draft_document.dart';

const codec = DietDraftCodec();

/// What one ref settled to, with the quantity left alone unless stated.
SettledFood settled(String foodId, {FoodQuantity? quantity}) =>
    SettledFood(foodId: foodId, quantity: quantity);

List<PendingFood> pendingOf(String draft) {
  return switch (codec.readPendingFoods(draft)) {
    Ok(value: final foods) => foods,
    Err(failure: final failure) => fail('$failure'),
  };
}

NutritionFailure failureOf(Result<Object?, NutritionFailure> result) {
  return switch (result) {
    Ok() => fail('expected a failure'),
    Err(failure: final failure) => failure,
  };
}

/// A minimal draft: one group, one meal, one component with two alternatives.
String draft({
  String pendingFoods = '''
  [
    {"ref":"x1","rawText":"140 g de pollo","canonicalName":"chicken breast",
     "preparation":"grilled","grams":140,"count":null,"unit":null,
     "brandNormalizedFrom":null}
  ]''',
  String alternatives = '''
  [
    {"foodRef":"x1","rawText":"140 g de pollo","quantity":{"grams":140}}
  ]''',
  String recipes = '[]',
}) {
  return '''
{
  "schemaVersion": 1,
  "diet": {
    "name": "Draft",
    "extractedFoods": $pendingFoods,
    "recipes": $recipes,
    "dayGroups": [
      {
        "label": "LU",
        "weekdays": [1],
        "meals": [
          {
            "label": "DESAYUNO",
            "sections": [{"label": null, "components": [
              {"alternatives": $alternatives}
            ]}]
          }
        ]
      }
    ]
  }
}''';
}

void main() {
  group('reading the foods a draft has not placed', () {
    test('reads every described field', () {
      final foods = pendingOf(draft(pendingFoods: '''
        [
          {"ref":"x1","rawText":"2 lonchas de Pavo Campofrío (60 g)",
           "canonicalName":"turkey breast","preparation":"cured","grams":60,
           "count":2,"unit":"loncha","brandNormalizedFrom":"Pavo Campofrío"}
        ]'''));

      expect(foods, hasLength(1));
      final food = foods.single;
      expect(food.ref, 'x1');
      expect(food.extracted.rawText, '2 lonchas de Pavo Campofrío (60 g)');
      expect(food.extracted.canonicalName, 'turkey breast');
      expect(food.extracted.preparation, 'cured');
      expect(food.extracted.grams, 60);
      expect(food.extracted.count, 2);
      expect(food.extracted.unit, 'loncha');
      expect(food.extracted.brandNormalizedFrom, 'Pavo Campofrío');
    });

    test('a draft with nothing pending is not an error', () {
      // Every line placed itself. That is a good import, not a broken one.
      final source = jsonDecode(draft()) as Map<String, dynamic>;
      (source['diet'] as Map).remove('extractedFoods');

      expect(pendingOf(jsonEncode(source)), isEmpty);
    });

    test('rejects a duplicate ref instead of silently dropping one', () {
      // Two foods under one ref would make the rewrite ambiguous, and one of the
      // user's decisions would quietly overwrite the other.
      final result = codec.readPendingFoods(draft(pendingFoods: '''
        [
          {"ref":"x1","rawText":"a","canonicalName":"rice","preparation":"raw",
           "grams":100},
          {"ref":"x1","rawText":"b","canonicalName":"oats","preparation":"raw",
           "grams":50}
        ]'''));

      final failure = failureOf(result);
      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('duplicate'));
    });

    test('names the missing field when the model omits one', () {
      final result = codec.readPendingFoods(draft(pendingFoods: '''
        [{"ref":"x1","rawText":"a","preparation":"raw","grams":100}]'''));

      final failure = failureOf(result);
      expect(failure, isA<MalformedPlanFailure>());
      expect(
        (failure as MalformedPlanFailure).reason,
        contains('canonicalName'),
      );
    });

    test('reports prose instead of a document as malformed', () {
      // The likeliest extractor failure: a model that answers in words.
      final failure = failureOf(
        codec.readPendingFoods('I could not read the PDF, sorry!'),
      );

      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('valid JSON'));
    });
  });

  group('baking the decisions into the document', () {
    test('replaces the ref everywhere it appears', () {
      final rewritten = codec.resolveRefs(
        draft(alternatives: '''
        [
          {"foodRef":"x1","rawText":"a","quantity":{"grams":140}},
          {"foodRef":"x1","rawText":"b","quantity":{"grams":100}}
        ]'''),
        {'x1': settled('chicken_breast_grilled')},
      );

      final document = switch (rewritten) {
        Ok(value: final value) => value,
        Err(failure: final failure) => fail('$failure'),
      };
      expect(document, isNot(contains('"x1"')));
      expect(
        'chicken_breast_grilled'.allMatches(document).length,
        2,
        reason: 'both alternatives must be rewritten',
      );
    });

    test('drops the draft section, so the result is a plain document', () {
      // Leaving it in would make the stored document fail its own schema.
      final rewritten = codec.resolveRefs(draft(), {'x1': settled('rice_white_raw')});
      final document = switch (rewritten) {
        Ok(value: final value) => value,
        Err(failure: final failure) => fail('$failure'),
      };

      final diet = (jsonDecode(document) as Map)['diet'] as Map;
      expect(diet.containsKey('extractedFoods'), isFalse);
      expect(jsonDecode(document)['schemaVersion'], 1);
    });

    test('leaves the quantity alone when the user did not correct it', () {
      // One described food can appear in several meals at different weights, so
      // an untouched line must keep each mention's own quantity. Writing a
      // single reading everywhere would rewrite meals nobody looked at.
      final rewritten = codec.resolveRefs(
        draft(alternatives: '''
        [
          {"foodRef":"x1","rawText":"a","quantity":{"grams":140}},
          {"foodRef":"x1","rawText":"b","quantity":{"grams":100}}
        ]'''),
        {'x1': settled('chicken_breast_grilled')},
      );

      final document = switch (rewritten) {
        Ok(value: final value) => value,
        Err(failure: final failure) => fail('$failure'),
      };
      final alternatives = _alternativesOf(document);
      expect(alternatives[0]['quantity']['grams'], 140);
      expect(alternatives[1]['quantity']['grams'], 100);
    });

    test('writes a corrected quantity over what the extraction read', () {
      // The invisible failure this guards: "2 portions (110 g)" read as 220 g
      // decodes perfectly and doubles the meal forever.
      final rewritten = codec.resolveRefs(
        draft(),
        {
          'x1': settled(
            'chicken_breast_grilled',
            quantity: FoodQuantity(grams: 110, count: 2, unit: 'porcion'),
          ),
        },
      );

      final document = switch (rewritten) {
        Ok(value: final value) => value,
        Err(failure: final failure) => fail('$failure'),
      };
      final quantity = _alternativesOf(document).single['quantity'];
      expect(quantity['grams'], 110);
      expect(quantity['count'], 2);
      expect(quantity['unit'], 'porcion');
    });

    test('refuses to rewrite while a ref is unsettled', () {
      // The whole safety property: an unsettled ref would become a dangling id
      // in a stored plan, which only shows up when the user opens that day.
      final result = codec.resolveRefs(
        draft(pendingFoods: '''
        [
          {"ref":"x1","rawText":"a","canonicalName":"chicken breast",
           "preparation":"grilled","grams":140},
          {"ref":"x2","rawText":"b","canonicalName":"rice","preparation":"raw",
           "grams":80}
        ]''', alternatives: '''
        [
          {"foodRef":"x1","rawText":"a","quantity":{"grams":140}},
          {"foodRef":"x2","rawText":"b","quantity":{"grams":80}}
        ]'''),
        {'x1': settled('chicken_breast_grilled')},
      );

      final failure = failureOf(result);
      expect(failure, isA<UnknownFoodFailure>());
      expect((failure as UnknownFoodFailure).sortedIds, ['x2']);
    });

    test('leaves recipe ids alone', () {
      // A plan that prints its own nutrition table has already placed those
      // foods; asking the user about them would be noise.
      final rewritten = codec.resolveRefs(
        draft(
          recipes: '''
          [{"id":"recipe_turkey","name":"Fiambre de pavo",
            "per100g":{"energyKcal":67,"proteinG":9,"carbsG":4,"fatG":1}}]''',
          alternatives: '''
          [
            {"foodRef":"x1","rawText":"a","quantity":{"grams":140}},
            {"foodRef":"recipe_turkey","rawText":"b","quantity":{"grams":50}}
          ]''',
        ),
        {'x1': settled('chicken_breast_grilled')},
      );

      final document = switch (rewritten) {
        Ok(value: final value) => value,
        Err(failure: final failure) => fail('$failure'),
      };
      expect(document, contains('recipe_turkey'));
    });

    test('refuses a draft written to an unknown schema', () {
      final failure = failureOf(
        codec.resolveRefs(
          '{"schemaVersion":99,"diet":{"dayGroups":[]}}',
          const {},
        ),
      );

      expect(failure, isA<MalformedPlanFailure>());
      expect(
        (failure as MalformedPlanFailure).reason,
        contains('schemaVersion'),
      );
    });

    test('reports a draft whose shape is wrong instead of crashing', () {
      final failure = failureOf(
        codec.resolveRefs('{"schemaVersion":1,"diet":{"dayGroups":"nope"}}', {}),
      );

      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('dayGroups'));
    });
  });

  group('against the real shipped plan', () {
    late String document;
    late String realDraft;

    setUpAll(() {
      document =
          File('assets/diets/nutrium_david_2950kcal.json').readAsStringSync();
      realDraft = draftFromDocument(document);
    });

    test('reads every food the plan names', () {
      final pending = pendingOf(realDraft);

      expect(pending, hasLength(originalFoodIds(document).length));
      expect(pending.length, greaterThan(20));
      // Refs are unique and the descriptions carry the plan's own wording.
      expect(pending.map((food) => food.ref).toSet(), hasLength(pending.length));
      expect(pending.every((food) => food.extracted.rawText.isNotEmpty), isTrue);
    });

    test('a fully settled draft round-trips back to the original document', () {
      // The strongest guarantee available without a live model: refs out, ids
      // back in, and what comes out is byte-identical to the shipped plan.
      final pending = pendingOf(realDraft);
      final ids = originalFoodIds(document);
      final decisions = <String, SettledFood>{
        for (var i = 0; i < pending.length; i++)
          pending[i].ref: settled(ids[i]),
      };

      final rewritten = codec.resolveRefs(realDraft, decisions);
      final result = switch (rewritten) {
        Ok(value: final value) => value,
        Err(failure: final failure) => fail('$failure'),
      };

      expect(jsonDecode(result), jsonDecode(document));
    });
  });
}

/// The alternatives of the single component in a rewritten minimal document.
List<dynamic> _alternativesOf(String document) {
  final diet = (jsonDecode(document) as Map)['diet'] as Map;
  final meal = ((diet['dayGroups'] as List).single as Map)['meals'] as List;
  final section = ((meal.single as Map)['sections'] as List).single as Map;
  final component = (section['components'] as List).single as Map;
  return component['alternatives'] as List;
}
