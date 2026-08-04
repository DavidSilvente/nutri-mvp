import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/day_plan_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/record_intake_screen.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_hydration_source.dart';
import '../../_fakes/fake_nutrition_source.dart';

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
  late FakeNutritionSource nutritionSource;

  setUp(() {
    dietSource = FakeDietPlanSource();
    nutritionSource = FakeNutritionSource();
  });

  Future<void> saveTemplate() async {
    final slots = [
      DietMealSlot(
        id: 'slot-breakfast',
        label: 'Breakfast',
        position: 0,
        target: target(),
      ),
      DietMealSlot(
        id: 'slot-dinner',
        label: 'Dinner',
        position: 1,
        target: target(),
      ),
    ];
    await dietSource.saveTemplate(
      DietTemplate(
        id: 't1',
        name: 'Plan',
        dailyTarget: NutritionTarget.sum(slots.map((s) => s.target)),
        slots: slots,
      ),
    );
  }

  Future<void> plan(String id, String slotId) {
    return dietSource.savePlannedMeal(
      PlannedMeal(
        id: id,
        slotId: slotId,
        day: day,
        targetSnapshot: target(),
      ),
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

  /// The day view stacks several tall cards, so the default 800x600 test
  /// surface would push most of them out of the viewport and out of the
  /// widget tree. A tall surface keeps the assertions about content, not
  /// about scrolling.
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      DayPlanScreen(day: day),
      overrides: [
        nutritionSourceProvider.overrideWithValue(nutritionSource),
        dietPlanSourceProvider.overrideWithValue(dietSource),
        hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
        todayProvider.overrideWithValue(today),
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
      await saveTemplate();
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
      await saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await plan('pm-dinner', 'slot-dinner');
      await log(id: 'e1', plannedMealId: 'pm-breakfast');

      await pumpScreen(tester);

      expect(find.text('On target'), findsOneWidget);
      expect(find.text('Not logged'), findsOneWidget);
      expect(find.text('1/2 meals'), findsOneWidget);
    });

    testWidgets('marks the day as partly met when some meals were met', (
      tester,
    ) async {
      await saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await plan('pm-dinner', 'slot-dinner');
      await log(id: 'e1', plannedMealId: 'pm-breakfast');

      await pumpScreen(tester);

      expect(find.text('Partly'), findsOneWidget);
    });

    testWidgets('logging a planned meal pre-fills the form with its target', (
      tester,
    ) async {
      await saveTemplate();
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
      await saveTemplate();
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
      await saveTemplate();
      await plan('pm-breakfast', 'slot-breakfast');
      await log(id: 'snack', kcal: 210, protein: 5, carbs: 25, fat: 8);

      await pumpScreen(tester);

      expect(find.text('Extras'), findsOneWidget);
      expect(find.text('210 kcal'), findsOneWidget);
    });
  });
}
