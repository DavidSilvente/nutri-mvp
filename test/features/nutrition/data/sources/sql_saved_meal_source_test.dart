import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_nutrition_source.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_saved_meal_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// A food whose per-100g composition is 200 kcal / 20P / 10C / 5F, used by
/// the composition round-trip tests below.
FoodItem _food(String id) => FoodItem(
  id: id,
  name: 'Food $id',
  preparation: FoodPreparation.raw,
  per100g: NutritionTarget(
    energy: Energy(kcal: 200),
    macros: Macros(proteinG: 20, carbsG: 10, fatG: 5),
  ),
  source: FoodDataSource.usdaSrLegacy,
);

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

    test(
      'saveMeal persists a composed meal\'s ingredients in order, including '
      'an unresolved foodId, and listSavedMeals rehydrates them verbatim',
      () async {
        final catalog = FoodCatalog([_food('chicken_breast'), _food('rice')]);
        final ingredients = [
          LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 80)),
          LoggedIngredient(
            foodId: 'discontinued_food',
            quantity: FoodQuantity(grams: 30),
          ),
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 120),
          ),
        ];
        final meal = SavedMeal.composed(
          id: 'm1',
          name: 'Chicken and rice',
          composition: DerivedTargets.compose(ingredients, catalog),
          createdAt: DateTime.utc(2026, 8, 1),
        );

        await source.saveMeal(meal);
        final result = await source.listSavedMeals();
        final loaded =
            (result as Ok<List<SavedMeal>, NutritionFailure>).value.single;

        expect(loaded, meal);
        expect(
          loaded.ingredients.map((i) => i.foodId).toList(),
          ['rice', 'discontinued_food', 'chicken_breast'],
        );
      },
    );

    // The legacy composition-less shape is already covered by
    // 'saveMeal then listSavedMeals round-trips the meal' above: `_meal()`
    // builds a hand-typed meal with zero ingredients, and `SavedMeal.==`
    // compares `ingredients` element-wise, so that round-trip already
    // proves an empty ingredient list survives with the flat target
    // unchanged — no separate test needed here.

    test(
      're-saving a composed meal with a changed, reordered composition '
      'replaces rather than appends its ingredient rows',
      () async {
        final catalog = FoodCatalog([_food('chicken_breast'), _food('rice')]);
        final original = SavedMeal.composed(
          id: 'm1',
          name: 'Chicken and rice',
          composition: DerivedTargets.compose([
            LoggedIngredient(
              foodId: 'chicken_breast',
              quantity: FoodQuantity(grams: 120),
            ),
            LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 80)),
          ], catalog),
          createdAt: DateTime.utc(2026, 8, 1),
        );
        await source.saveMeal(original);

        final edited = SavedMeal.composed(
          id: 'm1',
          name: 'Chicken and rice',
          composition: DerivedTargets.compose([
            LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 90)),
            LoggedIngredient(
              foodId: 'chicken_breast',
              quantity: FoodQuantity(grams: 130),
            ),
          ], catalog),
          createdAt: DateTime.utc(2026, 8, 1),
        );
        await source.saveMeal(edited);

        final result = await source.listSavedMeals();
        final loaded =
            (result as Ok<List<SavedMeal>, NutritionFailure>).value.single;

        expect(loaded.ingredients.length, 2);
        expect(
          loaded.ingredients.map((i) => i.foodId).toList(),
          ['rice', 'chicken_breast'],
        );
        expect(loaded.target, edited.target);
      },
    );

    test('deleteSavedMeal cascades to remove its ingredient rows', () async {
      final catalog = FoodCatalog([_food('chicken_breast')]);
      final meal = SavedMeal.composed(
        id: 'm1',
        name: 'Chicken bowl',
        composition: DerivedTargets.compose([
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 150),
          ),
        ], catalog),
        createdAt: DateTime.utc(2026, 8, 1),
      );
      await source.saveMeal(meal);

      await source.deleteSavedMeal('m1');

      final remainingIngredients = await db.select(db.savedMealIngredients).get();
      expect(remainingIngredients, isEmpty);
    });

    test(
      "editing a saved meal's composition does not mutate a previously "
      'logged NutritionEntry built from it (snapshot semantics)',
      () async {
        final catalog = FoodCatalog([_food('chicken_breast'), _food('rice')]);
        final originalComposition = DerivedTargets.compose([
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 120),
          ),
        ], catalog);
        final meal = SavedMeal.composed(
          id: 'm1',
          name: 'Chicken bowl',
          composition: originalComposition,
          createdAt: DateTime.utc(2026, 8, 1),
        );
        await source.saveMeal(meal);

        final nutritionSource = SqlNutritionSource(db);
        final loggedEntry = NutritionEntry.composed(
          id: 'entry-1',
          recordedAt: DateTime(2026, 8, 1, 12),
          composition: originalComposition,
        );
        await nutritionSource.record(loggedEntry);

        final editedMeal = SavedMeal.composed(
          id: 'm1',
          name: 'Chicken bowl',
          composition: DerivedTargets.compose([
            LoggedIngredient(
              foodId: 'chicken_breast',
              quantity: FoodQuantity(grams: 120),
            ),
            LoggedIngredient(
              foodId: 'rice',
              quantity: FoodQuantity(grams: 100),
            ),
          ], catalog),
          createdAt: DateTime.utc(2026, 8, 1),
        );
        await source.saveMeal(editedMeal);

        final entriesResult = await nutritionSource.entriesOn(
          NutritionDay.fromDateTime(loggedEntry.recordedAt),
        );
        final stillLoggedEntry =
            (entriesResult as Ok<List<NutritionEntry>, NutritionFailure>)
                .value
                .single;

        expect(stillLoggedEntry.energy, loggedEntry.energy);
        expect(stillLoggedEntry.macros, loggedEntry.macros);
        expect(stillLoggedEntry.ingredients, loggedEntry.ingredients);
      },
    );

    test(
      'round-trip consistency: a saved meal\'s stored flat target matches '
      'DerivedTargets.compose of its stored ingredient rows',
      () async {
        final catalog = FoodCatalog([_food('chicken_breast'), _food('rice')]);
        final ingredients = [
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 130),
          ),
          LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 70)),
        ];
        final meal = SavedMeal.composed(
          id: 'm1',
          name: 'Chicken and rice',
          composition: DerivedTargets.compose(ingredients, catalog),
          createdAt: DateTime.utc(2026, 8, 1),
        );
        await source.saveMeal(meal);

        final result = await source.listSavedMeals();
        final loaded =
            (result as Ok<List<SavedMeal>, NutritionFailure>).value.single;
        final recomposed = DerivedTargets.compose(
          loaded.ingredients,
          catalog,
        ).target;

        expect(
          loaded.target.equalsWithinTolerance(recomposed, tolerance: 0.01),
          isTrue,
        );
      },
    );
  });
}
