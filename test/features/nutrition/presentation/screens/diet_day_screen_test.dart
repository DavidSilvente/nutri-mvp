import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/food_table_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_day_screen.dart';

import '../../../../_helpers/fake_overrides.dart';
import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_diet_plan_store.dart';

/// Widget-level checks over the REAL shipped diet and food table.
///
/// Uses the actual assets rather than a toy plan so the screen is exercised
/// against the shape a real Nutrium export produces: day groups, per-item
/// alternatives, sections, notes, and estimated foods.
void main() {
  late String planDocument;
  late FakeFoodTableSource foodTable;

  setUpAll(() {
    planDocument =
        File('assets/diets/nutrium_david_2950kcal.json').readAsStringSync();
    final tableSource =
        File('assets/nutrition/food_table.json').readAsStringSync();
    final decoded = const FoodTableCodec().decode(tableSource);
    foodTable = FakeFoodTableSource(
      foods: switch (decoded) {
        Ok(value: final foods) => foods,
        Err(failure: final failure) => fail('food table: $failure'),
      },
    );
  });

  /// A Monday, so the plan resolves to its `LU Y VI` group.
  final monday = NutritionDay.fromDateTime(DateTime.utc(2026, 8, 3));

  Future<FakeDietPlanStore> pumpDay(
    WidgetTester tester, {
    NutritionDay? day,
    bool seedPlan = true,
  }) async {
    final store = FakeDietPlanStore();
    if (seedPlan) {
      await store.savePlan(StoredDietPlan(
        id: 'plan-1',
        name: 'Ajuste 2950 kcal',
        document: planDocument,
        importedAt: DateTime.utc(2026, 7, 22),
        declaredDailyEnergyKcal: 2950,
        isDefault: true,
        sourceLabel: 'DAVID GALERA AJUSTE 2950KCAL.pdf',
      ));
    }
    await pumpApp(
      tester,
      DietDayScreen(day: day ?? monday),
      overrides: fakeAppOverrides(
        dietPlanStore: store,
        foodTable: foodTable,
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('shows the active plan, its day group and derived energy',
      (tester) async {
    await pumpDay(tester);

    expect(find.text('Ajuste 2950 kcal'), findsOneWidget);
    expect(find.text('LU Y VI'), findsOneWidget);
    // The honest derived figure, not the 2950 headline.
    expect(find.text('3082 kcal'), findsOneWidget);
    // The headline is shown alongside it, with the gap stated.
    expect(
      find.textContaining('Plan states 2950 kcal'),
      findsOneWidget,
    );
  });

  testWidgets('lists every meal of the day with its own time', (tester) async {
    await pumpDay(tester);

    // The day does not fit one screen, so each meal is scrolled to in turn
    // rather than asserted blind — a ListView never builds off-screen rows.
    for (final label in [
      'DESAYUNO',
      'MEDIA MAÑANA',
      'COMIDA',
      'MERIENDA',
      'CENA',
    ]) {
      final finder = find.text(label);
      await tester.scrollUntilVisible(finder, 150);
      expect(finder, findsOneWidget, reason: label);
    }
    expect(find.text('16:30'), findsOneWidget);
  });

  testWidgets('shows each item with the plan wording verbatim',
      (tester) async {
    await pumpDay(tester);

    expect(
      find.text('60 gramos de jamón cocido, extra'),
      findsOneWidget,
    );
    expect(
      find.text('140 gramos de chapata cristal Mercadona'),
      findsOneWidget,
    );
  });

  testWidgets('swapping an item changes that item and the day total',
      (tester) async {
    await pumpDay(tester);

    expect(find.text('3082 kcal'), findsOneWidget);

    // Lunch's protein: 140 g chicken breast, with three alternatives.
    final protein = find.text('140 gramos de pollo, pechuga, plancha');
    await tester.scrollUntilVisible(protein, 120);
    await tester.tap(protein);
    await tester.pumpAndSettle();

    // The sheet lists the dietitian's options in their own order.
    expect(find.text("Plan's first choice"), findsOneWidget);
    final beef = find.byKey(
      const Key('option-plan-1:g0:m2:c0:o1'),
    );
    expect(beef, findsOneWidget);

    await tester.tap(beef);
    await tester.pumpAndSettle();

    // The swapped item now shows the chosen wording...
    expect(
      find.text('150 gramos de lomo ternera Mercadona'),
      findsOneWidget,
    );
    expect(protein, findsNothing);
    // ...and the day total moved, because macros are derived, not stored.
    expect(find.text('3082 kcal'), findsNothing);
  });

  testWidgets('the swap survives only for the day it was made', (tester) async {
    final store = await pumpDay(tester);

    await store.selectOption(
      day: monday,
      componentId: 'plan-1:g0:m2:c0',
      optionId: 'plan-1:g0:m2:c0:o1',
    );

    final mondayChoices = await store.selectionsFor(monday);
    expect(
      switch (mondayChoices) {
        Ok(value: final value) => value,
        Err() => fail('expected Ok'),
      },
      isNotEmpty,
    );

    // Friday shares the same day group but is a different date, so it keeps the
    // dietitian's default.
    final friday = NutritionDay.fromDateTime(DateTime.utc(2026, 8, 7));
    final fridayChoices = await store.selectionsFor(friday);
    expect(
      switch (fridayChoices) {
        Ok(value: final value) => value,
        Err() => fail('expected Ok'),
      },
      isEmpty,
    );
  });

  testWidgets('reverting returns the item to the plan choice', (tester) async {
    await pumpDay(tester);

    // Swap through the UI, so the revert is exercised against real state rather
    // than state the test wrote behind the screen's back.
    final original = find.text('140 gramos de pollo, pechuga, plancha');
    await tester.scrollUntilVisible(original, 120);
    await tester.tap(original);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('option-plan-1:g0:m2:c0:o1')));
    await tester.pumpAndSettle();

    final swapped = find.text('150 gramos de lomo ternera Mercadona');
    expect(swapped, findsOneWidget);

    await tester.tap(swapped);
    await tester.pumpAndSettle();
    // The revert affordance only appears once the item deviates from the plan.
    await tester.tap(find.byKey(const Key('resetComponentOption')));
    await tester.pumpAndSettle();

    expect(original, findsOneWidget);
    expect(swapped, findsNothing);
  });

  testWidgets('flags that some items rest on estimated values',
      (tester) async {
    // Saturday's breakfast uses jamón serrano, which has no USDA equivalent.
    final saturday = NutritionDay.fromDateTime(DateTime.utc(2026, 8, 8));
    await pumpDay(tester, day: saturday);

    expect(find.text('SÁBADO'), findsOneWidget);
    expect(find.text('Some items use estimated values'), findsOneWidget);
  });

  testWidgets('offers a way out when no diet is active', (tester) async {
    await pumpDay(tester, seedPlan: false);

    expect(find.text('Nothing planned for this day'), findsOneWidget);
    expect(find.text('Choose a diet'), findsOneWidget);
  });
}
