import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/daily_summary_screen.dart';

import '../../_fakes/fake_nutrition_source.dart';

void main() {
  testWidgets(
    'registering an intake from the record screen makes it appear in the '
    'daily summary list, sharing the same source',
    (tester) async {
      final fake = FakeNutritionSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [nutritionSourceProvider.overrideWithValue(fake)],
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
      await tester.enterText(find.byKey(const Key('waterField')), '250');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      // Back on the daily summary screen, the newly recorded entry shows up.
      expect(find.text('Ingestas de hoy'), findsOneWidget);
      expect(find.text('Sin ingestas registradas hoy'), findsNothing);
      expect(find.textContaining('500'), findsOneWidget);
    },
  );
}
