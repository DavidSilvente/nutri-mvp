import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/nutrition_health_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/record_nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

import '../../_fakes/fake_nutrition_source.dart';

/// A local test double that always fails, used ONLY to verify that
/// [RecordNutritionEntry] propagates the port's [Err] unchanged instead of
/// swallowing it. [FakeNutritionSource] is intentionally NOT used for this
/// scenario since it always succeeds.
class _AlwaysFailingSource implements NutritionHealthSource {
  @override
  Future<Result<void, NutritionFailure>> record(NutritionEntry entry) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<List<NutritionEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  ) async {
    return const Ok([]);
  }

  @override
  Future<Result<List<NutritionEntry>, NutritionFailure>> entriesBetween(
    NutritionDay from,
    NutritionDay to,
  ) async {
    return const Ok([]);
  }
}

NutritionEntry buildEntry({required String id, required DateTime recordedAt}) {
  return NutritionEntry(
    id: id,
    recordedAt: recordedAt,
    energy: Energy(kcal: 500),
    macros: Macros(proteinG: 30, carbsG: 40, fatG: 15),
  );
}

void main() {
  group('RecordNutritionEntry', () {
    test(
      'records an entry and it is reflected in a subsequent query',
      () async {
        final fake = FakeNutritionSource();
        final useCase = RecordNutritionEntry(fake);
        final entry = buildEntry(id: 'a', recordedAt: DateTime(2026, 7, 24, 9));

        final result = await useCase(entry);

        expect(result, isA<Ok<void, NutritionFailure>>());
        final queried = await fake.entriesOn(
          NutritionDay.fromDateTime(entry.recordedAt),
        );
        final entries =
            (queried as Ok<List<NutritionEntry>, NutritionFailure>).value;
        expect(entries, [entry]);
      },
    );

    test('propagates the failure returned by the source, unchanged', () async {
      final useCase = RecordNutritionEntry(_AlwaysFailingSource());
      final entry = buildEntry(id: 'b', recordedAt: DateTime(2026, 7, 24));

      final result = await useCase(entry);

      expect(
        result,
        const Err<void, NutritionFailure>(StorageFailure('disk full')),
      );
    });
  });
}
