import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_nutrition_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';

NutritionEntry buildEntry({required String id, required DateTime recordedAt}) {
  return NutritionEntry(
    id: id,
    recordedAt: recordedAt,
    energy: Energy(kcal: 500),
    macros: Macros(proteinG: 30, carbsG: 40, fatG: 15),
    water: WaterVolume(ml: 250),
  );
}

void main() {
  group('SqlNutritionSource', () {
    late NutritionDatabase database;
    late SqlNutritionSource source;

    setUp(() {
      database = NutritionDatabase(NativeDatabase.memory());
      source = SqlNutritionSource(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('round-trips: record then entriesOn returns it', () async {
      final entry = buildEntry(id: 'a', recordedAt: DateTime(2026, 7, 24, 9));

      final recordResult = await source.record(entry);
      final queryResult = await source.entriesOn(
        NutritionDay.fromDateTime(entry.recordedAt),
      );

      expect(recordResult, isA<Ok<void, NutritionFailure>>());
      final entries =
          (queryResult as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, [entry]);
    });

    test('entriesOn filters by day, excluding other days', () async {
      final day1 = buildEntry(id: 'day1', recordedAt: DateTime(2026, 7, 24));
      final day2 = buildEntry(id: 'day2', recordedAt: DateTime(2026, 7, 25));

      await source.record(day1);
      await source.record(day2);

      final result = await source.entriesOn(
        NutritionDay.fromDateTime(day1.recordedAt),
      );

      final entries =
          (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, [day1]);
    });

    test('entriesOn returns an empty list for a day with no entries', () async {
      final result = await source.entriesOn(
        NutritionDay.fromDateTime(DateTime(2026, 1, 1)),
      );

      final entries =
          (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, isEmpty);
    });

    test('data persists across separate SqlNutritionSource instances '
        'sharing the same database (simulates surviving a restart)', () async {
      final entry = buildEntry(
        id: 'restart',
        recordedAt: DateTime(2026, 7, 24, 10),
      );
      await source.record(entry);

      final reopenedSource = SqlNutritionSource(database);
      final result = await reopenedSource.entriesOn(
        NutritionDay.fromDateTime(entry.recordedAt),
      );

      final entries =
          (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, [entry]);
    });
  });
}
