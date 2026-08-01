import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/substitution_engine.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/data_revision_provider.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Identifies which meal to suggest alternatives for, and what target they
/// are ranked against.
///
/// The target travels with the id because ranking is done against the meal's
/// FROZEN snapshot, not against whatever its template slot says today.
typedef SubstituteQuery = ({String plannedMealId, NutritionTarget target});

/// The alternatives defined for a planned meal, ranked by how closely their
/// macros match the meal they would replace.
///
/// This is the "I don't fancy that today" path: the closest option first, so
/// swapping costs the plan as little as possible.
final rankedSubstitutesProvider =
    FutureProvider.family<List<RankedOption>, SubstituteQuery>((
      ref,
      query,
    ) async {
      ref.watch(dataRevisionProvider);

      final result = await ref
          .watch(dietPlanSourceProvider)
          .listSubstitutes(query.plannedMealId);

      return switch (result) {
        Ok(value: final substitutes) => SubstitutionEngine.rank(
          query.target,
          substitutes
              .map(
                (s) => MacroCandidate(
                  id: s.id,
                  label: s.label,
                  target: s.target,
                ),
              )
              .toList(growable: false),
        ),
        Err(failure: final failure) => throw HealthFailureException(failure),
      };
    });
