import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_daily_nutrition.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

import '../../_fakes/fake_nutrition_source.dart';

NutritionEntry buildEntry({required String id, required DateTime recordedAt}) {
  return NutritionEntry(
    id: id,
    recordedAt: recordedAt,
    energy: Energy(kcal: 500),
    macros: Macros(proteinG: 30, carbsG: 40, fatG: 15),
  );
}

void main() {
  group('GetDailyNutrition', () {
    test('returns entries for the day in recording order [A, B]', () async {
      final fake = FakeNutritionSource();
      final useCase = GetDailyNutrition(fake);
      final entryA = buildEntry(id: 'A', recordedAt: DateTime(2026, 7, 24, 8));
      final entryB = buildEntry(id: 'B', recordedAt: DateTime(2026, 7, 24, 13));
      await fake.record(entryA);
      await fake.record(entryB);

      final result = await useCase(
        NutritionDay.fromDateTime(entryA.recordedAt),
      );

      final entries =
          (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, [entryA, entryB]);
    });

    test('returns an empty list for a day with no entries', () async {
      final fake = FakeNutritionSource();
      final useCase = GetDailyNutrition(fake);

      final result = await useCase(
        NutritionDay.fromDateTime(DateTime(2026, 1, 1)),
      );

      final entries =
          (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, isEmpty);
    });
  });
}
