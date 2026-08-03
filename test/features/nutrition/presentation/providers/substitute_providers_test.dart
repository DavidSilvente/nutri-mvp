import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/alternative_ranker.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/substitute_providers.dart';

import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_saved_meal_source.dart';

NutritionTarget _target({
  num kcal = 700,
  required num protein,
  required num carbs,
  required num fat,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
  );
}

void main() {
  group('rankedSubstitutesProvider', () {
    late FakeDietPlanSource dietSource;
    late FakeSavedMealSource savedSource;
    late ProviderContainer container;

    final query = (
      plannedMealId: 'pm-1',
      target: _target(protein: 40, carbs: 60, fat: 20),
    );

    setUp(() {
      dietSource = FakeDietPlanSource();
      savedSource = FakeSavedMealSource();
      container = ProviderContainer(
        overrides: [
          dietPlanSourceProvider.overrideWithValue(dietSource),
          savedMealSourceProvider.overrideWithValue(savedSource),
        ],
      );
      addTearDown(container.dispose);
    });

    test(
      'a plan-only scenario reproduces the prior single-group ranking',
      () async {
        await dietSource.saveSubstitute(
          MealSubstitute(
            id: 'near',
            plannedMealId: 'pm-1',
            label: 'Chicken and rice',
            target: _target(protein: 41, carbs: 59, fat: 21),
          ),
        );
        await dietSource.saveSubstitute(
          MealSubstitute(
            id: 'far',
            plannedMealId: 'pm-1',
            label: 'Pizza',
            target: _target(protein: 20, carbs: 110, fat: 45),
          ),
        );

        final groups = await container.read(
          rankedSubstitutesProvider(query).future,
        );

        expect(groups, hasLength(1));
        expect(groups.single.origin, AlternativeOrigin.plan);
        expect(groups.single.options.map((o) => o.ranked.id).toList(), [
          'near',
          'far',
        ]);
      },
    );

    test(
      'saved meals appear in their own second group, id-namespaced',
      () async {
        await dietSource.saveSubstitute(
          MealSubstitute(
            id: 'sub-1',
            plannedMealId: 'pm-1',
            label: 'Chicken and rice',
            target: _target(protein: 41, carbs: 59, fat: 21),
          ),
        );
        await savedSource.saveMeal(
          SavedMeal(
            id: 'm1',
            name: 'Tuna bowl',
            target: _target(protein: 42, carbs: 58, fat: 19),
            createdAt: DateTime.utc(2026, 8, 1),
          ),
        );

        final groups = await container.read(
          rankedSubstitutesProvider(query).future,
        );

        expect(groups, hasLength(2));
        expect(groups[0].origin, AlternativeOrigin.plan);
        expect(groups[1].origin, AlternativeOrigin.savedMeal);
        expect(groups[1].options.single.ranked.id, 'saved:m1');
        expect(groups[1].options.single.ranked.label, 'Tuna bowl');
      },
    );

    test('an empty saved-meal catalogue yields only the plan group', () async {
      await dietSource.saveSubstitute(
        MealSubstitute(
          id: 'sub-1',
          plannedMealId: 'pm-1',
          label: 'Chicken and rice',
          target: _target(protein: 41, carbs: 59, fat: 21),
        ),
      );

      final groups = await container.read(
        rankedSubstitutesProvider(query).future,
      );

      expect(groups, hasLength(1));
      expect(groups.single.origin, AlternativeOrigin.plan);
    });

    test('no candidates from either source yields no groups', () async {
      final groups = await container.read(
        rankedSubstitutesProvider(query).future,
      );

      expect(groups, isEmpty);
    });
  });
}
