import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_saved_meal_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

NutritionTarget _target({
  double kcal = 400,
  double proteinG = 30,
  double carbsG = 40,
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
  DateTime? createdAt,
}) {
  return SavedMeal(
    id: id,
    name: name,
    target: target ?? _target(),
    portionNote: portionNote,
    createdAt: createdAt ?? DateTime.utc(2026, 8, 1),
  );
}

void main() {
  group('SqlSavedMealSource', () {
    late NutritionDatabase db;
    late SqlSavedMealSource source;

    setUp(() {
      db = NutritionDatabase(NativeDatabase.memory());
      source = SqlSavedMealSource(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('saveMeal then listSavedMeals round-trips the meal', () async {
      final meal = _meal(id: 'm1', name: 'Chicken salad');

      final saveResult = await source.saveMeal(meal);
      final listResult = await source.listSavedMeals();

      expect(saveResult, isA<Ok<SavedMeal, NutritionFailure>>());
      final meals = (listResult as Ok<List<SavedMeal>, NutritionFailure>).value;
      expect(meals, [meal]);
    });

    test(
      'saveMeal rejects a duplicate normalized name for a different id',
      () async {
        final first = _meal(id: 'm1', name: 'Chicken Salad');
        final duplicate = _meal(id: 'm2', name: ' chicken SALAD ');

        await source.saveMeal(first);
        final result = await source.saveMeal(duplicate);

        expect(result, isA<Err<SavedMeal, NutritionFailure>>());
        expect(
          (result as Err<SavedMeal, NutritionFailure>).failure,
          isA<ConflictFailure>(),
        );
      },
    );

    test('saveMeal allows renaming while keeping the same id (edit, '
        'not a conflict)', () async {
      final original = _meal(id: 'm1', name: 'Chicken salad');
      await source.saveMeal(original);

      final renamed = _meal(id: 'm1', name: 'Chicken salad');
      final result = await source.saveMeal(renamed);

      expect(result, isA<Ok<SavedMeal, NutritionFailure>>());
    });

    test('saveMeal allows editing macros without triggering a false '
        'conflict', () async {
      final original = _meal(id: 'm1', name: 'Chicken salad');
      await source.saveMeal(original);

      final edited = _meal(
        id: 'm1',
        name: 'Chicken salad',
        target: _target(kcal: 500),
      );
      final result = await source.saveMeal(edited);

      expect(result, isA<Ok<SavedMeal, NutritionFailure>>());
      final listResult = await source.listSavedMeals();
      final meals = (listResult as Ok<List<SavedMeal>, NutritionFailure>).value;
      expect(meals, [edited]);
    });

    test('listSavedMeals orders by name', () async {
      await source.saveMeal(_meal(id: 'm1', name: 'Zucchini bowl'));
      await source.saveMeal(_meal(id: 'm2', name: 'Apple snack'));

      final result = await source.listSavedMeals();
      final meals = (result as Ok<List<SavedMeal>, NutritionFailure>).value;

      expect(meals.map((m) => m.name).toList(), [
        'Apple snack',
        'Zucchini bowl',
      ]);
    });

    test('deleteSavedMeal removes the meal', () async {
      final meal = _meal(id: 'm1', name: 'Chicken salad');
      await source.saveMeal(meal);

      final deleteResult = await source.deleteSavedMeal('m1');
      final listResult = await source.listSavedMeals();

      expect(deleteResult, isA<Ok<void, NutritionFailure>>());
      expect(
        (listResult as Ok<List<SavedMeal>, NutritionFailure>).value,
        isEmpty,
      );
    });

    test('deleteSavedMeal is a no-op when the meal does not exist', () async {
      final deleteResult = await source.deleteSavedMeal('missing');

      expect(deleteResult, isA<Ok<void, NutritionFailure>>());
    });

    test('saveMeal persists an optional portionNote', () async {
      final meal = _meal(
        id: 'm1',
        name: 'Chicken salad',
        portionNote: '200g grilled breast + greens',
      );

      await source.saveMeal(meal);
      final result = await source.listSavedMeals();
      final meals = (result as Ok<List<SavedMeal>, NutritionFailure>).value;

      expect(meals.single.portionNote, '200g grilled breast + greens');
    });
  });
}
