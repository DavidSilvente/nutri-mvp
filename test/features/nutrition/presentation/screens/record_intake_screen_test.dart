import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/adherence_evaluator.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_day_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/record_intake_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/planned_meal_field.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/diet_fixture.dart';
import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_diet_plan_store.dart';
import '../../_fakes/fake_nutrition_source.dart';
import '../../_fakes/fake_option_choice_source.dart';

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

/// A pending [PlannedMealDetail] with nothing logged yet, for seeding the
/// planned-meal picker.
PlannedMealDetail plannedMealDetail(PlannedMeal meal, String label) {
  return PlannedMealDetail(
    meal: meal,
    label: label,
    position: 0,
    adherence: MealAdherence(
      plannedMeal: meal,
      logged: NutritionTarget.sum(const []),
      entryCount: 0,
      status: MealAdherenceStatus.pending,
    ),
    entries: const [],
  );
}

void main() {
  final today = NutritionDay.fromDateTime(DateTime(2026, 7, 24));

  late FakeNutritionSource nutritionSource;
  late FakeDietPlanSource dietSource;
  late FakeMealSlotDirectory slotDirectory;

  setUp(() {
    nutritionSource = FakeNutritionSource();
    dietSource = FakeDietPlanSource();
    slotDirectory = FakeMealSlotDirectory();
  });

  List<Override> baseOverrides() => [
    nutritionSourceProvider.overrideWithValue(nutritionSource),
    dietPlanSourceProvider.overrideWithValue(dietSource),
    mealSlotDirectoryProvider.overrideWithValue(slotDirectory),
    optionChoiceSourceProvider.overrideWithValue(FakeOptionChoiceSource()),
    foodTableSourceProvider.overrideWithValue(FakeFoodTableSource()),
    todayProvider.overrideWithValue(today),
  ];

  Future<List<NutritionEntry>> loggedEntries(NutritionDay day) async {
    final result = await nutritionSource.entriesOn(day);
    return (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
  }

  /// Taller than the default test surface: the dual-mode form (a `TabBar`
  /// plus either four macro fields or the composition editor) pushes
  /// `submitButton` past the default viewport, and a `ListView`'s Sliver
  /// only builds elements near the viewport — a widget below it is simply
  /// absent from the tree, not merely unpainted. The same pattern is already
  /// used by `meal_alternatives_sheet_test.dart` and `day_plan_screen_test.dart`
  /// for the same reason.
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    required List<Override> overrides,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, child, overrides: overrides);
    await tester.pumpAndSettle();
  }

  group('RecordIntakeScreen', () {
    testWidgets('manual mode submits energy and macros to the fake source', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const RecordIntakeScreen(),
        overrides: baseOverrides(),
      );

      await tester.tap(find.byKey(const Key('manualEntryTab')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('energyField')), '500');
      await tester.enterText(find.byKey(const Key('proteinField')), '30');
      await tester.enterText(find.byKey(const Key('carbsField')), '40');
      await tester.enterText(find.byKey(const Key('fatField')), '10');

      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      final entries = await loggedEntries(
        NutritionDay.fromDateTime(DateTime.now()),
      );

      expect(entries, hasLength(1));
      expect(entries.single.energy.kcal, 500);
      expect(entries.single.macros.proteinG, 30);
      expect(entries.single.macros.carbsG, 40);
      expect(entries.single.macros.fatG, 10);
      expect(entries.single.ingredients, isEmpty);
    });

    testWidgets(
      'food-first mode is the default and derives macros with no typing',
      (tester) async {
        await pumpScreen(
          tester,
          const RecordIntakeScreen(),
          overrides: baseOverrides(),
        );

        // The Macros tab is not the default — its fields do not exist yet.
        expect(find.byKey(const Key('energyField')), findsNothing);

        await tester.tap(find.byKey(const Key('addFoodButton')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('foodSearchField')),
          'pollo',
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('candidateOption-chicken_breast_grilled')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('compositionGramsField-0')),
          '150',
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('submitButton')));
        await tester.pumpAndSettle();

        final entries = await loggedEntries(
          NutritionDay.fromDateTime(DateTime.now()),
        );

        expect(entries, hasLength(1));
        expect(entries.single.ingredients, hasLength(1));
        expect(
          entries.single.ingredients.single.foodId,
          'chicken_breast_grilled',
        );
        // FakeFoodTableSource's default chicken is 151 kcal/100g -> 226.5 at 150g.
        expect(entries.single.energy.kcal, 226.5);
      },
    );

    testWidgets('the manual tab is reachable in one tap from the default', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const RecordIntakeScreen(),
        overrides: baseOverrides(),
      );

      expect(find.byKey(const Key('energyField')), findsNothing);

      await tester.tap(find.byKey(const Key('manualEntryTab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('energyField')), findsOneWidget);
      expect(find.byKey(const Key('proteinField')), findsOneWidget);
      expect(find.byKey(const Key('carbsField')), findsOneWidget);
      expect(find.byKey(const Key('fatField')), findsOneWidget);
    });

    testWidgets(
      'attaches a free-standing entry to a planned meal chosen in-screen',
      (tester) async {
        slotDirectory.slots.add(
          mealSlot(id: 'slot-breakfast', label: 'Breakfast', position: 0),
        );
        await dietSource.savePlannedMeal(
          PlannedMeal(
            id: 'pm-breakfast',
            slotId: 'slot-breakfast',
            day: today,
            targetSnapshot: target(),
          ),
        );

        await pumpScreen(
          tester,
          RecordIntakeScreen(day: today),
          overrides: baseOverrides(),
        );

        await tester.tap(find.byKey(const Key('plannedMealField')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Breakfast').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('manualEntryTab')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('energyField')), '400');
        await tester.enterText(find.byKey(const Key('proteinField')), '20');
        await tester.enterText(find.byKey(const Key('carbsField')), '30');
        await tester.enterText(find.byKey(const Key('fatField')), '10');

        await tester.tap(find.byKey(const Key('submitButton')));
        await tester.pumpAndSettle();

        final entries = await loggedEntries(today);
        expect(entries.single.plannedMealId, 'pm-breakfast');
      },
    );

    testWidgets('detaches a pre-attached entry back to extra', (
      tester,
    ) async {
      slotDirectory.slots.add(
        mealSlot(id: 'slot-breakfast', label: 'Breakfast', position: 0),
      );
      final plannedMeal = PlannedMeal(
        id: 'pm-breakfast',
        slotId: 'slot-breakfast',
        day: today,
        targetSnapshot: target(),
      );
      await dietSource.savePlannedMeal(plannedMeal);
      final detail = plannedMealDetail(plannedMeal, 'Breakfast');

      await pumpScreen(
        tester,
        RecordIntakeScreen(day: today, plannedMeal: detail),
        overrides: baseOverrides(),
      );

      await tester.tap(find.byKey(const Key('plannedMealField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PlannedMealField.extraLabel).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      final entries = await loggedEntries(today);
      expect(entries.single.plannedMealId, isNull);
    });

    testWidgets(
      'a planned-meal prefill opens on the manual tab, already filled in',
      (tester) async {
        slotDirectory.slots.add(
          mealSlot(id: 'slot-breakfast', label: 'Breakfast', position: 0),
        );
        final plannedMeal = PlannedMeal(
          id: 'pm-breakfast',
          slotId: 'slot-breakfast',
          day: today,
          targetSnapshot: target(kcal: 500, protein: 35, carbs: 55, fat: 15),
        );
        await dietSource.savePlannedMeal(plannedMeal);
        final detail = plannedMealDetail(plannedMeal, 'Breakfast');

        await pumpScreen(
          tester,
          RecordIntakeScreen(day: today, plannedMeal: detail),
          overrides: baseOverrides(),
        );

        // Prefilled means the manual tab is already selected and populated —
        // no tap needed, which is the one-tap-logging point of a prefill.
        final energyField = tester.widget<TextFormField>(
          find.byKey(const Key('energyField')),
        );
        expect(energyField.controller?.text, '500');

        await tester.tap(find.byKey(const Key('submitButton')));
        await tester.pumpAndSettle();

        final entries = await loggedEntries(today);
        expect(entries.single.energy.kcal, 500);
        expect(entries.single.plannedMealId, 'pm-breakfast');
      },
    );
  });
}
