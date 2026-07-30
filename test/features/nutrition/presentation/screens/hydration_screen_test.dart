import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/hydration_screen.dart';

import '../../_fakes/fake_hydration_source.dart';

void main() {
  group('HydrationScreen', () {
    testWidgets('shows an empty message when there are no entries today', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationSourceProvider.overrideWithValue(FakeHydrationSource()),
          ],
          child: const MaterialApp(home: HydrationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin registros de agua hoy'), findsOneWidget);
    });

    testWidgets('submits a volume to the fake source and lists it', (
      tester,
    ) async {
      final fake = FakeHydrationSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hydrationSourceProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: HydrationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('volumeField')), '250');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      final result = await fake.entriesOn(
        NutritionDay.fromDateTime(DateTime.now()),
      );
      final entries =
          (result as Ok<List<HydrationEntry>, NutritionFailure>).value;

      expect(entries, hasLength(1));
      expect(entries.single.volume.ml, 250);
      expect(find.textContaining('250'), findsWidgets);
    });
  });
}
