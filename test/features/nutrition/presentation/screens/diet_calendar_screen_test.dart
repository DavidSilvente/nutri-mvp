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
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_calendar_screen.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_hydration_source.dart';
import '../../_fakes/fake_nutrition_source.dart';

NutritionTarget target() => NutritionTarget(
  energy: Energy(kcal: 600),
  macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
);

void main() {
  final today = NutritionDay.fromDateTime(DateTime(2026, 7, 20));

  NutritionDay day(int d) => NutritionDay.fromDateTime(DateTime(2026, 7, d));

  late FakeDietPlanSource dietSource;
  late FakeNutritionSource nutritionSource;

  setUp(() async {
    dietSource = FakeDietPlanSource();
    nutritionSource = FakeNutritionSource();

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
  });

  Future<void> plan(String id, int dayOfMonth) {
    return dietSource.savePlannedMeal(
      PlannedMeal(
        id: id,
        slotId: 'slot-1',
        day: day(dayOfMonth),
        targetSnapshot: target(),
      ),
    );
  }

  Future<void> log(String id, String plannedMealId, int dayOfMonth) {
    return nutritionSource.record(
      NutritionEntry(
        id: id,
        recordedAt: DateTime(2026, 7, dayOfMonth, 13),
        energy: Energy(kcal: 600),
        macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
        plannedMealId: plannedMealId,
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      const DietCalendarScreen(),
      overrides: [
        nutritionSourceProvider.overrideWithValue(nutritionSource),
        dietPlanSourceProvider.overrideWithValue(dietSource),
        hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
        todayProvider.overrideWithValue(today),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('DietCalendarScreen', () {
    testWidgets('opens on the month containing today', (tester) async {
      await pumpScreen(tester);

      expect(find.text('July 2026'), findsOneWidget);
      // July has 31 days, all rendered as tappable cells.
      expect(find.byKey(Key('calendarDay-${day(1).epochDay}')), findsOneWidget);
      expect(
        find.byKey(Key('calendarDay-${day(31).epochDay}')),
        findsOneWidget,
      );
    });

    testWidgets('says there is nothing to judge before any day settles', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Nothing to judge yet'), findsOneWidget);
    });

    testWidgets('counts only settled days in the month summary', (
      tester,
    ) async {
      // The 10th is met, the 11th is missed, the 28th is still upcoming.
      await plan('pm-10', 10);
      await log('e-10', 'pm-10', 10);
      await plan('pm-11', 11);
      await plan('pm-28', 28);

      await pumpScreen(tester);

      expect(find.text('1 of 2 days on plan'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('navigates to the previous and next month', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('previousMonthButton')));
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nextMonthButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nextMonthButton')));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('rolls the year over at December', (tester) async {
      await pumpScreen(tester);

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(const Key('nextMonthButton')));
        await tester.pumpAndSettle();
      }

      expect(find.text('January 2027'), findsOneWidget);
    });

    testWidgets('tapping a day opens that day\'s plan', (tester) async {
      await plan('pm-10', 10);

      await pumpScreen(tester);
      await tester.tap(find.byKey(Key('calendarDay-${day(10).epochDay}')));
      await tester.pumpAndSettle();

      expect(find.byType(DayPlanScreen), findsOneWidget);
      expect(find.text('Friday, 10 July'), findsOneWidget);
    });
  });
}
