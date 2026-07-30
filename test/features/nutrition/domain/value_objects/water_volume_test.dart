import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';

void main() {
  group('WaterVolume', () {
    test('accepts a non-negative ml value', () {
      final water = WaterVolume(ml: 250);

      expect(water.ml, 250);
    });

    test('accepts zero ml', () {
      final water = WaterVolume(ml: 0);

      expect(water.ml, 0);
    });

    test('rejects a negative ml value', () {
      expect(() => WaterVolume(ml: -1), throwsA(isA<ArgumentError>()));
    });

    test('two instances with the same ml are equal', () {
      expect(WaterVolume(ml: 500), WaterVolume(ml: 500));
    });
  });
}
