import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/record_intake_screen.dart';

import '../../_fakes/fake_nutrition_source.dart';

void main() {
  group('RecordIntakeScreen', () {
    testWidgets('submits energy, macros and water to the fake source', (
      tester,
    ) async {
      final fake = FakeNutritionSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [nutritionSourceProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: RecordIntakeScreen()),
        ),
      );

      await tester.enterText(find.byKey(const Key('energyField')), '500');
      await tester.enterText(find.byKey(const Key('proteinField')), '30');
      await tester.enterText(find.byKey(const Key('carbsField')), '40');
      await tester.enterText(find.byKey(const Key('fatField')), '10');
      await tester.enterText(find.byKey(const Key('waterField')), '250');

      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      final result = await fake.entriesOn(
        NutritionDay.fromDateTime(DateTime.now()),
      );
      final entries =
          (result as Ok<List<NutritionEntry>, NutritionFailure>).value;

      expect(entries, hasLength(1));
      expect(entries.single.energy.kcal, 500);
      expect(entries.single.macros.proteinG, 30);
      expect(entries.single.macros.carbsG, 40);
      expect(entries.single.macros.fatG, 10);
      expect(entries.single.water.ml, 250);
    });
  });
}
