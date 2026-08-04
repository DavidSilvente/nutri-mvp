import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

NutritionTarget _target({
  double kcal = 100,
  double proteinG = 10,
  double carbsG = 10,
  double fatG = 5,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
  );
}

PlannedMeal _plannedMeal({
  required String id,
  required String slotId,
  NutritionDay? day,
  NutritionTarget? targetSnapshot,
}) {
  return PlannedMeal(
    id: id,
    slotId: slotId,
    day: day,
    targetSnapshot: targetSnapshot ?? _target(),
  );
}

MealSubstitute _substitute({
  required String id,
  required String plannedMealId,
  String label = 'Substitute',
  NutritionTarget? target,
}) {
  return MealSubstitute(
    id: id,
    plannedMealId: plannedMealId,
    label: label,
    target: target ?? _target(kcal: 150),
  );
}

void main() {
  group('SqlDietPlanSource', () {
    late NutritionDatabase database;
    late SqlDietPlanSource source;

    setUp(() {
      database = NutritionDatabase(NativeDatabase.memory());
      source = SqlDietPlanSource(database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'savePlannedMeal persists a meal so it is returned by listPlannedMeals',
      () async {
        final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
        final meal = _plannedMeal(
          id: 'pm1',
          slotId: 'slot-a',
          day: day,
          targetSnapshot: _target(
            kcal: 700,
            proteinG: 40,
            carbsG: 60,
            fatG: 20,
          ),
        );

        final result = await source.savePlannedMeal(meal);
        final listResult = await source.listPlannedMeals();

        expect(result, isA<Ok<PlannedMeal, NutritionFailure>>());
        final meals =
            (listResult as Ok<List<PlannedMeal>, NutritionFailure>).value;
        expect(meals, [meal]);
      },
    );

    test('savePlannedMeal rejects the same slot on the same day', () async {
      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      await source.savePlannedMeal(
        _plannedMeal(id: 'pm1', slotId: 'slot-a', day: day),
      );

      final duplicate = _plannedMeal(id: 'pm2', slotId: 'slot-a', day: day);
      final result = await source.savePlannedMeal(duplicate);

      expect(result, isA<Err<PlannedMeal, NutritionFailure>>());
      final failure = (result as Err<PlannedMeal, NutritionFailure>).failure;
      expect(failure, isA<ConflictFailure>());
    });

    test('savePlannedMeal allows the same slot on different days', () async {
      final day1 = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final day2 = NutritionDay.fromDateTime(DateTime(2026, 8, 2));
      final meal1 = _plannedMeal(id: 'pm1', slotId: 'slot-a', day: day1);
      final meal2 = _plannedMeal(id: 'pm2', slotId: 'slot-a', day: day2);

      final result1 = await source.savePlannedMeal(meal1);
      final result2 = await source.savePlannedMeal(meal2);

      expect(result1, isA<Ok<PlannedMeal, NutritionFailure>>());
      expect(result2, isA<Ok<PlannedMeal, NutritionFailure>>());
    });

    test('listPlannedMeals filters by day when provided', () async {
      final day1 = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final day2 = NutritionDay.fromDateTime(DateTime(2026, 8, 2));
      final meal1 = _plannedMeal(id: 'pm1', slotId: 'slot-a', day: day1);
      final meal2 = _plannedMeal(id: 'pm2', slotId: 'slot-b', day: day2);
      await source.savePlannedMeal(meal1);
      await source.savePlannedMeal(meal2);

      final result = await source.listPlannedMeals(day: day1);
      final meals = (result as Ok<List<PlannedMeal>, NutritionFailure>).value;
      expect(meals, [meal1]);
    });

    test('deletePlannedMeal removes the meal and its substitutes', () async {
      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final meal = _plannedMeal(id: 'pm1', slotId: 'slot-a', day: day);
      await source.savePlannedMeal(meal);
      await source.saveSubstitute(
        _substitute(id: 'sub1', plannedMealId: 'pm1'),
      );

      final deleteResult = await source.deletePlannedMeal('pm1');
      expect(deleteResult, isA<Ok<void, NutritionFailure>>());

      final listResult = await source.listPlannedMeals();
      final meals =
          (listResult as Ok<List<PlannedMeal>, NutritionFailure>).value;
      expect(meals, isEmpty);

      final subsResult = await source.listSubstitutes('pm1');
      final substitutes =
          (subsResult as Ok<List<MealSubstitute>, NutritionFailure>).value;
      expect(substitutes, isEmpty);
    });

    test(
      'saveSubstitute persists a substitute scoped to its planned meal',
      () async {
        final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
        final meal = _plannedMeal(id: 'pm1', slotId: 'slot-a', day: day);
        await source.savePlannedMeal(meal);

        final substitute = _substitute(
          id: 'sub1',
          plannedMealId: 'pm1',
          label: 'Tofu (200g)',
          target: _target(kcal: 200, proteinG: 20, carbsG: 15, fatG: 10),
        );
        final result = await source.saveSubstitute(substitute);
        final listResult = await source.listSubstitutes('pm1');

        expect(result, isA<Ok<MealSubstitute, NutritionFailure>>());
        final substitutes =
            (listResult as Ok<List<MealSubstitute>, NutritionFailure>).value;
        expect(substitutes, [substitute]);
      },
    );

    test(
      'listSubstitutes does not leak substitutes across planned meals',
      () async {
        final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
        final mealX = _plannedMeal(id: 'pm-x', slotId: 'slot-a', day: day);
        final mealY = _plannedMeal(id: 'pm-y', slotId: 'slot-b', day: day);
        await source.savePlannedMeal(mealX);
        await source.savePlannedMeal(mealY);

        await source.saveSubstitute(
          _substitute(id: 'sub-x', plannedMealId: 'pm-x'),
        );

        final result = await source.listSubstitutes('pm-y');
        final substitutes =
            (result as Ok<List<MealSubstitute>, NutritionFailure>).value;
        expect(substitutes, isEmpty);
      },
    );

    test('deleteSubstitute removes the substitute', () async {
      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final meal = _plannedMeal(id: 'pm1', slotId: 'slot-a', day: day);
      await source.savePlannedMeal(meal);
      await source.saveSubstitute(
        _substitute(id: 'sub1', plannedMealId: 'pm1'),
      );

      final deleteResult = await source.deleteSubstitute('sub1');
      expect(deleteResult, isA<Ok<void, NutritionFailure>>());

      final listResult = await source.listSubstitutes('pm1');
      final substitutes =
          (listResult as Ok<List<MealSubstitute>, NutritionFailure>).value;
      expect(substitutes, isEmpty);
    });

    test('data persists across separate SqlDietPlanSource instances '
        'sharing the same database', () async {
      final meal = _plannedMeal(
        id: 'pm1',
        slotId: 'slot-a',
        day: NutritionDay.fromDateTime(DateTime(2026, 8, 1)),
      );
      await source.savePlannedMeal(meal);

      final reopenedSource = SqlDietPlanSource(database);
      final listResult = await reopenedSource.listPlannedMeals();
      final meals =
          (listResult as Ok<List<PlannedMeal>, NutritionFailure>).value;
      expect(meals, [meal]);
    });

    test(
      'savePlannedMeal allows multiple unplanned meals for the same slot',
      () async {
        final meal1 = _plannedMeal(id: 'pm1', slotId: 'slot-a');
        final meal2 = _plannedMeal(id: 'pm2', slotId: 'slot-a');

        final result1 = await source.savePlannedMeal(meal1);
        final result2 = await source.savePlannedMeal(meal2);

        expect(result1, isA<Ok<PlannedMeal, NutritionFailure>>());
        expect(result2, isA<Ok<PlannedMeal, NutritionFailure>>());
      },
    );

    test(
      'listPlannedMeals returns an empty list when no meals exist',
      () async {
        final listResult = await source.listPlannedMeals();
        final meals =
            (listResult as Ok<List<PlannedMeal>, NutritionFailure>).value;
        expect(meals, isEmpty);
      },
    );

    test(
      'savePlannedMeal reassigns an existing meal to a different slot',
      () async {
        final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
        final original = _plannedMeal(
          id: 'pm1',
          slotId: 'slot-a',
          day: day,
          targetSnapshot: _target(
            kcal: 700,
            proteinG: 40,
            carbsG: 60,
            fatG: 20,
          ),
        );
        await source.savePlannedMeal(original);

        final reassigned = _plannedMeal(
          id: 'pm1',
          slotId: 'slot-b',
          day: day,
          targetSnapshot: _target(
            kcal: 600,
            proteinG: 35,
            carbsG: 50,
            fatG: 18,
          ),
        );
        final result = await source.savePlannedMeal(reassigned);
        final listResult = await source.listPlannedMeals();
        final meals =
            (listResult as Ok<List<PlannedMeal>, NutritionFailure>).value;

        expect(result, isA<Ok<PlannedMeal, NutritionFailure>>());
        expect(meals, [reassigned]);
      },
    );
  });
}
