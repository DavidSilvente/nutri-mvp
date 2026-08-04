import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

NutritionTarget target() {
  return NutritionTarget(
    energy: Energy(kcal: 500),
    macros: Macros(proteinG: 30, carbsG: 40, fatG: 15),
  );
}

List<PlannedMeal> unwrap(Result<List<PlannedMeal>, NutritionFailure> result) {
  return (result as Ok<List<PlannedMeal>, NutritionFailure>).value;
}

void main() {
  group('SqlDietPlanSource.plannedMealsBetween', () {
    late NutritionDatabase database;
    late SqlDietPlanSource source;

    setUp(() async {
      database = NutritionDatabase(NativeDatabase.memory());
      source = SqlDietPlanSource(database);

      // A planned meal names its slot but is not foreign-keyed to one: the
      // diet it came from lives in a plan document, and this table is the
      // ledger of what a day was committed to.
    });

    tearDown(() async {
      await database.close();
    });

    NutritionDay day(int d) => NutritionDay.fromDateTime(DateTime(2026, 7, d));

    Future<void> plan(String id, String slotId, NutritionDay? on) {
      return source.savePlannedMeal(
        PlannedMeal(id: id, slotId: slotId, day: on, targetSnapshot: target()),
      );
    }

    test('returns meals within the range, both bounds inclusive', () async {
      await plan('pm-09', 's1', day(9));
      await plan('pm-10', 's1', day(10));
      await plan('pm-15', 's1', day(15));
      await plan('pm-16', 's1', day(16));

      final meals = unwrap(await source.plannedMealsBetween(day(10), day(15)));

      expect(meals.map((m) => m.id).toSet(), {'pm-10', 'pm-15'});
    });

    test('excludes meals that have no day assigned', () async {
      await plan('pm-unscheduled', 's2', null);
      await plan('pm-12', 's1', day(12));

      final meals = unwrap(await source.plannedMealsBetween(day(1), day(31)));

      expect(meals.map((m) => m.id), ['pm-12']);
    });

    test('yields an empty list for an inverted range, not an error', () async {
      await plan('pm-12', 's1', day(12));

      final result = await source.plannedMealsBetween(day(15), day(10));

      expect(result, isA<Ok<List<PlannedMeal>, NutritionFailure>>());
      expect(unwrap(result), isEmpty);
    });

    test('yields an empty list when nothing falls in the range', () async {
      await plan('pm-12', 's1', day(12));

      final meals = unwrap(await source.plannedMealsBetween(day(1), day(5)));

      expect(meals, isEmpty);
    });

    test('preserves the frozen target snapshot and the day', () async {
      await plan('pm-12', 's1', day(12));

      final meals = unwrap(await source.plannedMealsBetween(day(12), day(12)));

      expect(meals.single.day, day(12));
      expect(meals.single.slotId, 's1');
      expect(meals.single.targetSnapshot, target());
    });
  });
}
