import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_daily_hydration.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';

import '../../_fakes/fake_hydration_source.dart';

HydrationEntry buildEntry({required String id, required DateTime recordedAt}) {
  return HydrationEntry(
    id: id,
    recordedAt: recordedAt,
    volume: WaterVolume(ml: 250),
  );
}

void main() {
  group('GetDailyHydration', () {
    test('returns entries for the day in recording order [A, B]', () async {
      final fake = FakeHydrationSource();
      final useCase = GetDailyHydration(fake);
      final entryA = buildEntry(id: 'A', recordedAt: DateTime(2026, 7, 24, 8));
      final entryB = buildEntry(id: 'B', recordedAt: DateTime(2026, 7, 24, 13));
      await fake.record(entryA);
      await fake.record(entryB);

      final result = await useCase(
        NutritionDay.fromDateTime(entryA.recordedAt),
      );

      final entries =
          (result as Ok<List<HydrationEntry>, NutritionFailure>).value;
      expect(entries, [entryA, entryB]);
    });

    test('returns an empty list for a day with no entries', () async {
      final fake = FakeHydrationSource();
      final useCase = GetDailyHydration(fake);

      final result = await useCase(
        NutritionDay.fromDateTime(DateTime(2026, 1, 1)),
      );

      final entries =
          (result as Ok<List<HydrationEntry>, NutritionFailure>).value;
      expect(entries, isEmpty);
    });
  });
}
