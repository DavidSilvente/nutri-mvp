import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/daily_summary_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/hydration_screen.dart';

import '../../_fakes/fake_diet_plan_source.dart';
import '../../_fakes/fake_hydration_source.dart';
import '../../_fakes/fake_nutrition_source.dart';

void main() {
  group('DailySummaryScreen', () {
    testWidgets('shows an empty message when there are no entries today', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nutritionSourceProvider.overrideWithValue(FakeNutritionSource()),
            hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
            dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
          ],
          child: const MaterialApp(home: DailySummaryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin ingestas registradas hoy'), findsOneWidget);
    });

    testWidgets('lists today\'s entries from the fake source, no water', (
      tester,
    ) async {
      final fake = FakeNutritionSource();
      final entry = NutritionEntry(
        id: 'a',
        recordedAt: DateTime.now(),
        energy: Energy(kcal: 500),
        macros: Macros(proteinG: 30, carbsG: 40, fatG: 10),
      );
      await fake.record(entry);

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

      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('shows today\'s hydration total, separate from meals', (
      tester,
    ) async {
      final hydrationFake = FakeHydrationSource();
      await hydrationFake.record(
        HydrationEntry(
          id: 'w1',
          recordedAt: DateTime.now(),
          volume: WaterVolume(ml: 250),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nutritionSourceProvider.overrideWithValue(FakeNutritionSource()),
            hydrationSourceProvider.overrideWithValue(hydrationFake),
          ],
          child: const MaterialApp(home: DailySummaryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('250'), findsOneWidget);
    });

    testWidgets(
      'has a dedicated entry point to HydrationScreen, separate from the '
      'meal FAB',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              nutritionSourceProvider.overrideWithValue(FakeNutritionSource()),
              hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
            ],
            child: const MaterialApp(home: DailySummaryScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('goToHydrationButton')), findsOneWidget);
        expect(find.byKey(const Key('addIntakeButton')), findsOneWidget);

        await tester.tap(find.byKey(const Key('goToHydrationButton')));
        await tester.pumpAndSettle();

        expect(find.byType(HydrationScreen), findsOneWidget);
      },
    );
  });
}
