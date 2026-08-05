import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/save_manual_diet.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/manual_diet_editor_screen.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/diet_fixture.dart';
import '../../_fakes/fake_diet_plan_store.dart';

void main() {
  late FakeDietPlanStore store;

  setUp(() => store = FakeDietPlanStore());

  Future<void> pumpEditor(WidgetTester tester, {String? planId}) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      ManualDietEditorScreen(planId: planId),
      overrides: [
        dietPlanStoreProvider.overrideWithValue(store),
        foodTableSourceProvider.overrideWithValue(FakeFoodTableSource()),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<List<StoredDietPlan>> storedPlans() async {
    final result = await store.listPlans();
    return switch (result) {
      Ok(value: final plans) => plans,
      Err() => throw StateError('listPlans failed'),
    };
  }

  Future<void> fillMeal(
    WidgetTester tester,
    int index, {
    required String label,
    required String kcal,
    String protein = '30',
    String carbs = '50',
    String fat = '15',
  }) async {
    await tester.enterText(find.byKey(Key('mealLabelField_$index')), label);
    await tester.enterText(find.byKey(Key('mealKcalField_$index')), kcal);
    await tester.enterText(find.byKey(Key('mealProteinField_$index')), protein);
    await tester.enterText(find.byKey(Key('mealCarbsField_$index')), carbs);
    await tester.enterText(find.byKey(Key('mealFatField_$index')), fat);
    await tester.pumpAndSettle();
  }

  group('ManualDietEditorScreen creating', () {
    testWidgets('opens with one meal row ready to fill in', (tester) async {
      await pumpEditor(tester);

      expect(find.text('New diet'), findsOneWidget);
      expect(find.byKey(const Key('mealCard_0')), findsOneWidget);
      // Nothing to remove when there is only one meal.
      expect(find.byKey(const Key('removeMealButton_0')), findsNothing);
    });

    testWidgets('shows the daily total adding up from the meals', (
      tester,
    ) async {
      await pumpEditor(tester);
      await fillMeal(tester, 0, label: 'Breakfast', kcal: '400');

      await tester.tap(find.byKey(const Key('addMealButton')));
      await tester.pumpAndSettle();
      await fillMeal(tester, 1, label: 'Lunch', kcal: '700');

      // Derived on screen rather than typed, so it cannot disagree with the
      // meals it is made of.
      expect(find.text('1100 kcal'), findsOneWidget);
    });

    testWidgets('saves the diet and makes it the active one', (tester) async {
      await pumpEditor(tester);
      await tester.enterText(
        find.byKey(const Key('dietNameField')),
        'My own diet',
      );
      await fillMeal(tester, 0, label: 'Breakfast', kcal: '400');

      await tester.tap(find.byKey(const Key('saveDietButton')));
      await tester.pumpAndSettle();

      final plans = await storedPlans();
      expect(plans, hasLength(1));
      expect(plans.single.name, 'My own diet');
      expect(plans.single.isDefault, isTrue);
      expect(plans.single.sourceLabel, SaveManualDiet.manualSourceLabel);
    });

    testWidgets('will not save without a name', (tester) async {
      await pumpEditor(tester);
      await fillMeal(tester, 0, label: 'Breakfast', kcal: '400');

      await tester.tap(find.byKey(const Key('saveDietButton')));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
      expect(await storedPlans(), isEmpty);
    });

    testWidgets('reports a clashing name instead of failing silently', (
      tester,
    ) async {
      await store.savePlan(
        manualDiet(
          name: 'Cut',
          slots: [mealSlot(id: 'existing')],
        ),
      );

      await pumpEditor(tester);
      await tester.enterText(find.byKey(const Key('dietNameField')), 'Cut');
      await fillMeal(tester, 0, label: 'Breakfast', kcal: '400');
      await tester.tap(find.byKey(const Key('saveDietButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manualDietError')), findsOneWidget);
      expect(await storedPlans(), hasLength(1));
    });
  });

  group('ManualDietEditorScreen editing', () {
    testWidgets('loads the diet and keeps its slot ids on save', (
      tester,
    ) async {
      await store.savePlan(
        manualDiet(
          id: 'diet-1',
          name: 'Cut',
          slots: [
            mealSlot(id: 'slot-a', label: 'Breakfast', position: 0, kcal: 400),
            mealSlot(id: 'slot-b', label: 'Lunch', position: 1, kcal: 700),
          ],
        ),
      );

      await pumpEditor(tester, planId: 'diet-1');

      expect(find.text('Edit diet'), findsOneWidget);
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('1100 kcal'), findsOneWidget);

      // Change only the first meal's energy.
      await tester.enterText(find.byKey(const Key('mealKcalField_0')), '450');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saveDietButton')));
      await tester.pumpAndSettle();

      final plans = await storedPlans();
      expect(plans, hasLength(1), reason: 'an edit replaces, it does not add');
      // The ids the calendar's planned meals point at must survive the edit.
      expect(plans.single.document, contains('slot-a'));
      expect(plans.single.document, contains('slot-b'));
      expect(plans.single.document, contains('450'));
    });

    testWidgets('refuses to edit a diet that came from a PDF', (tester) async {
      // A food-first plan prescribes actual foods; this editor only knows typed
      // macros, so "editing" it would replace them with bare totals.
      final imported = StoredDietPlan(
        id: 'imported-1',
        name: 'Nutrium 2950',
        importedAt: DateTime.utc(2026, 8, 1),
        sourceLabel: 'plan.pdf',
        document: _foodFirstDocument(),
      );
      await store.savePlan(imported);

      await pumpEditor(tester, planId: 'imported-1');

      expect(find.byKey(const Key('importedDietNotEditable')), findsOneWidget);
      expect(find.byKey(const Key('saveDietButton')), findsNothing);
    });

    testWidgets('says so when the diet was deleted meanwhile', (tester) async {
      await pumpEditor(tester, planId: 'gone');

      expect(find.text('This diet no longer exists.'), findsOneWidget);
    });
  });
}

/// A minimal food-first document referencing a food the fake table serves.
///
/// Written out by hand rather than produced by the encoder on purpose: the
/// encoder REFUSES food-first plans, which is the very case under test.
String _foodFirstDocument() => '''
{
  "schemaVersion": 2,
  "diet": {
    "name": "Nutrium 2950",
    "dayGroups": [
      {
        "label": "EVERY DAY",
        "weekdays": [1, 2, 3, 4, 5, 6, 7],
        "meals": [
          {
            "slotId": "imported-1:g0:m0",
            "label": "Lunch",
            "sections": [
              {
                "label": null,
                "components": [
                  {
                    "alternatives": [
                      {
                        "foodRef": "chicken_breast_grilled",
                        "quantity": {"grams": 100},
                        "rawText": "100 g pollo"
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}
''';
