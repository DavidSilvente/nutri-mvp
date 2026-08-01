import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/apply_template_to_days.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

import '../../_fakes/fake_diet_plan_source.dart';

NutritionTarget target({num kcal = 600}) => NutritionTarget(
  energy: Energy(kcal: kcal),
  macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
);

DietTemplate buildTemplate() {
  final slots = [
    DietMealSlot(
      id: 'slot-breakfast',
      label: 'Breakfast',
      position: 0,
      target: target(kcal: 400),
    ),
    DietMealSlot(
      id: 'slot-lunch',
      label: 'Lunch',
      position: 1,
      target: target(kcal: 800),
    ),
  ];
  return DietTemplate(
    id: 't1',
    name: 'Plan',
    dailyTarget: NutritionTarget.sum(slots.map((s) => s.target)),
    slots: slots,
  );
}

void main() {
  late FakeDietPlanSource source;
  late ApplyTemplateToDays useCase;
  final template = buildTemplate();

  NutritionDay day(int d) => NutritionDay.fromDateTime(DateTime(2026, 7, d));

  setUp(() async {
    source = FakeDietPlanSource();
    useCase = ApplyTemplateToDays(source);
    await source.saveTemplate(template);
  });

  Future<List<PlannedMeal>> plannedOn(NutritionDay d) async {
    final result = await source.listPlannedMeals(day: d);
    return (result as Ok<List<PlannedMeal>, NutritionFailure>).value;
  }

  group('ApplyTemplateToDays', () {
    test('creates one planned meal per slot per day', () async {
      final result = await useCase(
        template: template,
        days: [day(10), day(11), day(12)],
      );

      expect((result as Ok<int, NutritionFailure>).value, 6);
      expect(await plannedOn(day(10)), hasLength(2));
      expect(await plannedOn(day(12)), hasLength(2));
    });

    test('freezes each slot target onto its planned meal', () async {
      await useCase(template: template, days: [day(10)]);

      final meals = await plannedOn(day(10));
      final breakfast = meals.firstWhere(
        (m) => m.slotId == 'slot-breakfast',
      );
      expect(breakfast.targetSnapshot, target(kcal: 400));
    });

    test('is idempotent: re-applying does not duplicate or conflict', () async {
      await useCase(template: template, days: [day(10)]);
      final second = await useCase(template: template, days: [day(10)]);

      expect(second, isA<Ok<int, NutritionFailure>>());
      expect(await plannedOn(day(10)), hasLength(2));
    });

    test('uses deterministic ids so a retry overwrites the same rows', () async {
      await useCase(template: template, days: [day(10)]);

      final meals = await plannedOn(day(10));
      expect(
        meals.map((m) => m.id).toSet(),
        {
          ApplyTemplateToDays.plannedMealId('slot-breakfast', day(10)),
          ApplyTemplateToDays.plannedMealId('slot-lunch', day(10)),
        },
      );
    });

    test('writes nothing for an empty day list', () async {
      final result = await useCase(template: template, days: []);

      expect((result as Ok<int, NutritionFailure>).value, 0);
    });

    test('clear removes the meals it created, leaving other days alone', () async {
      await useCase(template: template, days: [day(10), day(11)]);

      final removed = await useCase.clear(
        template: template,
        days: [day(10)],
      );

      expect((removed as Ok<int, NutritionFailure>).value, 2);
      expect(await plannedOn(day(10)), isEmpty);
      expect(await plannedOn(day(11)), hasLength(2));
    });

    test('stops at the first failure and reports it', () async {
      final failing = ApplyTemplateToDays(_FailingSource());

      final result = await failing(template: template, days: [day(10)]);

      expect(
        result,
        const Err<int, NutritionFailure>(StorageFailure('disk full')),
      );
    });
  });
}

class _FailingSource extends FakeDietPlanSource {
  @override
  Future<Result<PlannedMeal, NutritionFailure>> savePlannedMeal(
    PlannedMeal meal,
  ) async {
    return const Err(StorageFailure('disk full'));
  }
}
