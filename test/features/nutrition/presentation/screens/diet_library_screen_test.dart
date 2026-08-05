import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_library_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/manual_diet_editor_screen.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/diet_fixture.dart';
import '../../_fakes/fake_diet_plan_store.dart';

/// The diet library is now the ONLY place a diet is managed. These tests pin the
/// affordances that used to be split across two screens — choose, write, edit,
/// delete — so they cannot quietly drift apart again.
void main() {
  late FakeDietPlanStore store;

  setUp(() => store = FakeDietPlanStore());

  Future<void> pumpLibrary(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      const DietLibraryScreen(),
      overrides: [
        dietPlanStoreProvider.overrideWithValue(store),
        foodTableSourceProvider.overrideWithValue(FakeFoodTableSource()),
        // Ships nothing, so the empty state is reachable. Left to the default,
        // the first-run seed would read the real bundled plan off the asset
        // bundle and the library would never be empty.
        bundledDietDocumentProvider.overrideWithValue(
          FakeBundledDietDocumentSource(),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<void> seed({
    required String id,
    required String name,
    bool isDefault = false,
    String? sourceLabel,
    DateTime? importedAt,
  }) async {
    final diet = manualDiet(
      id: id,
      name: name,
      isDefault: isDefault,
      importedAt: importedAt,
      slots: [mealSlot(id: '$id-slot', label: 'Breakfast')],
    );
    await store.savePlan(
      sourceLabel == null
          ? diet
          : StoredDietPlan(
              id: diet.id,
              name: diet.name,
              document: diet.document,
              importedAt: diet.importedAt,
              isDefault: diet.isDefault,
              sourceLabel: sourceLabel,
            ),
    );
  }

  group('DietLibraryScreen', () {
    testWidgets('offers both ways to get a first diet when there are none', (
      tester,
    ) async {
      await pumpLibrary(tester);

      expect(find.byKey(const Key('noDietsMessage')), findsOneWidget);
      // Writing one by hand always works, even on a build with no extraction
      // key, so it is the offer that is always present.
      expect(find.byKey(const Key('createFirstDietButton')), findsOneWidget);
    });

    testWidgets('marks the active diet and switches on tap', (tester) async {
      await seed(id: 'a', name: 'Diet A', importedAt: DateTime.utc(2026, 8, 1));
      await seed(id: 'b', name: 'Diet B', importedAt: DateTime.utc(2026, 8, 2));
      await pumpLibrary(tester);

      // The first stored plan became active; tapping the other moves it.
      await tester.tap(find.byKey(const Key('dietPlan-b')));
      await tester.pumpAndSettle();

      final active = switch (await store.activePlan()) {
        Ok(value: final plan) => plan,
        Err() => fail('activePlan failed'),
      };
      expect(
        active?.id,
        'b',
        reason: 'choosing a diet here is what every other screen reads',
      );
    });

    testWidgets('opens the editor from the write-a-diet button', (
      tester,
    ) async {
      await pumpLibrary(tester);

      await tester.tap(find.byKey(const Key('createDietButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ManualDietEditorScreen), findsOneWidget);
      expect(find.text('New diet'), findsOneWidget);
    });

    testWidgets('offers an edit for a hand-written diet only', (tester) async {
      await seed(id: 'mine', name: 'Mine');
      await seed(id: 'pdf', name: 'From a PDF', sourceLabel: 'plan.pdf');
      await pumpLibrary(tester);

      expect(find.byKey(const Key('editDietPlan-mine')), findsOneWidget);
      // An imported plan prescribes foods; this app cannot edit those, so it does
      // not pretend otherwise.
      expect(find.byKey(const Key('editDietPlan-pdf')), findsNothing);
    });

    testWidgets('keeps the last diet undeletable', (tester) async {
      await seed(id: 'only', name: 'Only one');
      await pumpLibrary(tester);

      // Deleting it would leave the day view with nothing to read and no obvious
      // way back.
      expect(find.byKey(const Key('deleteDietPlan-only')), findsNothing);
    });

    testWidgets('deletes a diet once there is more than one', (tester) async {
      await seed(id: 'a', name: 'Diet A', importedAt: DateTime.utc(2026, 8, 1));
      await seed(id: 'b', name: 'Diet B', importedAt: DateTime.utc(2026, 8, 2));
      await pumpLibrary(tester);

      await tester.tap(find.byKey(const Key('deleteDietPlan-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteDiet')));
      await tester.pumpAndSettle();

      expect(find.text('Diet B'), findsNothing);
      expect(find.text('Diet A'), findsOneWidget);
    });
  });
}
