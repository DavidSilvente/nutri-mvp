import 'dart:convert';

/// Turns a stored plan document into the DRAFT an extraction would have
/// produced: every food id replaced by a draft-local ref, described in an
/// `extractedFoods` section.
///
/// Built from the real shipped plan rather than hand-written, so the codec is
/// exercised against the shape and size of an actual 5-meal, 4-day-group plan
/// instead of a toy fixture that happens to fit the implementation.
///
/// Recipe ids are left alone: a plan that prints its own nutrition table has
/// already placed those foods, so they never need review.
String draftFromDocument(String document) {
  final root = jsonDecode(document) as Map<String, dynamic>;
  final diet = root['diet'] as Map<String, dynamic>;

  final recipeIds = <String>{
    for (final recipe in (diet['recipes'] as List? ?? const []))
      (recipe as Map)['id'] as String,
  };

  final refByFoodId = <String, String>{};
  final extractedFoods = <Map<String, Object?>>[];

  for (final group in diet['dayGroups'] as List) {
    for (final meal in (group as Map)['meals'] as List) {
      for (final section in (meal as Map)['sections'] as List) {
        for (final component in (section as Map)['components'] as List) {
          for (final alternative in (component as Map)['alternatives'] as List) {
            final option = alternative as Map<String, dynamic>;
            final foodId = option['foodRef'] as String;
            if (recipeIds.contains(foodId)) continue;

            var ref = refByFoodId[foodId];
            if (ref == null) {
              ref = 'x${refByFoodId.length + 1}';
              refByFoodId[foodId] = ref;
              final quantity = option['quantity'] as Map<String, dynamic>;
              extractedFoods.add({
                'ref': ref,
                'rawText': option['rawText'],
                // The id doubles as a plausible canonical name once its
                // separators are dropped, which is enough for the matcher.
                'canonicalName': foodId.replaceAll('_', ' '),
                'preparation': 'raw',
                'grams': quantity['grams'],
                'count': quantity['count'],
                'unit': quantity['unit'],
                'brandNormalizedFrom': null,
              });
            }
            option['foodRef'] = ref;
          }
        }
      }
    }
  }

  diet['extractedFoods'] = extractedFoods;
  return jsonEncode(root);
}

/// The food ids [draftFromDocument] turned into refs, in ref order — the ids a
/// perfect review would settle on.
List<String> originalFoodIds(String document) {
  final root = jsonDecode(document) as Map<String, dynamic>;
  final diet = root['diet'] as Map<String, dynamic>;
  final recipeIds = <String>{
    for (final recipe in (diet['recipes'] as List? ?? const []))
      (recipe as Map)['id'] as String,
  };

  final ordered = <String>[];
  for (final group in diet['dayGroups'] as List) {
    for (final meal in (group as Map)['meals'] as List) {
      for (final section in (meal as Map)['sections'] as List) {
        for (final component in (section as Map)['components'] as List) {
          for (final alternative in (component as Map)['alternatives'] as List) {
            final foodId = (alternative as Map)['foodRef'] as String;
            if (recipeIds.contains(foodId)) continue;
            if (!ordered.contains(foodId)) ordered.add(foodId);
          }
        }
      }
    }
  }
  return ordered;
}
