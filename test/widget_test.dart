// Smoke test for the real Nutrition MVP app (replaces the old Flutter
// counter demo). Overrides `nutritionSourceProvider` with the in-memory
// fake so the test never touches drift/disk.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/main.dart';

import 'features/nutrition/_fakes/fake_nutrition_source.dart';

void main() {
  testWidgets('NutritionApp starts on the daily summary screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nutritionSourceProvider.overrideWithValue(FakeNutritionSource()),
        ],
        child: const NutritionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ingestas de hoy'), findsOneWidget);
    expect(find.text('Sin ingestas registradas hoy'), findsOneWidget);
    expect(find.byKey(const Key('addIntakeButton')), findsOneWidget);
  });
}
