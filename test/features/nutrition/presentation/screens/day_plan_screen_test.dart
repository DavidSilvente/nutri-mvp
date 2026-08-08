import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_component.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/day_plan_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/record_intake_screen.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/diet_fixture.dart';
import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_hydration_source.dart';
import '../../_fakes/fake_nutrition_source.dart';
import '../../_fakes/fake_option_choice_source.dart';
import '../../_fakes/fake_saved_meal_source.dart';

NutritionTarget target({
  num kcal = 600,
  num protein = 40,
  num carbs = 60,
  num fat = 20,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
  );
}

void main() {
  final day = NutritionDay.fromDateTime(DateTime(2026, 7, 24));
  // Pinned one day after [day], so the day under test is settled and its
  // status is judged rather than left "in progress".
  final today = NutritionDay.fromDateTime(DateTime(2026, 7, 25));

  late FakeDietPlanSource dietSource;
  late FakeMealSlotDirectory slotDirectory;
  late FakeNutritionSource nutritionSource;
  late FakeOptionChoiceSource choiceSource;

  setUp(() {
    dietSource = FakeDietPlanSource();
    nutritionSource = FakeNutritionSource();
    slotDirectory = FakeMealSlotDirectory();
    choiceSource = FakeOptionChoiceSource();
  });

  /// Gives the active diet its meals, which is what turns a planned meal's
  /// slot id back into a label and a position.
  void saveTemplate() {
    slotDirectory.slots.addAll([
      mealSlot(id: 'slot-breakfast', label: 'Breakfast', position: 0),
      mealSlot(id: 'slot-dinner', label: 'Dinner', position: 1),
    ]);
  }

  Future<void> plan(String id, String slotId) {
    return dietSource.savePlannedMeal(
      PlannedMeal(id: id, slotId: slotId, day: day, targetSnapshot: target()),
    );
  }

  Future<void> log({
    required String id,
    String? plannedMealId,
    num kcal = 600,
    num protein = 40,
    num carbs = 60,
    num fat = 20,
  }) {
    return nutritionSource.record(
      NutritionEntry(
        id: id,
        recordedAt: DateTime(2026, 7, 24, 13),
        energy: Energy(kcal: kcal),
        macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
        plannedMealId: plannedMealId,
      ),
    );
  }

  /// A single-option component whose [rawText] is the plan's verbatim wording
  /// — the exact text the card must show as its primary content.
  MealComponent component({
    required String id,
    int position = 0,
    String? sectionLabel,
    required String rawText,
  }) {
    return MealComponent(
      id: id,
      position: position,
      sectionLabel: sectionLabel,
      options: [
        ComponentOption(
          id: '$id-option',
          foodId: '$id-food',
          quantity: FoodQuantity(grams: 100),
          rawText: rawText,
        ),
      ],
    );
  }

  /// The day view stacks several tall cards, so the default 800x600 test
  /// surface would push most of them out of the viewport and out of the
  /// widget tree. A tall surface keeps the assertions about content, not
  /// about scrolling.
  Future<void> pumpScreen(
    WidgetTester tester, {
    FakeSavedMealSource? savedMealSource,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1000, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      DayPlanScreen(day: day),
      overrides: [
        nutritionSourceProvider.overrideWithValue(nutritionSource),
        dietPlanSourceProvider.overrideWithValue(dietSource),
        mealSlotDirectoryProvider.overrideWithValue(slotDirectory),
        optionChoiceSourceProvider.overrideWithValue(choiceSource),
        hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
        todayProvider.overrideWithValue(today),
        savedMealSourceProvider.overrideWithValue(
          savedMealSource ?? FakeSavedMealSource(),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('DayPlanScreen', () {
    testWidgets('offers to apply a diet when the day has no plan', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('No meals planned'), findsOneWidget);
      expect(find.byKey(const Key('applyDietButton')), findsOneWidget);
    });

    testWidgets('lists planned meals in slot order with their labels', (
      tester,
    ) async {
      saveTemplate();
      await plan('pm-dinner', 'slot-dinner');
      await plan('pm-breakfast', 'slot-breakfast');

      await pumpScreen(tester);

      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);

      final breakfastY = tester.getTopLeft(find.text('Breakfast')).dy;
      final dinnerY = tester.getTopLeft(find.text('Dinner')).dy;
      expect(breakfastY, lessThan(dinnerY));
    });

    testWidgets('shows a met meal as on target and an empty one as pending', (
      tester,
    ) async {
      saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await plan('pm-dinner', 'slot-dinner');
      await log(id: 'e1', plannedMealId: 'pm-breakfast');

      await pumpScreen(tester);

      expect(find.text('On target'), findsOneWidget);
      expect(find.text('Not logged'), findsOneWidget);
      expect(find.text('1/2 meals'), findsOneWidget);
    });

    testWidgets(
      'shows the day chip as under when the logged total falls short',
      (tester) async {
        saveTemplate();
        await plan('pm-breakfast', 'slot-breakfast');
        await plan('pm-dinner', 'slot-dinner');
        await log(id: 'e1', plannedMealId: 'pm-breakfast');

        await pumpScreen(tester);

        expect(find.text('Under'), findsOneWidget);
      },
    );

    testWidgets('logging a planned meal pre-fills the form with its target', (
      tester,
    ) async {
      saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');

      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('logMealButton-pm-breakfast')));
      await tester.pumpAndSettle();

      expect(find.byType(RecordIntakeScreen), findsOneWidget);
      expect(find.text('Log Breakfast'), findsOneWidget);

      final energyField = tester.widget<TextFormField>(
        find.byKey(const Key('energyField')),
      );
      expect(energyField.controller?.text, '600');
    });

    testWidgets('an intake logged against a meal counts towards it', (
      tester,
    ) async {
      saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');

      await pumpScreen(tester);

      expect(find.text('Not logged'), findsOneWidget);

      await tester.tap(find.byKey(const Key('logMealButton-pm-breakfast')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      // Back on the day, the pre-filled target was accepted as met.
      expect(find.text('On target'), findsOneWidget);
      expect(find.text('Not logged'), findsNothing);
    });

    testWidgets('separates off-plan intake from the plan', (tester) async {
      saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await log(id: 'snack', kcal: 210, protein: 5, carbs: 25, fat: 8);

      await pumpScreen(tester);

      expect(find.text('Extras'), findsOneWidget);
      expect(find.text('210 kcal'), findsOneWidget);
    });

    testWidgets('saving an unplanned entry as a meal copies its macros without '
        'changing the entry', (tester) async {
      final savedMealSource = FakeSavedMealSource();
      await log(id: 'snack', kcal: 210, protein: 5, carbs: 25, fat: 8);

      await pumpScreen(tester, savedMealSource: savedMealSource);

      await tester.tap(find.byKey(const Key('saveEntryAsMealButton-snack')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('saveEntryAsMealNameField')),
        'Afternoon snack',
      );
      await tester.tap(find.byKey(const Key('confirmSaveEntryAsMealButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saveEntryAsMealNameField')), findsNothing);

      final listResult = await savedMealSource.listSavedMeals();
      final meals = (listResult as Ok<List<SavedMeal>, NutritionFailure>).value;
      expect(meals, hasLength(1));
      expect(meals.single.name, 'Afternoon snack');
      expect(meals.single.target.energy.kcal, 210);

      final entriesResult = await nutritionSource.entriesOn(day);
      final entries =
          (entriesResult as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries.single.energy.kcal, 210);
      expect(entries.single.plannedMealId, isNull);
    });

    testWidgets(
      "saving a planned meal's logged entry as a meal is offered from its "
      'own row and keeps the entry linked to the plan',
      (tester) async {
        final savedMealSource = FakeSavedMealSource();
        saveTemplate();
        await plan('pm-breakfast', 'slot-breakfast');
        await log(id: 'e1', plannedMealId: 'pm-breakfast');

        await pumpScreen(tester, savedMealSource: savedMealSource);

        await tester.tap(find.byKey(const Key('saveEntryAsMealButton-e1')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('saveEntryAsMealNameField')),
          'Usual breakfast',
        );
        await tester.tap(find.byKey(const Key('confirmSaveEntryAsMealButton')));
        await tester.pumpAndSettle();

        final listResult = await savedMealSource.listSavedMeals();
        final meals =
            (listResult as Ok<List<SavedMeal>, NutritionFailure>).value;
        expect(meals.single.name, 'Usual breakfast');

        final entriesResult = await nutritionSource.entriesOn(day);
        final entries =
            (entriesResult as Ok<List<NutritionEntry>, NutritionFailure>).value;
        expect(entries.single.plannedMealId, 'pm-breakfast');
      },
    );

    group('planned meal food', () {
      testWidgets(
        "shows the resolved option's wording as the row's primary content",
        (tester) async {
          slotDirectory.slots.add(
            mealSlot(
              id: 'slot-breakfast',
              label: 'Breakfast',
              position: 0,
              components: [
                component(id: 'component-1', rawText: '2 huevos revueltos'),
              ],
            ),
          );
          await plan('pm-breakfast', 'slot-breakfast');

          await pumpScreen(tester);

          expect(find.text('2 huevos revueltos'), findsOneWidget);
          // Macros stay complete and unchanged — display-only regression.
          expect(find.text('On target'), findsNothing);
          expect(find.text('Not logged'), findsOneWidget);
        },
      );

      testWidgets(
        'renders one row per component of a multi-course meal, grouped by '
        'section, never concatenated into one string',
        (tester) async {
          slotDirectory.slots.add(
            mealSlot(
              id: 'slot-lunch',
              label: 'Lunch',
              position: 0,
              components: [
                component(
                  id: 'c1',
                  position: 0,
                  sectionLabel: 'PRIMER PLATO',
                  rawText: 'Sopa de verduras',
                ),
                component(
                  id: 'c2',
                  position: 1,
                  sectionLabel: 'SEGUNDO PLATO',
                  rawText: 'Pollo a la plancha',
                ),
                component(
                  id: 'c3',
                  position: 2,
                  sectionLabel: 'POSTRE',
                  rawText: 'Yogur natural',
                ),
              ],
            ),
          );
          await plan('pm-lunch', 'slot-lunch');

          await pumpScreen(tester);

          expect(find.text('Sopa de verduras'), findsOneWidget);
          expect(find.text('Pollo a la plancha'), findsOneWidget);
          expect(find.text('Yogur natural'), findsOneWidget);
          expect(
            find.text('Sopa de verdurasPollo a la planchaYogur natural'),
            findsNothing,
          );
        },
      );

      testWidgets("shows the meal's scheduled time in its header", (
        tester,
      ) async {
        slotDirectory.slots.add(
          mealSlot(
            id: 'slot-breakfast',
            label: 'Breakfast',
            position: 0,
            timeOfDay: '08:00',
            components: [component(id: 'component-1', rawText: 'Oats')],
          ),
        );
        await plan('pm-breakfast', 'slot-breakfast');

        await pumpScreen(tester);

        expect(find.text('08:00'), findsOneWidget);
      });

      testWidgets('collapses notes by default and reveals them on tap', (
        tester,
      ) async {
        slotDirectory.slots.add(
          mealSlot(
            id: 'slot-breakfast',
            label: 'Breakfast',
            position: 0,
            notes: const ['Soak the oats overnight'],
            components: [component(id: 'component-1', rawText: 'Oats')],
          ),
        );
        await plan('pm-breakfast', 'slot-breakfast');

        await pumpScreen(tester);

        expect(find.text('Soak the oats overnight'), findsNothing);

        await tester.tap(find.byKey(const Key('notes-slot-breakfast')));
        await tester.pumpAndSettle();

        expect(find.text('Soak the oats overnight'), findsOneWidget);
      });

      testWidgets('shows no notes section when the meal has none', (
        tester,
      ) async {
        slotDirectory.slots.add(
          mealSlot(
            id: 'slot-breakfast',
            label: 'Breakfast',
            position: 0,
            components: [component(id: 'component-1', rawText: 'Oats')],
          ),
        );
        await plan('pm-breakfast', 'slot-breakfast');

        await pumpScreen(tester);

        expect(find.byKey(const Key('notes-slot-breakfast')), findsNothing);
      });

      testWidgets(
        'degrades to label, kcal and macros when the slot has no components',
        (tester) async {
          saveTemplate();
          await plan('pm-breakfast', 'slot-breakfast');

          await pumpScreen(tester);

          expect(
            find.byKey(const Key('mealFoodList-pm-breakfast')),
            findsNothing,
          );
          expect(find.text('Breakfast'), findsOneWidget);
          expect(find.text('Not logged'), findsOneWidget);
        },
      );

      testWidgets(
        'degrades to label, kcal and macros when the slot no longer exists',
        (tester) async {
          // No template saved at all: the planned meal points at a slot the
          // active diet no longer defines.
          await plan('pm-orphaned', 'slot-deleted');

          await pumpScreen(tester);

          expect(
            find.byKey(const Key('mealFoodList-pm-orphaned')),
            findsNothing,
          );
          expect(find.text('Not logged'), findsOneWidget);
        },
      );

      testWidgets(
        'tapping a component row with alternatives opens the options sheet, '
        'and the per-meal action reads "Swap meal", never the bare word '
        '"Alternatives"',
        (tester) async {
          final componentWithAlternatives = MealComponent(
            id: 'c1',
            position: 0,
            options: [
              ComponentOption(
                id: 'c1-option-a',
                foodId: 'c1-food-a',
                quantity: FoodQuantity(grams: 100),
                rawText: '140 gramos de pollo, pechuga',
              ),
              ComponentOption(
                id: 'c1-option-b',
                foodId: 'c1-food-b',
                quantity: FoodQuantity(grams: 150),
                rawText: '150 gramos de lomo ternera',
              ),
            ],
          );
          slotDirectory.slots.add(
            mealSlot(
              id: 'slot-lunch',
              label: 'Lunch',
              position: 0,
              components: [componentWithAlternatives],
            ),
          );
          await plan('pm-lunch', 'slot-lunch');

          await pumpScreen(tester);

          expect(find.text('Swap meal'), findsOneWidget);
          expect(find.text('Alternatives'), findsNothing);

          await tester.tap(find.byKey(const Key('componentRow-c1')));
          await tester.pumpAndSettle();

          expect(find.text('Options'), findsOneWidget);
        },
      );
    });
  });
}
