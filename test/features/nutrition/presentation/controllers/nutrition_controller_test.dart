import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/nutrition_health_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/nutrition_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';

import '../../_fakes/fake_nutrition_source.dart';

/// A local test double that always fails, used ONLY to verify that
/// [NutritionController] surfaces the port's [Err] as an [AsyncError]
/// instead of swallowing it. [FakeNutritionSource] is intentionally NOT
/// used for this scenario since it always succeeds.
class _AlwaysFailingSource implements NutritionHealthSource {
  @override
  Future<Result<void, NutritionFailure>> record(NutritionEntry entry) async {
    return const Err(StorageFailure('disk full'));
  }

  @override
  Future<Result<List<NutritionEntry>, NutritionFailure>> entriesOn(
    NutritionDay day,
  ) async {
    return const Err(StorageFailure('disk full'));
  }
}

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
  group('NutritionController', () {
    test('builds with today\'s entries from the source (empty)', () async {
      final container = ProviderContainer(
        overrides: [
          nutritionSourceProvider.overrideWithValue(FakeNutritionSource()),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(nutritionControllerProvider.future);

      expect(initial, isEmpty);
    });

    test('recording an entry is reflected in the async state', () async {
      final container = ProviderContainer(
        overrides: [
          nutritionSourceProvider.overrideWithValue(FakeNutritionSource()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(nutritionControllerProvider.future);

      final entry = buildEntry(id: 'a', recordedAt: DateTime.now());
      await container.read(nutritionControllerProvider.notifier).record(entry);

      final state = container.read(nutritionControllerProvider);
      expect(state, isA<AsyncData<List<NutritionEntry>>>());
      expect(state.value, contains(entry));
    });

    test('a failure while recording surfaces as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          nutritionSourceProvider.overrideWithValue(_AlwaysFailingSource()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(nutritionControllerProvider.future),
        throwsA(isA<NutritionFailureException>()),
      );

      final entry = buildEntry(id: 'b', recordedAt: DateTime.now());
      await container.read(nutritionControllerProvider.notifier).record(entry);

      final state = container.read(nutritionControllerProvider);
      expect(state, isA<AsyncError<List<NutritionEntry>>>());
      expect(state.error, isA<NutritionFailureException>());
    });
  });
}
