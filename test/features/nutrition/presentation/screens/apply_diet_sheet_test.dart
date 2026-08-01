import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/day_plan_screen.dart';

import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_hydration_source.dart';
import '../../_fakes/fake_nutrition_source.dart';

NutritionTarget target({num kcal = 600}) => NutritionTarget(
  energy: Energy(kcal: kcal),
  macros: Macros(proteinG: 40, carbsG: 60, fatG: 20),
);

void main() {
  // A Monday, so "rest of the week" covers a predictable seven days.
  final monday = NutritionDay.fromDateTime(DateTime(2026, 7, 20));

  late FakeDietPlanSource dietSource;

  setUp(() {
    dietSource = FakeDietPlanSource();
  });

  Future<void> saveTemplate() async {
    final slots = [
      DietMealSlot(
        id: 'slot-breakfast',
        label: 'Breakfast',
        position: 0,
        target: target(kcal: 400),
      ),
      DietMealSlot(
        id: 'slot-dinner',
        label: 'Dinner',
        position: 1,
        target: target(kcal: 800),
      ),
    ];
    await dietSource.saveTemplate(
      DietTemplate(
        id: 't1',
        name: 'Cut',
        dailyTarget: NutritionTarget.sum(slots.map((s) => s.target)),
        slots: slots,
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nutritionSourceProvider.overrideWithValue(FakeNutritionSource()),
          dietPlanSourceProvider.overrideWithValue(dietSource),
          hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
          todayProvider.overrideWithValue(monday),
        ],
        child: MaterialApp(home: DayPlanScreen(day: monday)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('applyDietButton')));
    await tester.pumpAndSettle();
  }

  group('ApplyDietSheet', () {
    testWidgets('points at the Diet tab when there is nothing to apply', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.text('No diets to apply'), findsOneWidget);
    });

    testWidgets('applies a diet to a single day', (tester) async {
      await saveTemplate();
      await openSheet(tester);

      expect(find.text('1 day · 2 meals'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmApplyDietButton')));
      await tester.pumpAndSettle();

      expect(await plannedOn(monday), hasLength(2));
      // The day view refreshes itself off the shared revision counter.
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
    });

    testWidgets('applies a diet to the rest of the week', (tester) async {
      await saveTemplate();
      await openSheet(tester);

      await tester.tap(find.text('Rest of the week'));
      await tester.pumpAndSettle();

      // Monday through Sunday inclusive.
      expect(find.text('7 days · 14 meals'), findsOneWidget);

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

    testWidgets('applies a diet to the rest of the month', (tester) async {
      await saveTemplate();
      await openSheet(tester);

      await tester.tap(find.text('Rest of the month'));
      await tester.pumpAndSettle();

      // The 20th to the 31st inclusive.
      expect(find.text('12 days · 24 meals'), findsOneWidget);
    });

    testWidgets('re-applying the same diet does not duplicate meals', (
      tester,
    ) async {
      await saveTemplate();
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('confirmApplyDietButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('applyDietCompactButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmApplyDietButton')));
      await tester.pumpAndSettle();

      expect(await plannedOn(monday), hasLength(2));
    });
  });
}
