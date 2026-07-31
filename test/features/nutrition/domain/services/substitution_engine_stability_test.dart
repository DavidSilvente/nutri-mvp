import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/substitution_engine.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('SubstitutionEngine stability', () {
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

    test('produces identical order across repeated identical calls', () {
      final options = [
        candidate('A', 42, 58, 22),
        candidate('B', 30, 80, 10),
        candidate('C', 44, 58, 20),
        candidate('D', 40, 64, 18),
      ];

      final first = SubstitutionEngine.rank(target, options);
      final second = SubstitutionEngine.rank(target, options);
      final third = SubstitutionEngine.rank(target, options);

      expect(first.map((r) => r.id).toList(),
          second.map((r) => r.id).toList());
      expect(second.map((r) => r.id).toList(),
          third.map((r) => r.id).toList());
    });

    test('keeps original input order when distance and protein tie', () {
      final options = [
        candidate('first', 41, 59, 21),
        candidate('second', 41, 59, 21),
      ];

      final ranked = SubstitutionEngine.rank(target, options);

      expect(ranked.map((r) => r.id).toList(), ['first', 'second']);
    });

    test('does not mutate the input candidate list', () {
      final options = [
        candidate('A', 42, 58, 22),
        candidate('B', 30, 80, 10),
        candidate('C', 44, 58, 20),
      ];
      final originalOrder = options.map((c) => c.id).toList();
      final originalFirstTarget = options.first.target;

      SubstitutionEngine.rank(target, options);

      expect(options.map((c) => c.id).toList(), originalOrder);
      expect(options.first.target, originalFirstTarget);
      expect(options, hasLength(3));
    });
  });
}
