import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';

void main() {
  group('Energy', () {
    test('accepts a non-negative kcal value', () {
      final energy = Energy(kcal: 500);

      expect(energy.kcal, 500);
    });

    test('accepts zero kcal', () {
      final energy = Energy(kcal: 0);

      expect(energy.kcal, 0);
    });

    test('rejects a negative kcal value', () {
      expect(() => Energy(kcal: -1), throwsA(isA<ArgumentError>()));
    });

    test('two instances with the same kcal are equal', () {
      expect(Energy(kcal: 250), Energy(kcal: 250));
    });
  });
}
