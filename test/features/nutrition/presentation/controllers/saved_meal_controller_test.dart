import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/data_revision_provider.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';

import '../../_fakes/fake_saved_meal_source.dart';

NutritionTarget _target({
  double kcal = 300,
  double proteinG = 20,
  double carbsG = 30,
  double fatG = 10,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
  );
}

SavedMeal _meal({
  required String id,
  required String name,
  NutritionTarget? target,
  String? portionNote,
}) {
  return SavedMeal(
    id: id,
    name: name,
    target: target ?? _target(),
    portionNote: portionNote,
    createdAt: DateTime.utc(2026, 8, 1),
  );
}

void main() {
  group('SavedMealController', () {
    test('builds with an empty list when the source has no meals', () async {
      final container = ProviderContainer(
        overrides: [
          savedMealSourceProvider.overrideWithValue(FakeSavedMealSource()),
        ],
      );
      addTearDown(container.dispose);

      final initial =
          await container.read(savedMealControllerProvider.future);

      expect(initial, isEmpty);
    });

    test(
      'saveMeal reflects the created meal in the async state and bumps the '
      'data revision',
      () async {
        final container = ProviderContainer(
          overrides: [
            savedMealSourceProvider.overrideWithValue(FakeSavedMealSource()),
          ],
        );
        addTearDown(container.dispose);
        await container.read(savedMealControllerProvider.future);
        final revisionBefore = container.read(dataRevisionProvider);

        final meal = _meal(id: 'm1', name: 'Chicken salad');
        await container
            .read(savedMealControllerProvider.notifier)
            .saveMeal(meal);

        final state = container.read(savedMealControllerProvider);
        expect(state.value, [meal]);
        expect(container.read(dataRevisionProvider), revisionBefore + 1);
      },
    );

    test(
      'saveMeal with a duplicate (trimmed/case-insensitive) name surfaces a '
      'ConflictFailure as AsyncError',
      () async {
        final container = ProviderContainer(
          overrides: [
            savedMealSourceProvider.overrideWithValue(FakeSavedMealSource()),
          ],
        );
        addTearDown(container.dispose);
        await container.read(savedMealControllerProvider.future);

        await container
            .read(savedMealControllerProvider.notifier)
            .saveMeal(_meal(id: 'm1', name: 'Chicken salad'));
        await container
            .read(savedMealControllerProvider.notifier)
            .saveMeal(_meal(id: 'm2', name: ' chicken SALAD '));

        final state = container.read(savedMealControllerProvider);
        expect(state, isA<AsyncError<List<SavedMeal>>>());
        final error = state.error! as HealthFailureException;
        expect(error.failure, isA<ConflictFailure>());
      },
    );

    test('deleteSavedMeal removes the meal from the async state', () async {
      final container = ProviderContainer(
        overrides: [
          savedMealSourceProvider.overrideWithValue(FakeSavedMealSource()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(savedMealControllerProvider.future);

      final meal = _meal(id: 'm1', name: 'Chicken salad');
      await container
          .read(savedMealControllerProvider.notifier)
          .saveMeal(meal);
      await container
          .read(savedMealControllerProvider.notifier)
          .deleteSavedMeal('m1');

      final state = container.read(savedMealControllerProvider);
      expect(state.value, isEmpty);
    });
  });
}
