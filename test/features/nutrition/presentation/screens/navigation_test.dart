import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/adherence_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_calendar_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_templates_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/home_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/hydration_screen.dart';

import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_hydration_source.dart';
import '../../_fakes/fake_nutrition_source.dart';

void main() {
  /// Pins "today" so the calendar and day headings do not drift with the
  /// machine clock.
  final today = NutritionDay.fromDateTime(DateTime.now());

  Widget app({
    FakeNutritionSource? nutrition,
    FakeHydrationSource? hydration,
    FakeDietPlanSource? dietPlan,
  }) {
    return ProviderScope(
      overrides: [
        nutritionSourceProvider.overrideWithValue(
          nutrition ?? FakeNutritionSource(),
        ),
        hydrationSourceProvider.overrideWithValue(
          hydration ?? FakeHydrationSource(),
        ),
        dietPlanSourceProvider.overrideWithValue(
          dietPlan ?? FakeDietPlanSource(),
        ),
        todayProvider.overrideWithValue(today),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  testWidgets(
    'an intake logged from the FAB shows up on today\'s plan as off-plan, '
    'sharing the same source',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Extras'), findsNothing);

      await tester.tap(find.byKey(const Key('logUnplannedIntakeButton')));
      await tester.pumpAndSettle();

      expect(find.text('Registrar ingesta'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('energyField')), '500');
      await tester.enterText(find.byKey(const Key('proteinField')), '30');
      await tester.enterText(find.byKey(const Key('carbsField')), '40');
      await tester.enterText(find.byKey(const Key('fatField')), '10');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      // Back on today's plan, the entry appears under the off-plan section:
      // it counts towards the totals, not towards adherence. It sits below
      // the fold, so scroll it into view first.
      await tester.scrollUntilVisible(
        find.text('Extras'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Extras'), findsOneWidget);
      expect(find.textContaining('500'), findsWidgets);
    },
  );

  testWidgets(
    'water logged from the hydration screen updates today\'s water total, '
    'independently from meals',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('goToHydrationButton')));
      await tester.pumpAndSettle();

      expect(find.byType(HydrationScreen), findsOneWidget);

      await tester.enterText(find.byKey(const Key('volumeField')), '250');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('250 ml'), findsOneWidget);
      // Meals remain untouched by the water registration.
      expect(find.text('Extras'), findsNothing);
    },
  );

  testWidgets('the diet tab opens the template list', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dietTab')));
    await tester.pumpAndSettle();

    expect(find.byType(DietTemplatesScreen), findsOneWidget);
  });

  testWidgets('the calendar tab opens the month grid', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calendarTab')));
    await tester.pumpAndSettle();

    expect(find.byType(DietCalendarScreen), findsOneWidget);
    expect(find.byKey(Key('calendarDay-${today.epochDay}')), findsOneWidget);
  });
}
