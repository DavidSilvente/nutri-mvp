// Smoke test for the real Nutrition app. Overrides the source providers with
// in-memory fakes so the test never touches drift/disk.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/home_screen.dart';
import 'package:nutri_mvp/main.dart';

import '_helpers/fake_overrides.dart';

void main() {
  testWidgets('NutritionApp starts on today\'s plan', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAppOverrides(),
        child: const NutritionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    // Nothing planned yet, so the empty state invites building a plan.
    expect(find.text('No meals planned'), findsOneWidget);
    expect(find.byKey(const Key('logUnplannedIntakeButton')), findsOneWidget);
  });

  testWidgets('every destination is reachable', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAppOverrides(),
        child: const NutritionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todayTab')), findsOneWidget);
    expect(find.byKey(const Key('myDietTab')), findsOneWidget);
    expect(find.byKey(const Key('calendarTab')), findsOneWidget);
    expect(find.byKey(const Key('dietTab')), findsOneWidget);
  });
}
