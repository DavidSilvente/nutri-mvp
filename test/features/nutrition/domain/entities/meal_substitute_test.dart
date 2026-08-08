import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('MealSubstitute', () {
    final target = NutritionTarget(
      energy: Energy(kcal: 250),
      macros: Macros(proteinG: 20, carbsG: 30, fatG: 10),
    );

    test('builds a substitute scoped to a planned meal', () {
      final substitute = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-1',
        label: 'Tofu (200g)',
        target: target,
      );

      expect(substitute.id, 'sub-1');
      expect(substitute.plannedMealId, 'meal-1');
      expect(substitute.label, 'Tofu (200g)');
      expect(substitute.target, target);
      expect(substitute.ingredients, isEmpty);
    });

    test('ingredients list is unmodifiable', () {
      final substitute = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-1',
        label: 'Tofu (200g)',
        target: target,
        ingredients: [
          LoggedIngredient(foodId: 'tofu', quantity: FoodQuantity(grams: 200)),
        ],
      );

      expect(
        () => substitute.ingredients.add(
          LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 100)),
        ),
        throwsUnsupportedError,
      );
    });

    test('ingredients participate in equality element-wise', () {
      MealSubstitute substitute(List<LoggedIngredient> ingredients) =>
          MealSubstitute(
            id: 'sub-1',
            plannedMealId: 'meal-1',
            label: 'Tofu (200g)',
            target: target,
            ingredients: ingredients,
          );
      final ingredients = [
        LoggedIngredient(foodId: 'tofu', quantity: FoodQuantity(grams: 200)),
      ];

      final a = substitute(ingredients);
      final b = substitute(ingredients);
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      final c = substitute(const []);
      expect(a, isNot(c));
    });

    test('rejects an empty label', () {
      expect(
        () => MealSubstitute(
          id: 'sub-1',
          plannedMealId: 'meal-1',
          label: '',
          target: target,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('two substitutes with the same fields are equal', () {
      final a = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-1',
        label: 'Tofu (200g)',
        target: target,
      );
      final b = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-1',
        label: 'Tofu (200g)',
        target: target,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('substitutes with different planned meal ids are not equal', () {
      final a = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-1',
        label: 'Tofu (200g)',
        target: target,
      );
      final b = MealSubstitute(
        id: 'sub-1',
        plannedMealId: 'meal-2',
        label: 'Tofu (200g)',
        target: target,
      );

      expect(a, isNot(b));
    });

    test(
      'MealSubstitute.composed writes target matching the composition '
      "target, and carries the composition's ingredients",
      () {
        final catalog = FoodCatalog([
          FoodItem(
            id: 'tofu',
            name: 'Tofu',
            preparation: FoodPreparation.raw,
            per100g: NutritionTarget(
              energy: Energy(kcal: 80),
              macros: Macros(proteinG: 8, carbsG: 2, fatG: 4),
            ),
            source: FoodDataSource.usdaSrLegacy,
          ),
        ]);
        final ingredients = [
          LoggedIngredient(foodId: 'tofu', quantity: FoodQuantity(grams: 200)),
        ];
        final composition = DerivedTargets.compose(ingredients, catalog);

        final substitute = MealSubstitute.composed(
          id: 'sub-1',
          plannedMealId: 'meal-1',
          label: 'Tofu (200g)',
          composition: composition,
        );

        expect(substitute.target, composition.target);
        expect(substitute.ingredients, ingredients);
      },
    );
  });
}
