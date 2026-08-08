import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/composition_editor.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_diet_plan_store.dart';

void main() {
  /// A tiny controlled harness: owns [lines] the way a real screen would,
  /// and re-pumps [CompositionEditor] with whatever it reports back.
  Future<void> pumpEditor(
    WidgetTester tester,
    List<CompositionLine> initial,
  ) async {
    var lines = initial;
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => CompositionEditor(
              lines: lines,
              onChanged: (updated) => setState(() => lines = updated),
            ),
          ),
        ),
      ),
      overrides: [
        foodTableSourceProvider.overrideWithValue(FakeFoodTableSource()),
      ],
    );
  }

  final chicken = FakeFoodTableSource.food(
    'chicken_breast_grilled',
    name: 'Pollo, pechuga',
    kcal: 200,
    proteinG: 30,
    carbsG: 0,
    fatG: 5,
  );

  testWidgets('renders a resolved line with its name and derived kcal', (
    tester,
  ) async {
    await pumpEditor(tester, [
      CompositionLine.resolved(
        resolvedFood: chicken,
        quantity: FoodQuantity(grams: 100),
      ),
    ]);

    expect(find.text('Pollo, pechuga'), findsOneWidget);
    expect(find.byKey(const Key('compositionGramsField-0')), findsOneWidget);
    expect(find.text('200'), findsOneWidget); // per-line derived kcal
    expect(find.byKey(const Key('compositionTotalKcal')), findsOneWidget);
  });

  testWidgets('flags an unresolved line, disables its grams field, and zero '
      'weights it in the total', (tester) async {
    await pumpEditor(tester, [
      CompositionLine.resolved(
        resolvedFood: chicken,
        quantity: FoodQuantity(grams: 100),
      ),
      CompositionLine.unresolved(
        foodId: 'vanished_food',
        quantity: FoodQuantity(grams: 50),
      ),
    ]);

    expect(find.text('Unresolved food'), findsOneWidget);
    expect(find.byKey(const Key('unresolvedIcon-1')), findsOneWidget);

    final gramsField = tester.widget<TextField>(
      find.byKey(const Key('compositionGramsField-1')),
    );
    expect(gramsField.enabled, isFalse);

    // Total is chicken's 200 kcal alone — the unresolved line contributes 0.
    final total = tester.widget<Text>(
      find.byKey(const Key('compositionTotalKcal')),
    );
    expect(total.data, '200 kcal');
  });

  testWidgets('editing grams updates the derived total live', (tester) async {
    await pumpEditor(tester, [
      CompositionLine.resolved(
        resolvedFood: chicken,
        quantity: FoodQuantity(grams: 100),
      ),
    ]);

    await tester.enterText(
      find.byKey(const Key('compositionGramsField-0')),
      '50',
    );
    await tester.pump();

    final total = tester.widget<Text>(
      find.byKey(const Key('compositionTotalKcal')),
    );
    expect(total.data, '100 kcal'); // half the grams, half the kcal
  });

  testWidgets('removing a line drops it from the total', (tester) async {
    final rice = FakeFoodTableSource.food(
      'rice_white_raw',
      name: 'Arroz blanco',
      kcal: 100,
      proteinG: 2,
      carbsG: 20,
      fatG: 0,
    );
    await pumpEditor(tester, [
      CompositionLine.resolved(
        resolvedFood: chicken,
        quantity: FoodQuantity(grams: 100),
      ),
      CompositionLine.resolved(
        resolvedFood: rice,
        quantity: FoodQuantity(grams: 100),
      ),
    ]);

    var total = tester.widget<Text>(
      find.byKey(const Key('compositionTotalKcal')),
    );
    expect(total.data, '300 kcal');

    await tester.tap(find.byKey(const Key('removeCompositionLineButton-1')));
    await tester.pumpAndSettle();

    total = tester.widget<Text>(find.byKey(const Key('compositionTotalKcal')));
    expect(total.data, '200 kcal');
    expect(find.text('Arroz blanco'), findsNothing);
  });

  testWidgets('adding a food through the picker appends a resolved line', (
    tester,
  ) async {
    await pumpEditor(tester, []);

    await tester.tap(find.byKey(const Key('addFoodButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('foodSearchField')), 'jamon');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('candidateOption-ham_serrano')));
    await tester.pumpAndSettle();

    expect(find.text('Jamón serrano'), findsOneWidget);
    expect(find.byKey(const Key('compositionGramsField-0')), findsOneWidget);
  });

  test('CompositionLine.fromIngredient resolves a known id and preserves an '
      'unknown one', () {
    final foodCatalog = FoodCatalog(FakeFoodTableSource.defaultFoods());

    final resolved = CompositionLine.fromIngredient(
      LoggedIngredient(
        foodId: 'chicken_breast_grilled',
        quantity: FoodQuantity(grams: 120),
      ),
      foodCatalog,
    );
    expect(resolved.isResolved, isTrue);
    expect(resolved.food!.id, 'chicken_breast_grilled');

    final unresolved = CompositionLine.fromIngredient(
      LoggedIngredient(
        foodId: 'vanished_food',
        quantity: FoodQuantity(grams: 50),
      ),
      foodCatalog,
    );
    expect(unresolved.isResolved, isFalse);
    expect(unresolved.foodId, 'vanished_food');
  });
}
