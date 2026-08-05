import 'dart:math' as math;

import '../entities/food_item.dart';
import 'food_catalog.dart';

/// A candidate food for a free-text query, with the score it earned.
class FoodMatch {
  const FoodMatch({required this.food, required this.score});

  final FoodItem food;

  /// Confidence in 0..1. Comparable across queries, since the token-coverage
  /// component is normalized by the query's own weight.
  final double score;

  @override
  String toString() => 'FoodMatch(${food.id}, ${score.toStringAsFixed(3)})';
}

/// Resolves free-text food descriptions to entries in a [FoodCatalog].
///
/// Exists because an imported plan names foods in prose ("chicken breast,
/// grilled"), while macros can only come from a catalog entry. Doing this
/// locally rather than asking a model to invent the numbers keeps every figure
/// traceable to a published table.
///
/// Scoring, in order of what actually decides matches:
///
/// * IDF-weighted token overlap. Without IDF, "chicken" would count as much as
///   "gizzard", and a query for chicken breast would be pulled toward whichever
///   chicken entry happened to share the most filler words.
/// * An F-score blend of query coverage and name coverage, biased toward query
///   coverage. This is what makes the concise generic entry beat a long
///   compound dish that happens to mention the same food.
/// * Preparation agreement. Raw and cooked forms of one food differ by up to 3x
///   in energy, so a contradiction is punished hard rather than treated as a
///   minor mismatch.
/// * Brand and curation tie-breakers.
class FoodMatcher {
  FoodMatcher(this._catalog) {
    _buildIndex();
  }

  final FoodCatalog _catalog;

  /// token -> ids of foods whose name contains it.
  final Map<String, Set<String>> _postings = {};

  /// token -> inverse document frequency.
  final Map<String, double> _idf = {};

  /// id -> its name's tokens.
  final Map<String, Set<String>> _nameTokens = {};

  /// Below this, a match is not worth offering; the caller should treat the food
  /// as unresolved rather than guess.
  static const double defaultMinimumScore = 0.45;

  /// Words carrying no discriminating power in food descriptions.
  static const Set<String> _stopWords = {
    'and',
    'or',
    'with',
    'without',
    'the',
    'of',
    'in',
    'a',
    'an',
    'to',
    'includes',
    'foods',
    'food',
    'for',
    'usda',
    'distribution',
    'program',
    'commercially',
    'prepared',
    'all',
    'types',
    'type',
    'variety',
    'varieties',
    'commercial',
    'only',
    'separable',
    'trimmed',
    'added',
    'solution',
    'enhanced',
    'unspecified',
    'ns',
    'nfs',
  };

  /// Preparation words a query may state, mapped to the enum.
  static const Map<String, FoodPreparation> _preparationWords = {
    'raw': FoodPreparation.raw,
    'uncooked': FoodPreparation.raw,
    'crudo': FoodPreparation.raw,
    'cruda': FoodPreparation.raw,
    'boiled': FoodPreparation.boiled,
    'hervido': FoodPreparation.boiled,
    'cocido': FoodPreparation.boiled,
    'baked': FoodPreparation.baked,
    'horno': FoodPreparation.baked,
    'grilled': FoodPreparation.grilled,
    'broiled': FoodPreparation.grilled,
    'plancha': FoodPreparation.grilled,
    'parrilla': FoodPreparation.grilled,
    'roasted': FoodPreparation.roasted,
    'asado': FoodPreparation.roasted,
    'cooked': FoodPreparation.cooked,
    'fried': FoodPreparation.cooked,
    'frito': FoodPreparation.cooked,
    'canned': FoodPreparation.canned,
    'enlatado': FoodPreparation.canned,
    'cured': FoodPreparation.cured,
    'curado': FoodPreparation.cured,
    'smoked': FoodPreparation.cured,
    'dried': FoodPreparation.cured,
  };

  void _buildIndex() {
    for (final food in _catalog.all) {
      final tokens = tokenize(food.name);
      _nameTokens[food.id] = tokens;
      for (final token in tokens) {
        (_postings[token] ??= <String>{}).add(food.id);
      }
    }
    final total = _nameTokens.length;
    for (final entry in _postings.entries) {
      // Smoothed IDF, so a token present in every name still has a floor above
      // zero instead of silently dropping out of the score.
      _idf[entry.key] = 1.0 + math.log(total / (1 + entry.value.length));
    }
  }

  /// Splits [text] into lowercase, punctuation-free, singularized tokens.
  static Set<String> tokenize(String text) {
    final lowered = _stripDiacritics(text.toLowerCase());
    final parts = lowered.split(RegExp(r'[^a-z0-9%]+'));
    return {
      for (final part in parts)
        if (part.length > 1 && !_stopWords.contains(part)) _singularize(part),
    };
  }

  /// Collapses regular English plurals so a query and a table entry meet.
  ///
  /// Without this, "pear" does not match "Pears, raw" at all, and the query is
  /// instead won by "Balsam-pear (bitter gourd)" — which contains the literal
  /// token and is a completely different food. Same for "orange" landing on
  /// "Tomatoes, orange, raw" instead of "Oranges, raw".
  ///
  /// Deliberately conservative: only regular endings, and never shortening a
  /// word below three characters, since an over-eager stemmer creates collisions
  /// that are harder to debug than the plurals it fixed.
  static String _singularize(String token) {
    if (token.length <= 3) return token;
    if (token.endsWith('ies')) {
      return '${token.substring(0, token.length - 3)}y';
    }
    for (final ending in const ['sses', 'shes', 'ches', 'xes', 'zes', 'oes']) {
      if (token.endsWith(ending)) {
        return token.substring(0, token.length - 2);
      }
    }
    if (token.endsWith('ss') || token.endsWith('us') || token.endsWith('is')) {
      return token;
    }
    if (token.endsWith('s')) return token.substring(0, token.length - 1);
    return token;
  }

  /// The preparation state [text] states, or null when it says nothing.
  static FoodPreparation? statedPreparation(String text) {
    for (final token in tokenize(text)) {
      final preparation = _preparationWords[token];
      if (preparation != null) return preparation;
    }
    return null;
  }

  /// Best matches for [query], highest score first.
  ///
  /// [preparation] overrides whatever the query text implies, for callers that
  /// already parsed it out of the plan. [limit] caps the returned list.
  List<FoodMatch> search(
    String query, {
    FoodPreparation? preparation,
    int limit = 5,
    double minimumScore = defaultMinimumScore,
  }) {
    final queryTokens = tokenize(query);
    if (queryTokens.isEmpty) return const [];

    final wantedPreparation = preparation ?? statedPreparation(query);

    var queryWeight = 0.0;
    for (final token in queryTokens) {
      queryWeight += _idf[token] ?? _unknownTokenIdf;
    }
    if (queryWeight == 0) return const [];

    // Only foods sharing at least one token can score, so the whole catalog is
    // never walked per query.
    final candidateIds = <String>{};
    for (final token in queryTokens) {
      final posting = _postings[token];
      if (posting != null) candidateIds.addAll(posting);
    }

    final matches = <FoodMatch>[];
    for (final id in candidateIds) {
      final food = _catalog.byId(id);
      if (food == null) continue;
      final nameTokens = _nameTokens[id]!;

      var overlapWeight = 0.0;
      var nameWeight = 0.0;
      for (final token in nameTokens) {
        final weight = _idf[token] ?? _unknownTokenIdf;
        nameWeight += weight;
        if (queryTokens.contains(token)) overlapWeight += weight;
      }
      if (overlapWeight == 0) continue;

      final recall = overlapWeight / queryWeight;
      final precision = nameWeight == 0 ? 0.0 : overlapWeight / nameWeight;

      // F-beta with beta=3: covering the query dominates, and terseness only
      // breaks ties. Weighting precision higher was actively harmful — USDA
      // describes generic foods verbosely ("Chicken, broiler or fryers, breast,
      // skinless, boneless, meat only, cooked, grilled"), so penalising extra
      // tokens handed the win to short processed entries like "Chicken breast,
      // roll, oven-roasted", a cold cut rather than a grilled breast.
      const betaSq = 9.0;
      final denominator = betaSq * precision + recall;
      var score = denominator == 0
          ? 0.0
          : (1 + betaSq) * precision * recall / denominator;

      if (wantedPreparation != null) {
        if (food.preparation == wantedPreparation) {
          score *= 1.18;
        } else if (_contradicts(wantedPreparation, food.preparation)) {
          // A raw/cooked mix-up is a multiple-hundred-percent macro error, so it
          // must lose to a weaker but correctly-prepared candidate.
          score *= 0.55;
        } else {
          // Same family, different method (grilled asked, roasted found).
          // Compositionally close, so only a nudge — but a real one, or an entry
          // that merely happens to be cooked ties with the exact match.
          score *= 0.92;
        }
      }

      if (food.branded) score *= 0.85;
      // Curated ids were checked by hand, so they win an otherwise even race.
      if (!id.startsWith('usda_')) score *= 1.10;

      if (score >= minimumScore) {
        matches.add(FoodMatch(food: food, score: score.clamp(0.0, 1.0)));
      }
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      // Ties resolve by id so results are deterministic across runs.
      return byScore != 0 ? byScore : a.food.id.compareTo(b.food.id);
    });
    return matches.length <= limit ? matches : matches.sublist(0, limit);
  }

  /// The single best match, or null when nothing clears [minimumScore].
  FoodMatch? bestMatch(
    String query, {
    FoodPreparation? preparation,
    double minimumScore = defaultMinimumScore,
  }) {
    final results = search(
      query,
      preparation: preparation,
      limit: 1,
      minimumScore: minimumScore,
    );
    return results.isEmpty ? null : results.first;
  }

  /// Whether two preparation states are mutually exclusive.
  ///
  /// `cooked` is treated as compatible with every specific cooking method: a
  /// plan saying "cooked" should not be pushed away from a grilled entry.
  static bool _contradicts(FoodPreparation wanted, FoodPreparation actual) {
    if (wanted == actual) return false;
    const cookedFamily = {
      FoodPreparation.cooked,
      FoodPreparation.boiled,
      FoodPreparation.baked,
      FoodPreparation.grilled,
      FoodPreparation.roasted,
    };
    if (cookedFamily.contains(wanted) && cookedFamily.contains(actual)) {
      // Both are cooked forms: different methods, similar composition.
      return false;
    }
    // raw vs anything cooked, or cured/canned vs raw, are real contradictions.
    return true;
  }

  /// IDF for a token absent from the catalog: treated as maximally rare, since
  /// nothing to compare it against means it carries no shared evidence.
  static const double _unknownTokenIdf = 3.0;

  static String _stripDiacritics(String input) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      final index = from.indexOf(char);
      buffer.write(index == -1 ? char : to[index]);
    }
    return buffer.toString();
  }
}
