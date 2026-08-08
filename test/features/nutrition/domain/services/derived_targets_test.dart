import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_component.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('OptionChoices precedence', () {
    // Three interchangeable options for one component: A is the plan's first
    // choice (the fallback with nothing recorded), B and C are alternatives.
    ComponentOption option(String id) => ComponentOption(
      id: id,
      foodId: 'food-$id',
      quantity: FoodQuantity(grams: 100),
      rawText: 'Option $id',
    );

    final component = MealComponent(
      id: 'component-1',
      position: 0,
      options: [option('a'), option('b'), option('c')],
    );

    test('a day selection alone is chosen', () {
      final choices = OptionChoices.day({'component-1': 'b'});

      expect(DerivedTargets.optionFor(component, choices).id, 'b');
    });

    test('a preference alone is chosen when there is no day selection', () {
      final choices = OptionChoices(preferences: {'component-1': 'c'});

      expect(DerivedTargets.optionFor(component, choices).id, 'c');
    });

    test('a day selection wins over a preference when both are present', () {
      final choices = OptionChoices(
        daySelections: {'component-1': 'b'},
        preferences: {'component-1': 'c'},
      );

      expect(DerivedTargets.optionFor(component, choices).id, 'b');
    });

    test("the plan's first option is chosen when neither is present", () {
      expect(
        DerivedTargets.optionFor(component, const OptionChoices.none()).id,
        'a',
      );
    });

    test('a day selection naming an unknown option id falls through to the '
        'preference', () {
      final choices = OptionChoices(
        daySelections: {'component-1': 'not-an-option'},
        preferences: {'component-1': 'c'},
      );

      expect(DerivedTargets.optionFor(component, choices).id, 'c');
    });

    test("a preference naming an unknown option id falls through to the plan's "
        'first option, with no day selection present', () {
      final choices = OptionChoices(
        preferences: {'component-1': 'not-an-option'},
      );

      expect(DerivedTargets.optionFor(component, choices).id, 'a');
    });
  });

  group('DerivedTargets.compose', () {
    FoodItem food(String id) => FoodItem(
      id: id,
      name: 'Food $id',
      preparation: FoodPreparation.raw,
      per100g: NutritionTarget(
        energy: Energy(kcal: 200),
        macros: Macros(proteinG: 20, carbsG: 10, fatG: 5),
      ),
      source: FoodDataSource.usdaSrLegacy,
    );

    final catalog = FoodCatalog([food('chicken_breast'), food('rice')]);

    test('sums resolvable ingredients', () {
      final ingredients = [
        LoggedIngredient(
          foodId: 'chicken_breast',
          quantity: FoodQuantity(grams: 150),
        ),
        LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 100)),
      ];

      final composition = DerivedTargets.compose(ingredients, catalog);

      // chicken_breast: 150g @ 200kcal/100g = 300 kcal, 30/15/7.5
      // rice: 100g @ 200kcal/100g = 200 kcal, 20/10/5
      expect(composition.target.energy.kcal, 500);
      expect(composition.target.macros.proteinG, 50);
      expect(composition.target.macros.carbsG, 25);
      expect(composition.target.macros.fatG, 12.5);
      expect(composition.unresolvedFoodIds, isEmpty);
      expect(composition.ingredients, ingredients);
    });

    test('an empty ingredient list yields a zero target', () {
      final composition = DerivedTargets.compose([], catalog);

      expect(composition.target.energy.kcal, 0);
      expect(composition.target.macros.proteinG, 0);
      expect(composition.target.macros.carbsG, 0);
      expect(composition.target.macros.fatG, 0);
      expect(composition.unresolvedFoodIds, isEmpty);
      expect(composition.ingredients, isEmpty);
    });

    test(
      'an unresolved foodId contributes zero, is reported in '
      'unresolvedFoodIds, and survives verbatim in ingredients — never '
      'dropped and never an Err',
      () {
        final resolvable = LoggedIngredient(
          foodId: 'rice',
          quantity: FoodQuantity(grams: 100),
        );
        final unresolvable = LoggedIngredient(
          foodId: 'discontinued_food',
          quantity: FoodQuantity(grams: 50),
        );

        final composition = DerivedTargets.compose(
          [resolvable, unresolvable],
          catalog,
        );

        // Only rice's 200 kcal / 20 / 10 / 5 contributes; the unresolved
        // ingredient contributes zero.
        expect(composition.target.energy.kcal, 200);
        expect(composition.target.macros.proteinG, 20);
        expect(composition.unresolvedFoodIds, {'discontinued_food'});
        expect(composition.ingredients, [resolvable, unresolvable]);
        // compose's return type is DerivedComposition, not
        // Result<DerivedComposition, NutritionFailure> — there is no Err
        // path, unlike forComponent/forComponents.
        expect(composition, isA<DerivedComposition>());
      },
    );
  });
}
