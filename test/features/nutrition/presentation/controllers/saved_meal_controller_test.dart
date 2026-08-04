import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
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

    test(
      'a failed saveMeal preserves the previously loaded list instead of '
      'losing it, so the UI can keep rendering the unchanged catalogue',
      () async {
        final container = ProviderContainer(
          overrides: [
            savedMealSourceProvider.overrideWithValue(FakeSavedMealSource()),
          ],
        );
        addTearDown(container.dispose);
        await container.read(savedMealControllerProvider.future);

        final original = _meal(id: 'm1', name: 'Chicken salad');
        await container
            .read(savedMealControllerProvider.notifier)
            .saveMeal(original);
        await container
            .read(savedMealControllerProvider.notifier)
            .saveMeal(_meal(id: 'm2', name: ' chicken SALAD '));

        final state = container.read(savedMealControllerProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull, [original]);
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

  group('SavedMealController.promoteEntry', () {
    NutritionEntry entry({
      String id = 'e1',
      num kcal = 270,
      num protein = 30,
      num carbs = 20,
      num fat = 10,
      String? plannedMealId,
    }) {
      return NutritionEntry(
        id: id,
        recordedAt: DateTime.utc(2026, 8, 1, 13),
        energy: Energy(kcal: kcal),
        macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
        plannedMealId: plannedMealId,
      );
    }

    test(
      'copies the entry macros verbatim into a new saved meal, leaving the '
      'entry unchanged',
      () async {
        final container = ProviderContainer(
          overrides: [
            savedMealSourceProvider.overrideWithValue(FakeSavedMealSource()),
          ],
        );
        addTearDown(container.dispose);
        await container.read(savedMealControllerProvider.future);

        final source = entry(plannedMealId: 'pm-1');
        final untouched = entry(plannedMealId: 'pm-1');

        await container
            .read(savedMealControllerProvider.notifier)
            .promoteEntry(source, name: 'Post-workout shake');

        final state = container.read(savedMealControllerProvider);
        final meals = state.value!;
        expect(meals, hasLength(1));
        expect(meals.single.name, 'Post-workout shake');
        expect(meals.single.target.energy, source.energy);
        expect(meals.single.target.macros, source.macros);
        expect(meals.single.portionNote, isNull);
        // The source entry object was never mutated by promotion.
        expect(source, untouched);
      },
    );

    test('an optional portionNote is copied onto the saved meal', () async {
      final container = ProviderContainer(
        overrides: [
          savedMealSourceProvider.overrideWithValue(FakeSavedMealSource()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(savedMealControllerProvider.future);

      await container
          .read(savedMealControllerProvider.notifier)
          .promoteEntry(
            entry(),
            name: 'Post-workout shake',
            portionNote: 'One scoop, whole milk',
          );

      final state = container.read(savedMealControllerProvider);
      expect(state.value!.single.portionNote, 'One scoop, whole milk');
    });

    test(
      'promoting a second entry under a name that already exists surfaces a '
      'ConflictFailure and leaves the catalogue at one meal',
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
            .promoteEntry(entry(id: 'e1'), name: 'Post-workout shake');
        await container
            .read(savedMealControllerProvider.notifier)
            .promoteEntry(
              entry(id: 'e2', kcal: 300),
              name: ' post-workout SHAKE ',
            );

        final state = container.read(savedMealControllerProvider);
        expect(state.hasError, isTrue);
        final error = state.error! as HealthFailureException;
        expect(error.failure, isA<ConflictFailure>());
        expect(state.valueOrNull, hasLength(1));
      },
    );
  });
}
