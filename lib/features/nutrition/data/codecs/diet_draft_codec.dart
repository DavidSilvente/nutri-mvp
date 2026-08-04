import 'dart:convert';

import 'package:nutri_mvp/core/result.dart';

import '../../domain/failures/nutrition_failure.dart';
import '../../domain/ports/diet_pdf_importer.dart';
import 'diet_plan_codec.dart';
import 'json_reader.dart';

/// Reads and rewrites the DRAFT document an extraction produces.
///
/// A draft is the ordinary plan document plus an `extractedFoods` section: the
/// foods the model described but could not place, each under a draft-local ref
/// (`x1`, `x2`, ...) that the meals point at through their usual `foodRef`.
///
/// The indirection is what makes review possible. The model reports what the
/// page SAYS; matching against a published table happens locally; the user
/// settles whatever is doubtful; and only then does the ref become a real
/// catalog id. At no point does a macro figure come from the model.
///
/// A draft is never stored. [resolveRefs] turns it into a plain schemaVersion 1
/// document, which is what reaches the database.
class DietDraftCodec implements DietPlanDraftCodec {
  const DietDraftCodec();

  /// Section listing the foods still to be placed.
  static const String pendingFoodsKey = 'extractedFoods';

  @override
  Result<List<PendingFood>, NutritionFailure> readPendingFoods(String draft) {
    final decoded = _decode(draft);
    switch (decoded) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final root):
        try {
          final reader = JsonReader.object(root, 'draft');
          final version = _checkVersion(reader);
          if (version != null) return Err(version);
          final diet = reader.child('diet');
          if (!diet.has(pendingFoodsKey)) return const Ok([]);

          final foods = <PendingFood>[];
          final seen = <String>{};
          for (final entry in diet.objectList(pendingFoodsKey)) {
            final ref = entry.string('ref');
            if (!seen.add(ref)) {
              return Err(MalformedPlanFailure(
                'draft.diet.$pendingFoodsKey: duplicate ref "$ref"',
              ));
            }
            foods.add(PendingFood(
              ref: ref,
              extracted: ExtractedFood(
                rawText: entry.string('rawText'),
                canonicalName: entry.string('canonicalName'),
                preparation: entry.string('preparation'),
                grams: entry.number('grams'),
                count: entry.numberOrNull('count'),
                unit: entry.stringOrNull('unit'),
                brandNormalizedFrom: entry.stringOrNull('brandNormalizedFrom'),
              ),
            ));
          }
          return Ok(foods);
        } on JsonReadException catch (error) {
          return Err(MalformedPlanFailure(error.message));
        } on ArgumentError catch (error) {
          return Err(
            MalformedPlanFailure('invalid draft value: ${error.message}'),
          );
        }
    }
  }

  @override
  Result<String, NutritionFailure> resolveRefs(
    String draft,
    Map<String, SettledFood> settled,
  ) {
    final decoded = _decode(draft);
    final Map<Object?, Object?> root;
    switch (decoded) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        if (value is! Map) {
          return const Err(
            MalformedPlanFailure('draft: expected an object'),
          );
        }
        root = value;
    }

    try {
      final version = _checkVersion(JsonReader(root, 'draft'));
      if (version != null) return Err(version);
    } on JsonReadException catch (error) {
      return Err(MalformedPlanFailure(error.message));
    }

    final diet = root['diet'];
    if (diet is! Map) {
      return const Err(MalformedPlanFailure('draft.diet: expected an object'));
    }

    // Refs the draft declared, so a leftover mention can be told apart from a
    // recipe id or a catalog id the model reused.
    final declaredRefs = <String>{};
    final pending = diet[pendingFoodsKey];
    if (pending is List) {
      for (final entry in pending) {
        if (entry is Map && entry['ref'] is String) {
          declaredRefs.add(entry['ref']! as String);
        }
      }
    }

    final unsettled = <String>{};
    final groups = diet['dayGroups'];
    if (groups is! List) {
      return const Err(
        MalformedPlanFailure('draft.diet.dayGroups: expected a list'),
      );
    }

    for (final group in groups) {
      final meals = group is Map ? group['meals'] : null;
      if (meals is! List) {
        return const Err(
          MalformedPlanFailure('draft.diet.dayGroups[].meals: expected a list'),
        );
      }
      for (final meal in meals) {
        final sections = meal is Map ? meal['sections'] : null;
        if (sections is! List) {
          return const Err(MalformedPlanFailure(
            'draft.diet.dayGroups[].meals[].sections: expected a list',
          ));
        }
        for (final section in sections) {
          final components = section is Map ? section['components'] : null;
          if (components is! List) {
            return const Err(MalformedPlanFailure(
              'draft.diet...sections[].components: expected a list',
            ));
          }
          for (final component in components) {
            final alternatives =
                component is Map ? component['alternatives'] : null;
            if (alternatives is! List) {
              return const Err(MalformedPlanFailure(
                'draft.diet...components[].alternatives: expected a list',
              ));
            }
            for (final alternative in alternatives) {
              if (alternative is! Map) {
                return const Err(MalformedPlanFailure(
                  'draft.diet...alternatives[]: expected an object',
                ));
              }
              final ref = alternative['foodRef'];
              if (ref is! String) {
                return const Err(MalformedPlanFailure(
                  'draft.diet...alternatives[].foodRef: expected a string',
                ));
              }
              final chosen = settled[ref];
              if (chosen != null) {
                alternative['foodRef'] = chosen.foodId;
                // Only a quantity the user actually corrected is written over
                // the document's; an untouched line keeps whatever each mention
                // of it says.
                if (chosen.quantity case final quantity?) {
                  alternative['quantity'] = {
                    'grams': quantity.grams,
                    'count': quantity.count,
                    'unit': quantity.unit,
                  };
                }
              } else if (declaredRefs.contains(ref)) {
                // A draft ref nobody settled would become a dangling id in a
                // stored plan, so it fails here while the user can still fix it.
                unsettled.add(ref);
              }
            }
          }
        }
      }
    }

    if (unsettled.isNotEmpty) return Err(UnknownFoodFailure(unsettled));

    // The draft section has served its purpose; leaving it in would make the
    // stored document fail its own schema.
    diet.remove(pendingFoodsKey);

    try {
      return Ok(jsonEncode(root));
    } on JsonUnsupportedObjectError catch (error) {
      return Err(
        MalformedPlanFailure('draft could not be re-encoded: ${error.cause}'),
      );
    }
  }

  /// Rejects a draft written to a schema this build does not know.
  ///
  /// Returns the failure, or null when the version is fine. Checked rather than
  /// overwritten: a model claiming another schema may have changed the SHAPE
  /// too, and quietly relabelling it as schema 1 would hand the decoder a
  /// document it would then misread field by field.
  static NutritionFailure? _checkVersion(JsonReader root) {
    final version = root.integer('schemaVersion');
    if (version == DietPlanCodec.supportedSchemaVersion) return null;
    return MalformedPlanFailure(
      'unsupported draft schemaVersion $version, '
      'expected ${DietPlanCodec.supportedSchemaVersion}',
    );
  }

  static Result<Object?, NutritionFailure> _decode(String draft) {
    try {
      return Ok(jsonDecode(draft));
    } on FormatException catch (error) {
      return Err(
        MalformedPlanFailure('draft is not valid JSON: ${error.message}'),
      );
    }
  }
}
