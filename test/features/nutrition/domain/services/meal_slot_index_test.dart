import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_component.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/meal_slot_index.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  NutritionTarget target({num kcal = 100}) => NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: 1, carbsG: 1, fatG: 1),
  );

  FoodItem food(String id, {bool needsReview = false}) => FoodItem(
    id: id,
    name: 'Food $id',
    preparation: FoodPreparation.raw,
    per100g: target(),
    source: needsReview
        ? FoodDataSource.estimated
        : FoodDataSource.usdaSrLegacy,
  );

  ComponentOption option(String id, String foodId) => ComponentOption(
    id: id,
    foodId: foodId,
    quantity: FoodQuantity(grams: 100),
    rawText: 'Option $id',
  );

  group('MealSlotIndex.fromPlan', () {
    test('carries components, timeOfDay and notes onto MealSlotInfo', () {
      final component = MealComponent(
        id: 'component-1',
        position: 0,
        options: [option('o1', 'food-a')],
      );
      final slot = DietMealSlot(
        id: 'slot-1',
        label: 'Breakfast',
        position: 0,
        target: target(),
        timeOfDay: '08:00',
        components: [component],
        notes: ['Soak the oats overnight'],
      );
      final plan = _planWith(slot);
      final catalog = FoodCatalog([food('food-a')]);

      final index = MealSlotIndex.fromPlan(plan, catalog);

      final info = index['slot-1']!;
      expect(info.components, [component]);
      expect(info.timeOfDay, '08:00');
      expect(info.notes, ['Soak the oats overnight']);
    });

    test('collects the ids of every food that needs review, plan-wide', () {
      final reviewedComponent = MealComponent(
        id: 'component-reviewed',
        position: 0,
        options: [option('o1', 'food-known'), option('o2', 'food-estimated')],
      );
      final okComponent = MealComponent(
        id: 'component-ok',
        position: 1,
        options: [option('o3', 'food-known')],
      );
      final slot = DietMealSlot(
        id: 'slot-1',
        label: 'Lunch',
        position: 0,
        target: target(),
        components: [reviewedComponent, okComponent],
      );
      final plan = _planWith(slot);
      final catalog = FoodCatalog([
        food('food-known'),
        food('food-estimated', needsReview: true),
      ]);

      final index = MealSlotIndex.fromPlan(plan, catalog);

      expect(index.estimatedFoodIds, {'food-estimated'});
    });

    test(
      'does not collect ids from options whose food does not need review',
      () {
        final component = MealComponent(
          id: 'component-1',
          position: 0,
          options: [option('o1', 'food-known')],
        );
        final slot = DietMealSlot(
          id: 'slot-1',
          label: 'Dinner',
          position: 0,
          target: target(),
          components: [component],
        );
        final plan = _planWith(slot);
        final catalog = FoodCatalog([food('food-known')]);

        final index = MealSlotIndex.fromPlan(plan, catalog);

        expect(index.estimatedFoodIds, isEmpty);
      },
    );
  });

  group('MealSlotIndex.empty', () {
    test('carries no slots and no estimated foods', () {
      final index = MealSlotIndex.empty();

      expect(index.isEmpty, isTrue);
      expect(index.estimatedFoodIds, isEmpty);
      expect(index['anything'], isNull);
    });
  });
}

/// Wraps [slot] in a single day group covering every weekday, the minimum
/// shape [MealSlotIndex.fromPlan] needs.
DietPlan _planWith(DietMealSlot slot) {
  return DietPlan(
    id: 'plan-1',
    name: 'Plan',
    dayGroups: [
      DietPlanDayGroup(
        label: 'EVERY DAY',
        weekdays: {
          for (
            var weekday = DateTime.monday;
            weekday <= DateTime.sunday;
            weekday++
          )
            weekday,
        },
        template: DietTemplate.derived(
          id: 'plan-1:g0',
          name: 'Plan — EVERY DAY',
          slots: [slot],
        ),
      ),
    ],
  );
}
