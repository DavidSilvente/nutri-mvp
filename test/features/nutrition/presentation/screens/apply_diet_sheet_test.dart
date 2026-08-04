import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/day_plan_screen.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/diet_fixture.dart';
import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_diet_plan_store.dart';
import '../../_fakes/fake_hydration_source.dart';
import '../../_fakes/fake_nutrition_source.dart';

/// Covers the sheet AND the wiring behind it: the store, the decoder and the
/// slot directory are the real ones, so a diet seeded as a stored plan has to
/// travel all the way to named meals on the day view.
///
/// That round trip is the bug this whole area had — a diet could exist and the
/// day view would still say there was none.
void main() {
  // A Monday, so "rest of the week" covers a predictable seven days.
  final monday = NutritionDay.fromDateTime(DateTime(2026, 7, 20));

  late FakeDietPlanSource dietSource;
  late FakeDietPlanStore store;

  setUp(() {
    dietSource = FakeDietPlanSource();
    store = FakeDietPlanStore();
  });

  Future<void> seedDiet({Set<int>? weekdays}) async {
    await store.savePlan(
      manualDiet(
        name: 'Cut',
        weekdays: weekdays,
        slots: [
          mealSlot(
            id: 'slot-breakfast',
            label: 'Breakfast',
            position: 0,
            kcal: 400,
          ),
          mealSlot(id: 'slot-dinner', label: 'Dinner', position: 1, kcal: 800),
        ],
      ),
    );
  }

  Future<List<PlannedMeal>> plannedOn(NutritionDay day) async {
    final result = await dietSource.listPlannedMeals(day: day);
    return (result as Ok<List<PlannedMeal>, NutritionFailure>).value;
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      DayPlanScreen(day: monday),
      overrides: [
        nutritionSourceProvider.overrideWithValue(FakeNutritionSource()),
        dietPlanSourceProvider.overrideWithValue(dietSource),
        dietPlanStoreProvider.overrideWithValue(store),
        foodTableSourceProvider.overrideWithValue(FakeFoodTableSource()),
        hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
        todayProvider.overrideWithValue(monday),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('applyDietButton')));
    await tester.pumpAndSettle();
  }

  group('ApplyDietSheet', () {
    testWidgets('points at My diets when there is nothing to apply', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.text('No diets to apply'), findsOneWidget);
    });

    testWidgets('applies the stored diet to a single day', (tester) async {
      await seedDiet();
      await openSheet(tester);

      expect(find.text('1 day'), findsOneWidget);
      // The active diet is preselected, so applying is one tap.
      expect(find.text('Current'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmApplyDietButton')));
      await tester.pumpAndSettle();

      expect(await plannedOn(monday), hasLength(2));
      // The day view refreshes itself off the shared revision counter, and names
      // the meals by reading them back out of the diet.
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
    });

    testWidgets('applies a diet to the rest of the week', (tester) async {
      await seedDiet();
      await openSheet(tester);

      await tester.tap(find.text('Rest of the week'));
      await tester.pumpAndSettle();

      // Monday through Sunday inclusive.
      expect(find.text('7 days'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmApplyDietButton')));
      await tester.pumpAndSettle();

      expect(await plannedOn(monday), hasLength(2));
      expect(
        await plannedOn(NutritionDay.fromDateTime(DateTime(2026, 7, 26))),
        hasLength(2),
      );
      // Never reaches into days already lived.
      expect(
        await plannedOn(NutritionDay.fromDateTime(DateTime(2026, 7, 19))),
        isEmpty,
      );
    });

    testWidgets('counts the days of the rest of the month', (tester) async {
      await seedDiet();
      await openSheet(tester);

      await tester.tap(find.text('Rest of the month'));
      await tester.pumpAndSettle();

      // The 20th to the 31st inclusive.
      expect(find.text('12 days'), findsOneWidget);
    });

    testWidgets('re-applying the same diet does not duplicate meals', (
      tester,
    ) async {
      await seedDiet();
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('confirmApplyDietButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('applyDietCompactButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmApplyDietButton')));
      await tester.pumpAndSettle();

      expect(await plannedOn(monday), hasLength(2));
    });

    testWidgets('says so when the diet covers none of the days asked for', (
      tester,
    ) async {
      // A diet that only describes Sundays, applied to a Monday.
      await seedDiet(weekdays: {DateTime.sunday});
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('confirmApplyDietButton')));
      await tester.pumpAndSettle();

      expect(await plannedOn(monday), isEmpty);
      expect(
        find.textContaining('left empty'),
        findsOneWidget,
        reason: 'silently planning nothing would look like it worked',
      );
    });
  });
}
