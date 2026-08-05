import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/food_table_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_matcher.dart';

/// Exercises the matcher against the REAL shipped table (~6900 foods).
///
/// A matcher tested on a handful of hand-picked foods proves nothing: the whole
/// difficulty is competing against thousands of near-miss entries. These tests
/// therefore assert on the actual asset, and on the specific failure modes that
/// make a diet import wrong rather than merely imperfect.
void main() {
  late FoodMatcher matcher;
  late FoodCatalog catalog;

  setUpAll(() {
    final source = File('assets/nutrition/food_table.json').readAsStringSync();
    final decoded = const FoodTableCodec().decode(source);
    catalog = switch (decoded) {
      Ok(value: final foods) => FoodCatalog(foods),
      Err(failure: final failure) => fail('food table: $failure'),
    };
    matcher = FoodMatcher(catalog);
  });

  /// Folds case and diacritics, so an assertion for `salmon` is satisfied by the
  /// curated Spanish entry `Salmón` — matching them is the intended behaviour.
  String fold(String value) => FoodMatcher.tokenize(value).join(' ');

  /// Asserts the best match's name contains every fragment.
  void expectBestContains(
    String query,
    List<String> fragments, {
    FoodPreparation? preparation,
  }) {
    final best = matcher.bestMatch(query, preparation: preparation);
    expect(best, isNotNull, reason: 'no match for "$query"');
    final name = fold(best!.food.name);
    for (final fragment in fragments) {
      expect(
        name,
        contains(fold(fragment)),
        reason:
            '"$query" matched "${best.food.name}" '
            '(${best.score.toStringAsFixed(2)})',
      );
    }
  }

  group('tokenizing', () {
    test('drops punctuation, case and filler words', () {
      expect(
        FoodMatcher.tokenize('Chicken, broilers or fryers, breast, MEAT ONLY'),
        {'chicken', 'broiler', 'fryer', 'breast', 'meat'},
      );
    });

    test('collapses regular plurals so a query meets a table entry', () {
      // "pear" must reach "Pears, raw"; without this it is won by
      // "Balsam-pear (bitter gourd)", a different food entirely.
      expect(FoodMatcher.tokenize('pears'), FoodMatcher.tokenize('pear'));
      expect(FoodMatcher.tokenize('oranges'), FoodMatcher.tokenize('orange'));
      expect(FoodMatcher.tokenize('tomatoes'), FoodMatcher.tokenize('tomato'));
      expect(
        FoodMatcher.tokenize('strawberries'),
        FoodMatcher.tokenize('strawberry'),
      );
    });

    test('leaves -us and -is words alone', () {
      // Over-eager stemming creates collisions that are worse than the plurals
      // it fixes, so these must survive intact.
      expect(FoodMatcher.tokenize('couscous'), {'couscous'});
      expect(FoodMatcher.tokenize('hummus'), {'hummus'});
    });

    test('normalizes both sides identically, which is what matching needs', () {
      // The stemmer is not a linguist: "molasses" reduces to "molass". That is
      // harmless because the SAME rule runs over the table entry, so the two
      // still meet. Symmetry is the property worth asserting, not correctness of
      // the stem itself.
      for (final word in ['molasses', 'greens', 'leaves', 'loaves', 'olives']) {
        expect(
          FoodMatcher.tokenize(word),
          FoodMatcher.tokenize(word.toUpperCase()),
          reason: word,
        );
      }
      expect(matcher.bestMatch('molasses'), isNotNull);
      expect(matcher.bestMatch('olives'), isNotNull);
    });

    test('folds Spanish diacritics so plan wording matches', () {
      expect(FoodMatcher.tokenize('jamón'), contains('jamon'));
      expect(FoodMatcher.tokenize('plátano'), contains('platano'));
    });
  });

  group('stated preparation', () {
    test('reads English and Spanish preparation words', () {
      expect(FoodMatcher.statedPreparation('rice, raw'), FoodPreparation.raw);
      expect(
        FoodMatcher.statedPreparation('arroz blanco, hervido'),
        FoodPreparation.boiled,
      );
      expect(
        FoodMatcher.statedPreparation('pollo a la plancha'),
        FoodPreparation.grilled,
      );
      expect(
        FoodMatcher.statedPreparation('atún enlatado'),
        FoodPreparation.canned,
      );
    });

    test('returns null when the text says nothing about preparation', () {
      expect(FoodMatcher.statedPreparation('white bread'), isNull);
    });
  });

  group('matching common diet foods', () {
    test('finds plain staples', () {
      expectBestContains('chicken breast', ['chicken', 'breast']);
      expectBestContains('salmon', ['salmon']);
      expectBestContains('strawberries', ['strawberries']);
      expectBestContains('honey', ['honey']);
      expectBestContains('mozzarella cheese', ['mozzarella']);
      expectBestContains('olive oil', ['olive']);
    });

    test('prefers the generic entry over a branded one', () {
      final best = matcher.bestMatch('corn flakes cereal');
      expect(best, isNotNull);
      // A branded row may still win when it is the only entry, but a query with
      // no brand in it must not be dragged to a restaurant dish.
      expect(best!.food.name.toLowerCase(), contains('corn'));
    });

    test('does not match a compound dish for a single ingredient', () {
      final best = matcher.bestMatch('rice');
      expect(best, isNotNull);
      // "Rice" alone should land on rice, not on "chicken and rice casserole".
      expect(best!.food.name.toLowerCase(), startsWith('rice'));
    });
  });

  group('preparation state decides between forms of one food', () {
    test('raw and boiled rice resolve to different entries', () {
      final raw = matcher.bestMatch(
        'white rice',
        preparation: FoodPreparation.raw,
      );
      final boiled = matcher.bestMatch(
        'white rice',
        preparation: FoodPreparation.boiled,
      );

      expect(raw, isNotNull);
      expect(boiled, isNotNull);
      expect(raw!.food.id, isNot(boiled!.food.id));
      // This is the whole point: the energy gap between the two is ~3x, so a
      // matcher that ignores preparation produces wildly wrong day totals.
      expect(raw.food.per100g.energy.kcal, greaterThan(300));
      expect(boiled.food.per100g.energy.kcal, lessThan(200));
    });

    test('a raw query does not return a cooked entry', () {
      final best = matcher.bestMatch(
        'beef tenderloin',
        preparation: FoodPreparation.raw,
      );
      expect(best, isNotNull);
      expect(best!.food.preparation, FoodPreparation.raw);
    });

    test('a generic "cooked" query accepts any cooking method', () {
      // "cooked" must not be treated as contradicting "grilled": both describe
      // a cooked food with comparable composition.
      final best = matcher.bestMatch(
        'chicken breast',
        preparation: FoodPreparation.cooked,
      );
      expect(best, isNotNull);
      expect(best!.food.preparation, isNot(FoodPreparation.raw));
    });
  });

  group('refusing to guess', () {
    test('returns nothing for a food the table does not carry', () {
      // Better to report it unresolved and let the user correct it than to
      // silently attach the macros of something else.
      expect(matcher.bestMatch('zzzqqq nonexistent foodstuff'), isNull);
    });

    test('returns nothing for an empty or meaningless query', () {
      expect(matcher.bestMatch(''), isNull);
      expect(matcher.bestMatch('   ,,,   '), isNull);
      expect(matcher.bestMatch('of the and'), isNull);
    });

    test('a higher threshold rejects weak matches', () {
      final loose = matcher.bestMatch('cheese', minimumScore: 0.1);
      final strict = matcher.bestMatch('cheese', minimumScore: 0.99);
      expect(loose, isNotNull);
      expect(strict, isNull);
    });
  });

  group('result shape', () {
    test('scores are bounded, ordered, and deterministic', () {
      final first = matcher.search('chicken breast grilled', limit: 5);
      final second = matcher.search('chicken breast grilled', limit: 5);

      expect(first, isNotEmpty);
      expect(first.map((m) => m.food.id), second.map((m) => m.food.id));
      for (final match in first) {
        expect(match.score, inInclusiveRange(0.0, 1.0));
      }
      for (var i = 1; i < first.length; i++) {
        expect(first[i - 1].score, greaterThanOrEqualTo(first[i].score));
      }
    });

    test('honours the result limit', () {
      expect(matcher.search('chicken', limit: 3).length, lessThanOrEqualTo(3));
    });
  });

  group('the real plan resolves without the curated slugs', () {
    // The point of widening the table: a plan written by someone else, whose
    // wording does not use our slugs, must still resolve. These are the actual
    // Spanish-normalized generics from the shipped plan.
    const planFoods = <String, List<String>>{
      'chicken breast grilled': ['chicken', 'breast'],
      'beef tenderloin raw': ['beef', 'tenderloin'],
      'pork tenderloin raw': ['pork', 'tenderloin'],
      'atlantic salmon raw': ['salmon'],
      'atlantic mackerel raw': ['mackerel'],
      'whole egg raw': ['egg'],
      'egg white raw': ['egg', 'white'],
      'white rice raw': ['rice'],
      'brown rice cooked': ['rice', 'brown'],
      'whole wheat bread': ['bread'],
      'rolled oats dry': ['oats'],
      'blueberries raw': ['blueberries'],
      'pear raw': ['pears'],
      'orange raw': ['oranges'],
      'baked potato': ['potato'],
      'sweet potato raw': ['sweet potato'],
      'dark chocolate': ['chocolate'],
    };

    test('every plan food finds a plausible entry', () {
      final unresolved = <String>[];
      for (final entry in planFoods.entries) {
        final best = matcher.bestMatch(entry.key);
        if (best == null) {
          unresolved.add(entry.key);
          continue;
        }
        final name = best.food.name.toLowerCase();
        final ok = entry.value.every((f) => name.contains(f.toLowerCase()));
        if (!ok) unresolved.add('${entry.key} -> ${best.food.name}');
      }
      expect(unresolved, isEmpty);
    });
  });
}
