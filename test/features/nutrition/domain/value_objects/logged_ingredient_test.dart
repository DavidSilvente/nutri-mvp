import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';

void main() {
  group('LoggedIngredient', () {
    test('builds with a foodId and a quantity', () {
      final quantity = FoodQuantity(grams: 150);
      final ingredient = LoggedIngredient(foodId: 'chicken_breast', quantity: quantity);

      expect(ingredient.foodId, 'chicken_breast');
      expect(ingredient.quantity, quantity);
    });

    test('throws ArgumentError.value for an empty foodId', () {
      expect(
        () => LoggedIngredient(foodId: '', quantity: FoodQuantity(grams: 100)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError.value for a whitespace-only foodId', () {
      expect(
        () => LoggedIngredient(foodId: '   ', quantity: FoodQuantity(grams: 100)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('two ingredients with the same fields are equal', () {
      final a = LoggedIngredient(
        foodId: 'chicken_breast',
        quantity: FoodQuantity(grams: 150),
      );
      final b = LoggedIngredient(
        foodId: 'chicken_breast',
        quantity: FoodQuantity(grams: 150),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('ingredients differing only by quantity are not equal', () {
      final a = LoggedIngredient(
        foodId: 'chicken_breast',
        quantity: FoodQuantity(grams: 150),
      );
      final b = LoggedIngredient(
        foodId: 'chicken_breast',
        quantity: FoodQuantity(grams: 200),
      );

      expect(a, isNot(b));
    });

    test('ingredients differing only by foodId are not equal', () {
      final a = LoggedIngredient(
        foodId: 'chicken_breast',
        quantity: FoodQuantity(grams: 150),
      );
      final b = LoggedIngredient(
        foodId: 'tofu',
        quantity: FoodQuantity(grams: 150),
      );

      expect(a, isNot(b));
    });

    test('does not carry an id, rawText, or position field', () {
      // LoggedIngredient deliberately drops the three ComponentOption fields
      // that don't apply to user-logged data: no id (nothing references an
      // ingredient), no rawText (the user picked the row — FoodItem.name is
      // the wording), no position (list order already carries it).
      final ingredient = LoggedIngredient(
        foodId: 'chicken_breast',
        quantity: FoodQuantity(grams: 150),
      );

      expect(
        ingredient.toString(),
        'LoggedIngredient(foodId: chicken_breast, quantity: FoodQuantity(grams: 150, count: null, unit: null))',
      );
    });
  });
}
