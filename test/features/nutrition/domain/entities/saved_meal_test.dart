import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
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

void main() {
  group('SavedMeal', () {
    test('creates with a valid name, target, and no note', () {
      final createdAt = DateTime.utc(2026, 8, 1);
      final meal = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        createdAt: createdAt,
      );

      expect(meal.id, 'meal-1');
      expect(meal.name, 'Chicken salad');
      expect(meal.target, _target());
      expect(meal.portionNote, isNull);
      expect(meal.createdAt, createdAt);
      expect(meal.ingredients, isEmpty);
    });

    test('ingredients list is unmodifiable', () {
      final meal = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        createdAt: DateTime.utc(2026, 8, 1),
        ingredients: [
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 150),
          ),
        ],
      );

      expect(
        () => meal.ingredients.add(
          LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 100)),
        ),
        throwsUnsupportedError,
      );
    });

    test('two meals with the same ingredients, in the same order, are '
        'equal', () {
      final ingredients = [
        LoggedIngredient(
          foodId: 'chicken_breast',
          quantity: FoodQuantity(grams: 150),
        ),
      ];
      final a = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        createdAt: DateTime.utc(2026, 8, 1),
        ingredients: ingredients,
      );
      final b = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        createdAt: DateTime.utc(2026, 8, 1),
        ingredients: ingredients,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('meals differing only by ingredients are not equal', () {
      final a = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        createdAt: DateTime.utc(2026, 8, 1),
        ingredients: [
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 150),
          ),
        ],
      );
      final b = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        createdAt: DateTime.utc(2026, 8, 1),
      );

      expect(a == b, isFalse);
    });

    test('creates with an optional portionNote', () {
      final meal = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        portionNote: '200g grilled breast + greens',
        createdAt: DateTime.utc(2026, 8, 1),
      );

      expect(meal.portionNote, '200g grilled breast + greens');
    });

    test('throws ArgumentError.value for a blank name', () {
      expect(
        () => SavedMeal(
          id: 'meal-1',
          name: '',
          target: _target(),
          createdAt: DateTime.utc(2026, 8, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError.value for a whitespace-only name', () {
      expect(
        () => SavedMeal(
          id: 'meal-1',
          name: '   ',
          target: _target(),
          createdAt: DateTime.utc(2026, 8, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('normalizedName trims surrounding whitespace and folds case', () {
      final meal = SavedMeal(
        id: 'meal-1',
        name: '  Chicken SALAD  ',
        target: _target(),
        createdAt: DateTime.utc(2026, 8, 1),
      );

      expect(meal.normalizedName, 'chicken salad');
    });

    test('two meals with the same fields are equal', () {
      final createdAt = DateTime.utc(2026, 8, 1);
      final a = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        portionNote: 'note',
        createdAt: createdAt,
      );
      final b = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        portionNote: 'note',
        createdAt: createdAt,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('meals differing only by id are not equal', () {
      final createdAt = DateTime.utc(2026, 8, 1);
      final a = SavedMeal(
        id: 'meal-1',
        name: 'Chicken salad',
        target: _target(),
        createdAt: createdAt,
      );
      final b = SavedMeal(
        id: 'meal-2',
        name: 'Chicken salad',
        target: _target(),
        createdAt: createdAt,
      );

      expect(a == b, isFalse);
    });

    test(
      'SavedMeal.composed writes target matching the composition target, '
      "and carries the composition's ingredients",
      () {
        final catalog = FoodCatalog([
          FoodItem(
            id: 'chicken_breast',
            name: 'Chicken breast',
            preparation: FoodPreparation.grilled,
            per100g: NutritionTarget(
              energy: Energy(kcal: 200),
              macros: Macros(proteinG: 30, carbsG: 0, fatG: 5),
            ),
            source: FoodDataSource.usdaSrLegacy,
          ),
        ]);
        final ingredients = [
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 150),
          ),
        ];
        final composition = DerivedTargets.compose(ingredients, catalog);

        final meal = SavedMeal.composed(
          id: 'meal-1',
          name: 'Grilled chicken',
          composition: composition,
          createdAt: DateTime.utc(2026, 8, 1),
        );

        expect(meal.target, composition.target);
        expect(meal.ingredients, ingredients);
      },
    );
  });
}
