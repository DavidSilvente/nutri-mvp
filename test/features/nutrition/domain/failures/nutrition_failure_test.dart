import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';

void main() {
  group('NutritionFailure', () {
    test('ConflictFailure carries a reason', () {
      const failure = ConflictFailure('Duplicate template name');

      expect(failure.reason, 'Duplicate template name');
    });

    test('two ConflictFailures with the same reason are equal', () {
      const a = ConflictFailure('Duplicate template name');
      const b = ConflictFailure('Duplicate template name');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('ConflictFailures with different reasons are not equal', () {
      const a = ConflictFailure('Duplicate template name');
      const b = ConflictFailure('Slot already planned for this day');

      expect(a, isNot(b));
    });
  });
}
