import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';

void main() {
  group('HydrationEntry', () {
    test('builds successfully with a valid WaterVolume', () {
      final entry = HydrationEntry(
        id: 'hydration-1',
        recordedAt: DateTime(2026, 7, 24, 8, 30),
        volume: WaterVolume(ml: 250),
      );

      expect(entry.id, 'hydration-1');
      expect(entry.recordedAt, DateTime(2026, 7, 24, 8, 30));
      expect(entry.volume, WaterVolume(ml: 250));
    });

    test('rejects a negative volume by delegating to the WaterVolume value '
        'object', () {
      expect(
        () => HydrationEntry(
          id: 'hydration-1',
          recordedAt: DateTime(2026, 7, 24),
          volume: WaterVolume(ml: -10),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('two entries with the same id, recordedAt and volume are equal', () {
      final a = HydrationEntry(
        id: 'hydration-1',
        recordedAt: DateTime(2026, 7, 24),
        volume: WaterVolume(ml: 100),
      );
      final b = HydrationEntry(
        id: 'hydration-1',
        recordedAt: DateTime(2026, 7, 24),
        volume: WaterVolume(ml: 100),
      );

      expect(a, b);
    });

    test('entries with different ids are not equal', () {
      final a = HydrationEntry(
        id: 'hydration-1',
        recordedAt: DateTime(2026, 7, 24),
        volume: WaterVolume(ml: 100),
      );
      final b = HydrationEntry(
        id: 'hydration-2',
        recordedAt: DateTime(2026, 7, 24),
        volume: WaterVolume(ml: 100),
      );

      expect(a == b, isFalse);
    });
  });
}
