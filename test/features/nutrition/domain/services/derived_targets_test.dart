import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_component.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';

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
}
