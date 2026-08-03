import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/alternative_ranker.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/substitution_engine.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('AlternativeRanker', () {
    const ranker = AlternativeRanker();

    final target = NutritionTarget(
      energy: Energy(kcal: 700),
      macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
    );

    MacroCandidate candidate(String id, num p, num c, num f) => MacroCandidate(
      id: id,
      label: 'Candidate $id',
      target: NutritionTarget(
        energy: Energy(kcal: 0),
        macros: Macros(proteinG: p, carbsG: c, fatG: f),
      ),
    );

    test(
      'GUARD: plan-only input reproduces SubstitutionEngine.rank exactly',
      () {
        final planCandidates = [
          candidate('far', 20, 110, 45),
          candidate('near', 42, 58, 21),
        ];

        final groups = ranker.rank(
          target: target,
          planCandidates: planCandidates,
          savedCandidates: const [],
        );

        final directRank = SubstitutionEngine.rank(target, planCandidates);

        expect(groups, hasLength(1));
        expect(groups.single.origin, AlternativeOrigin.plan);
        expect(
          groups.single.options.map((o) => o.ranked).toList(),
          directRank,
        );
        expect(
          groups.single.options.map((o) => o.ranked.id).toList(),
          directRank.map((r) => r.id).toList(),
        );
      },
    );

    test('group order is fixed: plan first, saved second', () {
      final groups = ranker.rank(
        target: target,
        planCandidates: [candidate('p1', 40, 60, 20)],
        savedCandidates: [candidate('s1', 40, 60, 20)],
      );

      expect(groups.map((g) => g.origin).toList(), [
        AlternativeOrigin.plan,
        AlternativeOrigin.savedMeal,
      ]);
    });

    test('an empty saved-meal list omits the saved group entirely', () {
      final groups = ranker.rank(
        target: target,
        planCandidates: [candidate('p1', 40, 60, 20)],
        savedCandidates: const [],
      );

      expect(groups, hasLength(1));
      expect(groups.single.origin, AlternativeOrigin.plan);
    });

    test('an empty plan list omits the plan group entirely', () {
      final groups = ranker.rank(
        target: target,
        planCandidates: const [],
        savedCandidates: [candidate('s1', 40, 60, 20)],
      );

      expect(groups, hasLength(1));
      expect(groups.single.origin, AlternativeOrigin.savedMeal);
    });

    test('both empty yields no groups at all', () {
      final groups = ranker.rank(
        target: target,
        planCandidates: const [],
        savedCandidates: const [],
      );

      expect(groups, isEmpty);
    });

    test('each group preserves the engine ranking order independently', () {
      final groups = ranker.rank(
        target: target,
        planCandidates: [
          candidate('plan-far', 20, 110, 45),
          candidate('plan-near', 42, 58, 21),
        ],
        savedCandidates: [
          candidate('saved-far', 90, 5, 60),
          candidate('saved-near', 41, 59, 20),
        ],
      );

      final plan = groups.firstWhere((g) => g.origin == AlternativeOrigin.plan);
      final saved = groups.firstWhere(
        (g) => g.origin == AlternativeOrigin.savedMeal,
      );

      expect(plan.options.map((o) => o.ranked.id).toList(), [
        'plan-near',
        'plan-far',
      ]);
      expect(saved.options.map((o) => o.ranked.id).toList(), [
        'saved-near',
        'saved-far',
      ]);
    });

    test('off-target flag matches SwapTolerance.standard', () {
      final groups = ranker.rank(
        target: target,
        // Protein +11 g breaches the 10%/3g protein tolerance (10% of 40 is
        // 4 g); carbs/fat are unchanged.
        planCandidates: [candidate('over-protein', 51, 60, 20)],
        savedCandidates: const [],
      );

      final option = groups.single.options.single;
      expect(option.deviation.isOffTarget, isTrue);
      expect(option.deviation.proteinG, 11);
    });

    test('a candidate within tolerance is not labelled off target', () {
      final groups = ranker.rank(
        target: target,
        planCandidates: [candidate('close', 41, 59, 21)],
        savedCandidates: const [],
      );

      final option = groups.single.options.single;
      expect(option.deviation.isOffTarget, isFalse);
    });

    test('every option in a group carries its group origin', () {
      final groups = ranker.rank(
        target: target,
        planCandidates: [candidate('p1', 40, 60, 20)],
        savedCandidates: [candidate('s1', 40, 60, 20)],
      );

      for (final group in groups) {
        for (final option in group.options) {
          expect(option.origin, group.origin);
        }
      }
    });
  });
}
