import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_component.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/resolved_component.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/component_options_sheet.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_diet_plan_store.dart';

/// A store whose day-scoped write always fails, so the day-write failure path
/// is exercised without touching the preference path at all.
class _FailingDayWriteStore extends FakeDietPlanStore {
  @override
  Future<Result<void, NutritionFailure>> selectOption({
    required NutritionDay day,
    required String componentId,
    required String optionId,
  }) async => const Err(StorageFailure('disk full'));
}

/// A store whose preference write can be switched to fail on demand, so a
/// test can first seed a preference successfully and only then break the
/// write the interaction under test is about.
class _FailingPreferenceStore extends FakeDietPlanStore {
  bool failPreferenceWrites = false;

  @override
  Future<Result<void, NutritionFailure>> setPreferredOption({
    required String componentId,
    required String optionId,
  }) async {
    if (failPreferenceWrites) return const Err(StorageFailure('disk full'));
    return super.setPreferredOption(
      componentId: componentId,
      optionId: optionId,
    );
  }
}

void main() {
  final day = NutritionDay.fromDateTime(DateTime(2026, 8, 3));

  late FakeDietPlanStore store;

  setUp(() => store = FakeDietPlanStore());

  ComponentOption option(String suffix) => ComponentOption(
    id: 'component-1-option-$suffix',
    foodId: 'food-$suffix',
    quantity: FoodQuantity(grams: 100),
    rawText: 'Option $suffix',
  );

  ResolvedComponent component() {
    final options = [option('a'), option('b')];
    return ResolvedComponent(
      componentId: 'component-1',
      sectionLabel: null,
      options: options,
      chosen: options.first,
      isDeviation: false,
      needsReview: false,
    );
  }

  Future<void> pumpSheet(
    WidgetTester tester, {
    FakeDietPlanStore? overrideStore,
  }) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showComponentOptionsSheet(
                context: context,
                component: component(),
                day: day,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      overrides: [
        dietPlanStoreProvider.overrideWithValue(overrideStore ?? store),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<Map<String, String>> selections(FakeDietPlanStore s) async {
    final result = await s.selectionsFor(day);
    return (result as Ok<Map<String, String>, NutritionFailure>).value;
  }

  Future<Map<String, String>> preferences(FakeDietPlanStore s) async {
    final result = await s.preferredOptions();
    return (result as Ok<Map<String, String>, NutritionFailure>).value;
  }

  group('ComponentOptionsSheet', () {
    testWidgets(
      'picking an option with the opt-in off writes only the day selection',
      (tester) async {
        await pumpSheet(tester);

        await tester.tap(find.byKey(const Key('option-component-1-option-b')));
        await tester.pumpAndSettle();

        expect(
          (await selections(store))['component-1'],
          'component-1-option-b',
        );
        expect(await preferences(store), isEmpty);
      },
    );

    testWidgets(
      'picking an option with the opt-in checked writes the day selection '
      'and the standing preference',
      (tester) async {
        await pumpSheet(tester);

        await tester.tap(find.byKey(const Key('alwaysUseThisCheckbox')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('option-component-1-option-b')));
        await tester.pumpAndSettle();

        expect(
          (await selections(store))['component-1'],
          'component-1-option-b',
        );
        expect(
          (await preferences(store))['component-1'],
          'component-1-option-b',
        );
      },
    );

    testWidgets(
      'toggling the checkbox alone writes and clears the preference for the '
      'option the sheet opened with, not an unconfirmed radio pick',
      (tester) async {
        await pumpSheet(tester);

        await tester.tap(find.byKey(const Key('alwaysUseThisCheckbox')));
        await tester.pumpAndSettle();

        expect(
          (await preferences(store))['component-1'],
          'component-1-option-a',
        );

        await tester.tap(find.byKey(const Key('alwaysUseThisCheckbox')));
        await tester.pumpAndSettle();

        expect((await preferences(store)).containsKey('component-1'), isFalse);
      },
    );

    testWidgets(
      'a day-selection write failure keeps the sheet open, surfaces the '
      'error, and leaves the prior selection intact',
      (tester) async {
        final failingStore = _FailingDayWriteStore();
        await pumpSheet(tester, overrideStore: failingStore);

        await tester.tap(find.byKey(const Key('option-component-1-option-b')));
        await tester.pumpAndSettle();

        expect(await selections(failingStore), isEmpty);
        expect(find.byKey(const Key('componentOptionsError')), findsOneWidget);
        // The sheet is still open: its option list is still on screen.
        expect(
          find.byKey(const Key('option-component-1-option-a')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a preference-write failure after a successful day-selection write '
      'keeps the sheet open, surfaces an attributable error, and leaves the '
      'checkbox unchecked',
      (tester) async {
        final failingStore = _FailingPreferenceStore();
        // Seed a preference that matches the opening selection, so the
        // checkbox opens already checked without going through the write
        // path this test is about to break.
        await failingStore.setPreferredOption(
          componentId: 'component-1',
          optionId: 'component-1-option-a',
        );
        failingStore.failPreferenceWrites = true;

        await pumpSheet(tester, overrideStore: failingStore);

        final checkboxBefore = tester.widget<CheckboxListTile>(
          find.byKey(const Key('alwaysUseThisCheckbox')),
        );
        expect(checkboxBefore.value, isTrue);

        await tester.tap(find.byKey(const Key('option-component-1-option-b')));
        await tester.pumpAndSettle();

        // The day selection succeeded...
        expect(
          (await selections(failingStore))['component-1'],
          'component-1-option-b',
        );
        // ...but the preference write failed, so it stays at the seeded
        // value rather than following the new pick.
        expect(
          (await preferences(failingStore))['component-1'],
          'component-1-option-a',
        );
        expect(find.byKey(const Key('componentOptionsError')), findsOneWidget);

        final checkboxAfter = tester.widget<CheckboxListTile>(
          find.byKey(const Key('alwaysUseThisCheckbox')),
        );
        expect(checkboxAfter.value, isFalse);
      },
    );

    testWidgets(
      "the sheet's title falls back to 'Options', never 'Alternatives'",
      (tester) async {
        await pumpSheet(tester);

        expect(find.text('Options'), findsOneWidget);
        expect(find.text('Alternatives'), findsNothing);
      },
    );
  });
}
