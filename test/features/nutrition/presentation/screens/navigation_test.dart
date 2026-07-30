import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/daily_summary_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/hydration_screen.dart';

import '../../_fakes/fake_hydration_source.dart';
import '../../_fakes/fake_nutrition_source.dart';

void main() {
  testWidgets(
    'registering an intake from the record screen makes it appear in the '
    'daily summary list, sharing the same source',
    (tester) async {
      final fake = FakeNutritionSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nutritionSourceProvider.overrideWithValue(fake),
            hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
          ],
          child: const MaterialApp(home: DailySummaryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin ingestas registradas hoy'), findsOneWidget);

      // Navigate to the record screen via the FAB.
      await tester.tap(find.byKey(const Key('addIntakeButton')));
      await tester.pumpAndSettle();

      expect(find.text('Registrar ingesta'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('energyField')), '500');
      await tester.enterText(find.byKey(const Key('proteinField')), '30');
      await tester.enterText(find.byKey(const Key('carbsField')), '40');
      await tester.enterText(find.byKey(const Key('fatField')), '10');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      // Back on the daily summary screen, the newly recorded entry shows up.
      expect(find.text('Ingestas de hoy'), findsOneWidget);
      expect(find.text('Sin ingestas registradas hoy'), findsNothing);
      expect(find.textContaining('500'), findsOneWidget);
    },
  );

  testWidgets(
    'registering water from the dedicated hydration screen updates the '
    'daily summary hydration total, independently from meals',
    (tester) async {
      final nutritionFake = FakeNutritionSource();
      final hydrationFake = FakeHydrationSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nutritionSourceProvider.overrideWithValue(nutritionFake),
            hydrationSourceProvider.overrideWithValue(hydrationFake),
          ],
          child: const MaterialApp(home: DailySummaryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to the dedicated hydration screen via its own entry point
      // (NOT the meal FAB).
      await tester.tap(find.byKey(const Key('goToHydrationButton')));
      await tester.pumpAndSettle();

      expect(find.byType(HydrationScreen), findsOneWidget);

      await tester.enterText(find.byKey(const Key('volumeField')), '250');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      // Go back to the daily summary screen.
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(DailySummaryScreen), findsOneWidget);
      expect(find.textContaining('250'), findsOneWidget);
      // Meals remain untouched by the water registration.
      expect(find.text('Sin ingestas registradas hoy'), findsOneWidget);
    },
  );
}
