import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/hydration_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/hydration_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';

import '../../_fakes/fake_hydration_source.dart';

/// A local test double that always fails, used ONLY to verify that
/// [HydrationController] surfaces the port's [Err] as an [AsyncError]
/// instead of swallowing it. [FakeHydrationSource] is intentionally NOT
/// used for this scenario since it always succeeds.
class _AlwaysFailingSource implements HydrationSource {
  @override
  Future<Result<void, NutritionFailure>> record(HydrationEntry entry) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<List<HydrationEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  ) async {
    return const Err(StorageFailure('disk full'));
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
  group('HydrationController', () {
    test('builds with today\'s entries from the source (empty)', () async {
      final container = ProviderContainer(
        overrides: [
          hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(hydrationControllerProvider.future);

      expect(initial, isEmpty);
    });

    test('recording an entry is reflected in the async state', () async {
      final container = ProviderContainer(
        overrides: [
          hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(hydrationControllerProvider.future);

      final entry = buildEntry(id: 'a', recordedAt: DateTime.now());
      await container.read(hydrationControllerProvider.notifier).record(entry);

      final state = container.read(hydrationControllerProvider);
      expect(state, isA<AsyncData<List<HydrationEntry>>>());
      expect(state.value, contains(entry));
    });

    test('a failure while recording surfaces as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          hydrationSourceProvider.overrideWithValue(_AlwaysFailingSource()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(hydrationControllerProvider.future),
        throwsA(isA<HealthFailureException>()),
      );

      final entry = buildEntry(id: 'b', recordedAt: DateTime.now());
      await container.read(hydrationControllerProvider.notifier).record(entry);

      final state = container.read(hydrationControllerProvider);
      expect(state, isA<AsyncError<List<HydrationEntry>>>());
      expect(state.error, isA<HealthFailureException>());
    });
  });
}
