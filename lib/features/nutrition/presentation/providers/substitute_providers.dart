import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/alternative_ranker.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/substitution_engine.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/data_revision_provider.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';

/// Identifies which meal to suggest alternatives for, and what target they
/// are ranked against.
///
/// The target travels with the id because ranking is done against the meal's
/// FROZEN snapshot, not against whatever its template slot says today.
typedef SubstituteQuery = ({String plannedMealId, NutritionTarget target});

/// The alternatives available for a planned meal, ranked by how closely their
/// macros match the meal they would replace, grouped by where they came
/// from: the diet plan's own substitutes first, the user's saved-meal
/// catalogue second.
///
/// This is the "I don't fancy that today" path: the closest option in each
/// group first, so swapping costs the plan as little as possible. Reads both
/// sources directly (rather than through a separate `FutureProvider` per
/// source) so grouping and off-target labelling — done by [AlternativeRanker]
/// — happen in one place with one loading/error state for the sheet.
final rankedSubstitutesProvider =
    FutureProvider.family<List<AlternativeGroup>, SubstituteQuery>((
      ref,
      query,
    ) async {
      ref.watch(dataRevisionProvider);

      final substitutesResult = await ref
          .watch(dietPlanSourceProvider)
          .listSubstitutes(query.plannedMealId);
      final substitutes = switch (substitutesResult) {
        Ok(value: final value) => value,
        Err(failure: final failure) => throw HealthFailureException(failure),
      };

      final savedResult = await ref
          .watch(savedMealSourceProvider)
          .listSavedMeals();
      final saved = switch (savedResult) {
        Ok(value: final value) => value,
        Err(failure: final failure) => throw HealthFailureException(failure),
      };

      const ranker = AlternativeRanker();
      return ranker.rank(
        target: query.target,
        planCandidates: substitutes
            .map(
              (s) => MacroCandidate(id: s.id, label: s.label, target: s.target),
            )
            .toList(growable: false),
        // Namespaced so a saved meal can never collide with a plan
        // substitute's id across the two groups.
        savedCandidates: saved
            .map(
              (m) => MacroCandidate(
                id: 'saved:${m.id}',
                label: m.name,
                target: m.target,
              ),
            )
            .toList(growable: false),
      );
    });
