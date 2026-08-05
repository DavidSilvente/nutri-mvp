import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('NutritionEntry', () {
    test('builds successfully without any water field', () {
      final entry = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24, 8, 30),
        energy: Energy(kcal: 500),
        macros: Macros(proteinG: 30, carbsG: 50, fatG: 15),
      );

      expect(entry.id, 'entry-1');
      expect(entry.recordedAt, DateTime(2026, 7, 24, 8, 30));
      expect(entry.energy, Energy(kcal: 500));
      expect(entry.macros, Macros(proteinG: 30, carbsG: 50, fatG: 15));
      expect(entry.ingredients, isEmpty);
    });

    test('ingredients list is unmodifiable', () {
      final entry = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24, 8, 30),
        energy: Energy(kcal: 500),
        macros: Macros(proteinG: 30, carbsG: 50, fatG: 15),
        ingredients: [
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 150),
          ),
        ],
      );

      expect(
        () => entry.ingredients.add(
          LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 100)),
        ),
        throwsUnsupportedError,
      );
    });

    test('two entries with the same ingredients, in the same order, are '
        'equal', () {
      final ingredients = [
        LoggedIngredient(
          foodId: 'chicken_breast',
          quantity: FoodQuantity(grams: 150),
        ),
        LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 100)),
      ];
      final a = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24),
        energy: Energy(kcal: 500),
        macros: Macros(proteinG: 30, carbsG: 50, fatG: 15),
        ingredients: ingredients,
      );
      final b = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24),
        energy: Energy(kcal: 500),
        macros: Macros(proteinG: 30, carbsG: 50, fatG: 15),
        ingredients: ingredients,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('entries differing only by ingredients are not equal', () {
      final a = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24),
        energy: Energy(kcal: 500),
        macros: Macros(proteinG: 30, carbsG: 50, fatG: 15),
        ingredients: [
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 150),
          ),
        ],
      );
      final b = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24),
        energy: Energy(kcal: 500),
        macros: Macros(proteinG: 30, carbsG: 50, fatG: 15),
      );

      expect(a, isNot(b));
    });

    test(
      'withPlannedMeal preserves ingredients — the likeliest bug in this '
      'slice, since the method rebuilds the entity field by field',
      () {
        final entry = NutritionEntry(
          id: 'entry-1',
          recordedAt: DateTime(2026, 7, 24),
          energy: Energy(kcal: 500),
          macros: Macros(proteinG: 30, carbsG: 50, fatG: 15),
          ingredients: [
            LoggedIngredient(
              foodId: 'chicken_breast',
              quantity: FoodQuantity(grams: 150),
            ),
          ],
        );

        final attached = entry.withPlannedMeal('meal-1');
        expect(attached.ingredients, entry.ingredients);
        expect(attached.plannedMealId, 'meal-1');

        final detached = attached.withPlannedMeal(null);
        expect(detached.ingredients, entry.ingredients);
        expect(detached.plannedMealId, isNull);
      },
    );

    test(
      'NutritionEntry.composed writes flat fields matching the composition '
      "target, and carries the composition's ingredients",
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

        final entry = NutritionEntry.composed(
          id: 'entry-1',
          recordedAt: DateTime(2026, 7, 24),
          composition: composition,
        );

        expect(entry.energy, composition.target.energy);
        expect(entry.macros, composition.target.macros);
        expect(entry.ingredients, ingredients);
      },
    );

    test(
      'rejects negative energy by delegating to the Energy value object',
      () {
        expect(
          () => NutritionEntry(
            id: 'entry-1',
            recordedAt: DateTime(2026, 7, 24),
            energy: Energy(kcal: -1),
            macros: Macros(proteinG: 0, carbsG: 0, fatG: 0),
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'rejects negative macros by delegating to the Macros value object',
      () {
        expect(
          () => NutritionEntry(
            id: 'entry-1',
            recordedAt: DateTime(2026, 7, 24),
            energy: Energy(kcal: 0),
            macros: Macros(proteinG: -5, carbsG: 0, fatG: 0),
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('two entries with the same fields are equal', () {
      final a = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24),
        energy: Energy(kcal: 100),
        macros: Macros(proteinG: 10, carbsG: 10, fatG: 10),
      );
      final b = NutritionEntry(
        id: 'entry-1',
        recordedAt: DateTime(2026, 7, 24),
        energy: Energy(kcal: 100),
        macros: Macros(proteinG: 10, carbsG: 10, fatG: 10),
      );

      expect(a, b);
    });
  });
}
