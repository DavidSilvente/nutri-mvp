import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
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
import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_hydration_source.dart';
import '../../_fakes/fake_nutrition_source.dart';
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
  final today = day;

  late FakeDietPlanSource dietSource;
  late FakeNutritionSource nutritionSource;
  late FakeSavedMealSource savedMealSource;

  setUp(() async {
    dietSource = FakeDietPlanSource();
    nutritionSource = FakeNutritionSource();
    savedMealSource = FakeSavedMealSource();

    final slots = [
      DietMealSlot(id: 'slot-1', label: 'Lunch', position: 0, target: target()),
    ];
    await dietSource.saveTemplate(
      DietTemplate(
        id: 't1',
        name: 'Plan',
        dailyTarget: NutritionTarget.sum(slots.map((s) => s.target)),
        slots: slots,
      ),
    );
    await dietSource.savePlannedMeal(
      PlannedMeal(
        id: 'pm-1',
        slotId: 'slot-1',
        day: day,
        targetSnapshot: target(),
      ),
    );
  });

  Future<void> addSubstitute({
    required String id,
    required String label,
    required NutritionTarget substituteTarget,
  }) {
    return dietSource.saveSubstitute(
      MealSubstitute(
        id: id,
        plannedMealId: 'pm-1',
        label: label,
        target: substituteTarget,
      ),
    );
  }

  Future<void> addSavedMeal({
    required String id,
    required String name,
    required NutritionTarget mealTarget,
  }) {
    return savedMealSource.saveMeal(
      SavedMeal(
        id: id,
        name: name,
        target: mealTarget,
        createdAt: DateTime.utc(2026, 8, 1),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      DayPlanScreen(day: day),
      overrides: [
        nutritionSourceProvider.overrideWithValue(nutritionSource),
        dietPlanSourceProvider.overrideWithValue(dietSource),
        hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
        savedMealSourceProvider.overrideWithValue(savedMealSource),
        todayProvider.overrideWithValue(today),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alternativesButton-pm-1')));
    await tester.pumpAndSettle();
  }

  group('MealAlternativesSheet', () {
    testWidgets('explains the empty state when no alternatives exist', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.text('No alternatives yet'), findsOneWidget);
      expect(find.byKey(const Key('addAlternativeButton')), findsOneWidget);
    });

    testWidgets('ranks alternatives by macro distance, closest first', (
      tester,
    ) async {
      // Far: every macro is well away from the 40/60/20 target.
      await addSubstitute(
        id: 'far',
        label: 'Pizza',
        substituteTarget: target(kcal: 900, protein: 20, carbs: 110, fat: 45),
      );
      // Near: a couple of grams off.
      await addSubstitute(
        id: 'near',
        label: 'Chicken and rice',
        substituteTarget: target(kcal: 610, protein: 42, carbs: 58, fat: 21),
      );

      await openSheet(tester);

      expect(find.text('Closest match'), findsOneWidget);

      final nearY = tester.getTopLeft(find.text('Chicken and rice')).dy;
      final farY = tester.getTopLeft(find.text('Pizza')).dy;
      expect(nearY, lessThan(farY));
    });

    testWidgets('picking an alternative pre-fills the log with its macros', (
      tester,
    ) async {
      await addSubstitute(
        id: 'near',
        label: 'Chicken and rice',
        substituteTarget: target(kcal: 610, protein: 42, carbs: 58, fat: 21),
      );

      await openSheet(tester);
      await tester.tap(find.byKey(const Key('pickAlternativeButton-near')));
      await tester.pumpAndSettle();

      expect(find.byType(RecordIntakeScreen), findsOneWidget);
      // The substitute's own macros, not the planned meal's target.
      final energyField = tester.widget<TextFormField>(
        find.byKey(const Key('energyField')),
      );
      expect(energyField.controller?.text, '610');
      // And it still counts towards the meal it replaces.
      expect(find.text('Counts towards Lunch'), findsOneWidget);
    });

    testWidgets('a logged alternative still meets the planned meal', (
      tester,
    ) async {
      await addSubstitute(
        id: 'near',
        label: 'Chicken and rice',
        substituteTarget: target(kcal: 610, protein: 42, carbs: 58, fat: 21),
      );

      await openSheet(tester);
      await tester.tap(find.byKey(const Key('pickAlternativeButton-near')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      // Swapping the meal is not a miss: the macros still land in tolerance.
      expect(find.text('On target'), findsOneWidget);
    });

    testWidgets('adds a new alternative and lists it', (tester) async {
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('addAlternativeButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('alternativeLabelField')),
        'Tuna salad',
      );
      await tester.enterText(
        find.byKey(const Key('alternativeEnergyField')),
        '580',
      );
      await tester.enterText(
        find.byKey(const Key('alternativeProteinField')),
        '45',
      );
      await tester.enterText(
        find.byKey(const Key('alternativeCarbsField')),
        '55',
      );
      await tester.enterText(
        find.byKey(const Key('alternativeFatField')),
        '18',
      );
      await tester.tap(find.byKey(const Key('saveAlternativeButton')));
      await tester.pumpAndSettle();

      final saved = await dietSource.listSubstitutes('pm-1');
      expect(saved.toString(), contains('Tuna salad'));
    });

    testWidgets(
      'groups plan substitutes and saved meals separately, plan group first',
      (tester) async {
        await addSubstitute(
          id: 'sub-1',
          label: 'Chicken and rice',
          substituteTarget: target(kcal: 610, protein: 42, carbs: 58, fat: 21),
        );
        await addSavedMeal(
          id: 'm1',
          name: 'Tuna bowl',
          mealTarget: target(kcal: 580, protein: 41, carbs: 59, fat: 20),
        );

        await openSheet(tester);

        expect(find.text('From your plan'), findsOneWidget);
        expect(find.text('From your meals'), findsOneWidget);
        expect(find.text('Chicken and rice'), findsOneWidget);
        expect(find.text('Tuna bowl'), findsOneWidget);

        final planHeaderY = tester.getTopLeft(find.text('From your plan')).dy;
        final savedHeaderY = tester
            .getTopLeft(find.text('From your meals'))
            .dy;
        expect(planHeaderY, lessThan(savedHeaderY));
      },
    );

    testWidgets(
      'an empty saved-meal catalogue hides the saved group and shows a '
      'call-to-action instead, leaving plan substitutes working',
      (tester) async {
        await addSubstitute(
          id: 'sub-1',
          label: 'Chicken and rice',
          substituteTarget: target(kcal: 610, protein: 42, carbs: 58, fat: 21),
        );

        await openSheet(tester);

        expect(find.text('From your plan'), findsOneWidget);
        expect(find.text('From your meals'), findsNothing);
        expect(find.byKey(const Key('noSavedMealsCta')), findsOneWidget);
        expect(
          find.byKey(const Key('pickAlternativeButton-sub-1')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'an off-target saved meal is still shown, labelled with its gram '
      'deltas, and stays pickable',
      (tester) async {
        // Target protein is 40 g; 10% of that is 4 g, so an 11 g delta
        // breaches the tighter protein tolerance even though carbs and fat
        // stay exactly on target.
        await addSavedMeal(
          id: 'm1',
          name: 'Protein shake',
          mealTarget: target(kcal: 600, protein: 51, carbs: 60, fat: 20),
        );

        await openSheet(tester);

        expect(find.text('Protein shake'), findsOneWidget);
        expect(find.textContaining('Off target'), findsOneWidget);
        expect(find.textContaining('+11'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('pickAlternativeButton-saved:m1')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RecordIntakeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'picking a saved meal pre-fills the log with its macros and still '
      'counts towards the planned meal',
      (tester) async {
        await addSavedMeal(
          id: 'm1',
          name: 'Tuna bowl',
          mealTarget: target(kcal: 580, protein: 41, carbs: 59, fat: 20),
        );

        await openSheet(tester);
        await tester.tap(
          find.byKey(const Key('pickAlternativeButton-saved:m1')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RecordIntakeScreen), findsOneWidget);
        final energyField = tester.widget<TextFormField>(
          find.byKey(const Key('energyField')),
        );
        expect(energyField.controller?.text, '580');
        expect(find.text('Counts towards Lunch'), findsOneWidget);
      },
    );
  });
}
