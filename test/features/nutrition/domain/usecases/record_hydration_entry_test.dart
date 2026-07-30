import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/hydration_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/record_hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';

import '../../_fakes/fake_hydration_source.dart';

/// A local test double that always fails, used ONLY to verify that
/// [RecordHydrationEntry] propagates the port's [Err] unchanged instead of
/// swallowing it. [FakeHydrationSource] is intentionally NOT used for this
/// scenario since it always succeeds.
class _AlwaysFailingSource implements HydrationSource {
  @override
  Future<Result<void, NutritionFailure>> record(HydrationEntry entry) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<List<HydrationEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  ) async {
    return const Ok([]);
  }
}

HydrationEntry buildEntry({required String id, required DateTime recordedAt}) {
  return HydrationEntry(
    id: id,
    recordedAt: recordedAt,
    volume: WaterVolume(ml: 250),
  );
}

void main() {
  group('RecordHydrationEntry', () {
    test(
      'records an entry and it is reflected in a subsequent query',
      () async {
        final fake = FakeHydrationSource();
        final useCase = RecordHydrationEntry(fake);
        final entry = buildEntry(id: 'a', recordedAt: DateTime(2026, 7, 24, 9));

        final result = await useCase(entry);

        expect(result, isA<Ok<void, NutritionFailure>>());
        final queried = await fake.entriesOn(
          NutritionDay.fromDateTime(entry.recordedAt),
        );
        final entries =
            (queried as Ok<List<HydrationEntry>, NutritionFailure>).value;
        expect(entries, [entry]);
      },
    );

    test('propagates the failure returned by the source, unchanged', () async {
      final useCase = RecordHydrationEntry(_AlwaysFailingSource());
      final entry = buildEntry(id: 'b', recordedAt: DateTime(2026, 7, 24));

      final result = await useCase(entry);

      expect(
        result,
        const Err<void, NutritionFailure>(StorageFailure('disk full')),
      );
    });
  });
}
