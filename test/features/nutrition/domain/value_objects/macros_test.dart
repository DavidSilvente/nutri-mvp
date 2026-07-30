import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';

void main() {
  group('Macros', () {
    test('accepts non-negative protein, carbs and fat in grams', () {
      final macros = Macros(proteinG: 20, carbsG: 30, fatG: 10);

      expect(macros.proteinG, 20);
      expect(macros.carbsG, 30);
      expect(macros.fatG, 10);
    });

    test('rejects a negative protein value', () {
      expect(
        () => Macros(proteinG: -1, carbsG: 0, fatG: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a negative carbs value', () {
      expect(
        () => Macros(proteinG: 0, carbsG: -1, fatG: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a negative fat value', () {
      expect(
        () => Macros(proteinG: 0, carbsG: 0, fatG: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('two instances with the same values are equal', () {
      expect(
        Macros(proteinG: 1, carbsG: 2, fatG: 3),
        Macros(proteinG: 1, carbsG: 2, fatG: 3),
      );
    });
  });
}
