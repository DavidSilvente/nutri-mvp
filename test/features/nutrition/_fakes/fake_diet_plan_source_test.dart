import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

import 'fake_diet_plan_source.dart';

NutritionTarget _target({
  double kcal = 700,
  double proteinG = 40,
  double carbsG = 60,
  double fatG = 20,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
  );
}

void main() {
  group('FakeDietPlanSource', () {






    test('savePlannedMeal persists a meal so it is returned by listPlannedMeals',
        () async {
      final source = FakeDietPlanSource();
      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final meal = PlannedMeal(
        id: 'm1',
        slotId: 's1',
        day: day,
        targetSnapshot: _target(),
      );

      final saveResult = await source.savePlannedMeal(meal);
      final listResult = await source.listPlannedMeals();

      expect(saveResult, isA<Ok<PlannedMeal, NutritionFailure>>());
      final meals =
          (listResult as Ok<List<PlannedMeal>, NutritionFailure>).value;
      expect(meals, [meal]);
    });

    test('savePlannedMeal rejects the same slot on the same day', () async {
      final source = FakeDietPlanSource();
      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final first = PlannedMeal(
        id: 'm1',
        slotId: 's1',
        day: day,
        targetSnapshot: _target(),
      );
      final duplicate = PlannedMeal(
        id: 'm2',
        slotId: 's1',
        day: day,
        targetSnapshot: _target(),
      );

      await source.savePlannedMeal(first);
      final result = await source.savePlannedMeal(duplicate);

      expect(result, isA<Err<PlannedMeal, NutritionFailure>>());
      expect(
        (result as Err<PlannedMeal, NutritionFailure>).failure,
        isA<ConflictFailure>(),
      );
    });

    test('savePlannedMeal allows the same slot on different days', () async {
      final source = FakeDietPlanSource();
      final day1 = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final day2 = NutritionDay.fromDateTime(DateTime(2026, 8, 2));
      final first = PlannedMeal(
        id: 'm1',
        slotId: 's1',
        day: day1,
        targetSnapshot: _target(),
      );
      final second = PlannedMeal(
        id: 'm2',
        slotId: 's1',
        day: day2,
        targetSnapshot: _target(),
      );

      final firstResult = await source.savePlannedMeal(first);
      final secondResult = await source.savePlannedMeal(second);

      expect(firstResult, isA<Ok<PlannedMeal, NutritionFailure>>());
      expect(secondResult, isA<Ok<PlannedMeal, NutritionFailure>>());
    });


    test('listPlannedMeals filters by day when provided', () async {
      final source = FakeDietPlanSource();
      final day1 = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final day2 = NutritionDay.fromDateTime(DateTime(2026, 8, 2));
      final meal1 = PlannedMeal(
        id: 'm1',
        slotId: 's1',
        day: day1,
        targetSnapshot: _target(),
      );
      final meal2 = PlannedMeal(
        id: 'm2',
        slotId: 's2',
        day: day2,
        targetSnapshot: _target(),
      );
      await source.savePlannedMeal(meal1);
      await source.savePlannedMeal(meal2);

      final result = await source.listPlannedMeals(day: day1);
      final meals =
          (result as Ok<List<PlannedMeal>, NutritionFailure>).value;
      expect(meals, [meal1]);
    });

    test('deletePlannedMeal removes the meal and its substitutes', () async {
      final source = FakeDietPlanSource();
      final meal = PlannedMeal(
        id: 'm1',
        slotId: 's1',
        day: NutritionDay.fromDateTime(DateTime(2026, 8, 1)),
        targetSnapshot: _target(),
      );
      final substitute = MealSubstitute(
        id: 'sub1',
        plannedMealId: 'm1',
        label: 'Tofu',
        target: _target(),
      );
      await source.savePlannedMeal(meal);
      await source.saveSubstitute(substitute);

      final deleteResult = await source.deletePlannedMeal('m1');
      final mealsResult = await source.listPlannedMeals();
      final substitutesResult = await source.listSubstitutes('m1');

      expect(deleteResult, isA<Ok<void, NutritionFailure>>());
      expect(
        (mealsResult as Ok<List<PlannedMeal>, NutritionFailure>).value,
        isEmpty,
      );
      expect(
        (substitutesResult as Ok<List<MealSubstitute>, NutritionFailure>).value,
        isEmpty,
      );
    });

    test('saveSubstitute persists a substitute scoped to its planned meal',
        () async {
      final source = FakeDietPlanSource();
      final substitute = MealSubstitute(
        id: 'sub1',
        plannedMealId: 'm1',
        label: 'Tofu',
        target: _target(),
      );

      final saveResult = await source.saveSubstitute(substitute);
      final listResult = await source.listSubstitutes('m1');

      expect(saveResult, isA<Ok<MealSubstitute, NutritionFailure>>());
      final substitutes =
          (listResult as Ok<List<MealSubstitute>, NutritionFailure>).value;
      expect(substitutes, [substitute]);
    });

    test('listSubstitutes does not leak substitutes across planned meals',
        () async {
      final source = FakeDietPlanSource();
      final subA = MealSubstitute(
        id: 'subA',
        plannedMealId: 'mA',
        label: 'Tofu',
        target: _target(),
      );
      final subB = MealSubstitute(
        id: 'subB',
        plannedMealId: 'mB',
        label: 'Tempeh',
        target: _target(),
      );

      await source.saveSubstitute(subA);
      await source.saveSubstitute(subB);

      final result = await source.listSubstitutes('mA');
      final substitutes =
          (result as Ok<List<MealSubstitute>, NutritionFailure>).value;
      expect(substitutes, [subA]);
    });

    test('deleteSubstitute removes the substitute', () async {
      final source = FakeDietPlanSource();
      final substitute = MealSubstitute(
        id: 'sub1',
        plannedMealId: 'm1',
        label: 'Tofu',
        target: _target(),
      );

      await source.saveSubstitute(substitute);
      final deleteResult = await source.deleteSubstitute('sub1');
      final listResult = await source.listSubstitutes('m1');

      expect(deleteResult, isA<Ok<void, NutritionFailure>>());
      expect(
        (listResult as Ok<List<MealSubstitute>, NutritionFailure>).value,
        isEmpty,
      );
    });
  });
}
