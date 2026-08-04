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

NutritionEntry buildEntry({
  required String id,
  required DateTime recordedAt,
  String? plannedMealId,
}) {
  return NutritionEntry(
    id: id,
    recordedAt: recordedAt,
    energy: Energy(kcal: 500),
    macros: Macros(proteinG: 30, carbsG: 40, fatG: 15),
    plannedMealId: plannedMealId,
  );
}

List<NutritionEntry> unwrap(
  Result<List<NutritionEntry>, NutritionFailure> result,
) {
  return (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
}

void main() {
  group('SqlNutritionSource.entriesBetween', () {
    late NutritionDatabase database;
    late SqlNutritionSource source;

    setUp(() {
      database = NutritionDatabase(NativeDatabase.memory());
      source = SqlNutritionSource(database);
    });

    tearDown(() async {
      await database.close();
    });

    NutritionDay day(int d) =>
        NutritionDay.fromDateTime(DateTime(2026, 7, d));

    test('returns entries within the range, both bounds inclusive', () async {
      await source.record(buildEntry(id: 'a', recordedAt: DateTime(2026, 7, 9)));
      await source.record(
        buildEntry(id: 'b', recordedAt: DateTime(2026, 7, 10, 8)),
      );
      await source.record(
        buildEntry(id: 'c', recordedAt: DateTime(2026, 7, 15, 20)),
      );
      await source.record(
        buildEntry(id: 'd', recordedAt: DateTime(2026, 7, 16)),
      );

      final result = await source.entriesBetween(day(10), day(15));

      expect(unwrap(result).map((e) => e.id), ['b', 'c']);
    });

    test('returns a single day when both bounds are the same', () async {
      await source.record(
        buildEntry(id: 'a', recordedAt: DateTime(2026, 7, 12, 7)),
      );
      await source.record(
        buildEntry(id: 'b', recordedAt: DateTime(2026, 7, 13)),
      );

      final result = await source.entriesBetween(day(12), day(12));

      expect(unwrap(result).map((e) => e.id), ['a']);
    });

    test('orders results by recording time', () async {
      await source.record(
        buildEntry(id: 'late', recordedAt: DateTime(2026, 7, 12, 21)),
      );
      await source.record(
        buildEntry(id: 'early', recordedAt: DateTime(2026, 7, 11, 6)),
      );

      final result = await source.entriesBetween(day(10), day(15));

      expect(unwrap(result).map((e) => e.id), ['early', 'late']);
    });

    test('yields an empty list for an inverted range, not an error', () async {
      await source.record(
        buildEntry(id: 'a', recordedAt: DateTime(2026, 7, 12)),
      );

      final result = await source.entriesBetween(day(15), day(10));

      expect(result, isA<Ok<List<NutritionEntry>, NutritionFailure>>());
      expect(unwrap(result), isEmpty);
    });

    test('yields an empty list when nothing falls in the range', () async {
      final result = await source.entriesBetween(day(1), day(5));

      expect(unwrap(result), isEmpty);
    });

    test('round-trips the planned meal link', () async {
      // `nutrition_entries.planned_meal_id` is a real FK, so the meal has to
      // exist. It no longer hangs off a slot table, though: a planned meal names
      // its slot without being keyed to one, so this is the whole chain.
      await database.customStatement('''
        INSERT INTO planned_meals
          (id, slot_id, day_epoch, energy_kcal, protein_g, carbs_g, fat_g)
        VALUES ('pm1', 's1', 20645, 500.0, 30.0, 40.0, 15.0);
      ''');

      await source.record(
        buildEntry(
          id: 'linked',
          recordedAt: DateTime(2026, 7, 12, 13),
          plannedMealId: 'pm1',
        ),
      );
      await source.record(
        buildEntry(id: 'loose', recordedAt: DateTime(2026, 7, 12, 19)),
      );

      final entries = unwrap(await source.entriesBetween(day(12), day(12)));

      expect(entries.firstWhere((e) => e.id == 'linked').plannedMealId, 'pm1');
      expect(entries.firstWhere((e) => e.id == 'loose').plannedMealId, isNull);
    });
  });
}
