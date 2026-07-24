import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';

void main() {
  group('NutritionEntry', () {
    test('builds successfully with valid value objects', () {
      final entry = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24, 8, 30),
        energy: Energy(kcal: 500),
        macros: Macros(proteinG: 30, carbsG: 50, fatG: 15),
        water: WaterVolume(ml: 250),
      );

      expect(entry.id, 'entry-1');
      expect(entry.recordedAt, DateTime(2026, 7, 24, 8, 30));
      expect(entry.energy, Energy(kcal: 500));
      expect(entry.macros, Macros(proteinG: 30, carbsG: 50, fatG: 15));
      expect(entry.water, WaterVolume(ml: 250));
    });

    test(
      'rejects negative energy by delegating to the Energy value object',
      () {
        expect(
          () => NutritionEntry(
            id: 'entry-1',
            recordedAt: DateTime(2026, 7, 24),
            energy: Energy(kcal: -1),
            macros: Macros(proteinG: 0, carbsG: 0, fatG: 0),
            water: WaterVolume(ml: 0),
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'rejects negative macros by delegating to the Macros value object',
      () {
        expect(
          () => NutritionEntry(
            id: 'entry-1',
            recordedAt: DateTime(2026, 7, 24),
            energy: Energy(kcal: 0),
            macros: Macros(proteinG: -5, carbsG: 0, fatG: 0),
            water: WaterVolume(ml: 0),
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'rejects negative water by delegating to the WaterVolume value object',
      () {
        expect(
          () => NutritionEntry(
            id: 'entry-1',
            recordedAt: DateTime(2026, 7, 24),
            energy: Energy(kcal: 0),
            macros: Macros(proteinG: 0, carbsG: 0, fatG: 0),
            water: WaterVolume(ml: -10),
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('two entries with the same fields are equal', () {
      final a = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24),
        energy: Energy(kcal: 100),
        macros: Macros(proteinG: 10, carbsG: 10, fatG: 10),
        water: WaterVolume(ml: 100),
      );
      final b = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24),
        energy: Energy(kcal: 100),
        macros: Macros(proteinG: 10, carbsG: 10, fatG: 10),
        water: WaterVolume(ml: 100),
      );

      expect(a, b);
    });
  });
}
