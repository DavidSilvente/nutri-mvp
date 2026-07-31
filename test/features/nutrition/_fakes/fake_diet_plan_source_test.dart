import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
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

DietTemplate _template({
  required String id,
  required String name,
  required NutritionTarget target,
}) {
  return DietTemplate(
    id: id,
    name: name,
    dailyTarget: target,
    slots: [
      DietMealSlot(
        id: '${id}_slot',
        label: 'Meal',
        position: 0,
        target: target,
      ),
    ],
  );
}

void main() {
  group('FakeDietPlanSource', () {
    test('saveTemplate persists a template so it is returned by listTemplates',
        () async {
      final source = FakeDietPlanSource();
      final template = _template(id: 't1', name: 'Cut-A', target: _target());

      final saveResult = await source.saveTemplate(template);
      final listResult = await source.listTemplates();

      expect(saveResult, isA<Ok<DietTemplate, NutritionFailure>>());
      final templates =
          (listResult as Ok<List<DietTemplate>, NutritionFailure>).value;
      expect(templates, [template]);
    });

    test('saveTemplate rejects a duplicate name for a different id', () async {
      final source = FakeDietPlanSource();
      final first = _template(id: 't1', name: 'Cut-A', target: _target());
      final duplicate = _template(id: 't2', name: 'Cut-A', target: _target());

      await source.saveTemplate(first);
      final result = await source.saveTemplate(duplicate);

      expect(result, isA<Err<DietTemplate, NutritionFailure>>());
      expect(
        (result as Err<DietTemplate, NutritionFailure>).failure,
        isA<ConflictFailure>(),
      );
    });

    test('saveTemplate allows updating a template while keeping its own name',
        () async {
      final source = FakeDietPlanSource();
      final original = _template(id: 't1', name: 'Cut-A', target: _target());
      final updated = _template(
        id: 't1',
        name: 'Cut-A',
        target: _target(kcal: 800),
      );

      await source.saveTemplate(original);
      final result = await source.saveTemplate(updated);

      expect(result, isA<Ok<DietTemplate, NutritionFailure>>());
      final templates =
          (await source.listTemplates() as Ok<List<DietTemplate>, NutritionFailure>)
              .value;
      expect(templates, [updated]);
    });

    test(
        'saveTemplate preserves planned meals when slot identity is unchanged',
        () async {
      final source = FakeDietPlanSource();
      final original = _template(id: 't1', name: 'Cut-A', target: _target());
      await source.saveTemplate(original);

      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final meal = PlannedMeal(
        id: 'm1',
        slotId: 't1_slot',
        day: day,
        targetSnapshot: _target(),
      );
      await source.savePlannedMeal(meal);
      await source.saveSubstitute(
        MealSubstitute(
          id: 'sub1',
          plannedMealId: 'm1',
          label: 'Tofu',
          target: _target(),
        ),
      );

      final updated = DietTemplate(
        id: 't1',
        name: 'Cut-A',
        dailyTarget: _target(kcal: 800),
        slots: [
          DietMealSlot(
            id: 't1_slot',
            label: 'Brunch',
            position: 0,
            target: _target(kcal: 800),
          ),
        ],
      );
      final result = await source.saveTemplate(updated);
      final mealsResult = await source.listPlannedMeals();
      final substitutesResult = await source.listSubstitutes('m1');

      expect(result, isA<Ok<DietTemplate, NutritionFailure>>());
      final meals =
          (mealsResult as Ok<List<PlannedMeal>, NutritionFailure>).value;
      expect(meals, [meal]);
      final substitutes =
          (substitutesResult as Ok<List<MealSubstitute>, NutritionFailure>)
              .value;
      expect(substitutes, isNotEmpty);
    });

    test('saveTemplate deletes planned meals for removed slots', () async {
      final source = FakeDietPlanSource();
      final slotA = DietMealSlot(
        id: 'slot-a',
        label: 'Breakfast',
        position: 0,
        target: _target(),
      );
      final slotB = DietMealSlot(
        id: 'slot-b',
        label: 'Lunch',
        position: 1,
        target: _target(),
      );
      final original = DietTemplate(
        id: 't1',
        name: 'Cut-A',
        dailyTarget: NutritionTarget.sum([slotA.target, slotB.target]),
        slots: [slotA, slotB],
      );
      await source.saveTemplate(original);

      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final mealA = PlannedMeal(
        id: 'ma',
        slotId: 'slot-a',
        day: day,
        targetSnapshot: _target(),
      );
      final mealB = PlannedMeal(
        id: 'mb',
        slotId: 'slot-b',
        day: day,
        targetSnapshot: _target(),
      );
      await source.savePlannedMeal(mealA);
      await source.savePlannedMeal(mealB);
      await source.saveSubstitute(
        MealSubstitute(
          id: 'sub-b',
          plannedMealId: 'mb',
          label: 'Tofu',
          target: _target(),
        ),
      );

      final updated = DietTemplate(
        id: 't1',
        name: 'Cut-A',
        dailyTarget: _target(),
        slots: [
          DietMealSlot(
            id: 'slot-a',
            label: 'Breakfast',
            position: 0,
            target: _target(),
          ),
        ],
      );
      final result = await source.saveTemplate(updated);
      final mealsResult = await source.listPlannedMeals();
      final substitutesResult = await source.listSubstitutes('mb');

      expect(result, isA<Ok<DietTemplate, NutritionFailure>>());
      final meals =
          (mealsResult as Ok<List<PlannedMeal>, NutritionFailure>).value;
      expect(meals, [mealA]);
      final substitutes =
          (substitutesResult as Ok<List<MealSubstitute>, NutritionFailure>)
              .value;
      expect(substitutes, isEmpty);
    });

    test('deleteTemplate removes the template', () async {
      final source = FakeDietPlanSource();
      final template = _template(id: 't1', name: 'Cut-A', target: _target());

      await source.saveTemplate(template);
      final deleteResult = await source.deleteTemplate('t1');
      final listResult = await source.listTemplates();

      expect(deleteResult, isA<Ok<void, NutritionFailure>>());
      expect(
        (listResult as Ok<List<DietTemplate>, NutritionFailure>).value,
        isEmpty,
      );
    });

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

    test('listPlannedMeals filters by templateId when provided', () async {
      final source = FakeDietPlanSource();
      final templateA = _template(id: 'ta', name: 'A', target: _target());
      final templateB = _template(id: 'tb', name: 'B', target: _target());
      await source.saveTemplate(templateA);
      await source.saveTemplate(templateB);

      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final mealA = PlannedMeal(
        id: 'ma',
        slotId: 'ta_slot',
        day: day,
        targetSnapshot: _target(),
      );
      final mealB = PlannedMeal(
        id: 'mb',
        slotId: 'tb_slot',
        day: day,
        targetSnapshot: _target(),
      );
      await source.savePlannedMeal(mealA);
      await source.savePlannedMeal(mealB);

      final result = await source.listPlannedMeals(templateId: 'ta');
      final meals =
          (result as Ok<List<PlannedMeal>, NutritionFailure>).value;
      expect(meals, [mealA]);
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
