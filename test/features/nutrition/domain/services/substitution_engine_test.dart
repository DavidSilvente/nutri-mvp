import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/substitution_engine.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('SubstitutionEngine', () {
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

    test('ranks closer macro-distance options first', () {
      final options = [
        candidate('A', 42, 58, 22),
        candidate('B', 30, 80, 10),
      ];

      final ranked = SubstitutionEngine.rank(target, options);

      expect(ranked.map((r) => r.id).toList(), ['A', 'B']);
    });

    test('breaks ties by protein proximity to the target', () {
      final options = [
        candidate('C', 44, 58, 20),
        candidate('D', 40, 64, 18),
      ];

      final ranked = SubstitutionEngine.rank(target, options);

      expect(ranked.map((r) => r.id).toList(), ['D', 'C']);
      expect(ranked.first.proteinDelta, 0);
      expect(ranked[1].proteinDelta, 4);
    });

    test('returns an empty list when there are no candidates', () {
      final ranked = SubstitutionEngine.rank(target, []);

      expect(ranked, isEmpty);
    });

    test('exposes distance and proteinDelta on each ranked option', () {
      final option = candidate('A', 42, 58, 22);

      final ranked = SubstitutionEngine.rank(target, [option]);

      expect(ranked, hasLength(1));
      expect(ranked.first.id, 'A');
      expect(ranked.first.distance, closeTo(3.464, 0.001));
      expect(ranked.first.proteinDelta, 2);
    });

    test('ranks 10 candidates in under 100ms', () {
      final options = [
        candidate('1', 40, 60, 20),
        candidate('2', 41, 59, 21),
        candidate('3', 39, 61, 19),
        candidate('4', 42, 58, 22),
        candidate('5', 38, 62, 18),
        candidate('6', 43, 57, 23),
        candidate('7', 37, 63, 17),
        candidate('8', 44, 56, 24),
        candidate('9', 36, 64, 16),
        candidate('10', 45, 55, 25),
      ];

      final stopwatch = Stopwatch()..start();
      final ranked = SubstitutionEngine.rank(target, options);
      stopwatch.stop();

      expect(ranked, hasLength(10));
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
