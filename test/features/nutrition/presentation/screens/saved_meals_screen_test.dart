import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/saved_meals_screen.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_saved_meal_source.dart';

NutritionTarget _target({
  double kcal = 300,
  double proteinG = 20,
  double carbsG = 30,
  double fatG = 10,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
  );
}

SavedMeal _meal({required String id, required String name}) {
  return SavedMeal(
    id: id,
    name: name,
    target: _target(),
    createdAt: DateTime.utc(2026, 8, 1),
  );
}

Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String name = 'Tuna bowl',
  String kcal = '450',
  String protein = '35',
  String carbs = '40',
  String fat = '12',
}) async {
  await tester.enterText(find.byKey(const Key('savedMealNameField')), name);
  await tester.enterText(find.byKey(const Key('savedMealEnergyField')), kcal);
  await tester.enterText(
    find.byKey(const Key('savedMealProteinField')),
    protein,
  );
  await tester.enterText(find.byKey(const Key('savedMealCarbsField')), carbs);
  await tester.enterText(find.byKey(const Key('savedMealFatField')), fat);
  await tester.tap(find.byKey(const Key('saveSavedMealButton')));
  await tester.pumpAndSettle();
}

void main() {
  group('SavedMealsScreen', () {
    testWidgets('shows an empty message with a CTA when there are no meals', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const SavedMealsScreen(),
        overrides: [
          savedMealSourceProvider.overrideWithValue(FakeSavedMealSource()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('No saved meals yet'), findsOneWidget);
      expect(find.byKey(const Key('addSavedMealButton')), findsOneWidget);
    });

    testWidgets('lists saved meals from the controller', (tester) async {
      final fake = FakeSavedMealSource();
      await fake.saveMeal(_meal(id: 'm1', name: 'Chicken salad'));

      await pumpApp(
        tester,
        const SavedMealsScreen(),
        overrides: [savedMealSourceProvider.overrideWithValue(fake)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Chicken salad'), findsOneWidget);
      expect(find.text('300 kcal'), findsOneWidget);
      expect(find.text('P 20 · C 30 · F 10'), findsOneWidget);
    });

    testWidgets('creating a meal through the dialog adds it to the list', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const SavedMealsScreen(),
        overrides: [
          savedMealSourceProvider.overrideWithValue(FakeSavedMealSource()),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addSavedMealButton')));
      await tester.pumpAndSettle();
      await _fillAndSubmit(tester);

      expect(find.text('Tuna bowl'), findsOneWidget);
      expect(find.text('450 kcal'), findsOneWidget);
    });

    testWidgets('deleting a meal removes it after confirming', (tester) async {
      final fake = FakeSavedMealSource();
      await fake.saveMeal(_meal(id: 'm1', name: 'Chicken salad'));

      await pumpApp(
        tester,
        const SavedMealsScreen(),
        overrides: [savedMealSourceProvider.overrideWithValue(fake)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteSavedMeal-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteSavedMeal')));
      await tester.pumpAndSettle();

      expect(find.text('Chicken salad'), findsNothing);
      expect(find.text('No saved meals yet'), findsOneWidget);
    });

    testWidgets('cancelling the delete confirmation keeps the meal', (
      tester,
    ) async {
      final fake = FakeSavedMealSource();
      await fake.saveMeal(_meal(id: 'm1', name: 'Chicken salad'));

      await pumpApp(
        tester,
        const SavedMealsScreen(),
        overrides: [savedMealSourceProvider.overrideWithValue(fake)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteSavedMeal-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Chicken salad'), findsOneWidget);
    });

    testWidgets(
      'creating a duplicate (trimmed/case-insensitive) name keeps the dialog '
      'open, shows the error inline, and preserves what was typed',
      (tester) async {
        final fake = FakeSavedMealSource();
        await fake.saveMeal(_meal(id: 'm1', name: 'Chicken salad'));

        await pumpApp(
          tester,
          const SavedMealsScreen(),
          overrides: [savedMealSourceProvider.overrideWithValue(fake)],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('addSavedMealButton')));
        await tester.pumpAndSettle();
        await _fillAndSubmit(tester, name: ' chicken SALAD ');

        // The dialog is still open — the failure never lost the form.
        expect(find.byKey(const Key('savedMealNameField')), findsOneWidget);
        expect(find.textContaining('already exists'), findsOneWidget);

        // Nothing the user typed was lost: they can just fix the name.
        final nameField = tester.widget<TextFormField>(
          find.byKey(const Key('savedMealNameField')),
        );
        expect(nameField.controller?.text, ' chicken SALAD ');
        final energyField = tester.widget<TextFormField>(
          find.byKey(const Key('savedMealEnergyField')),
        );
        expect(energyField.controller?.text, '450');

        // The underlying catalogue kept its original, unchanged entry — no
        // duplicate was created, and the screen never blanked out.
        expect(find.text('Chicken salad'), findsOneWidget);
      },
    );

    testWidgets(
      'fixing the name after a duplicate-name failure and resubmitting '
      'saves the meal and closes the dialog',
      (tester) async {
        final fake = FakeSavedMealSource();
        await fake.saveMeal(_meal(id: 'm1', name: 'Chicken salad'));

        await pumpApp(
          tester,
          const SavedMealsScreen(),
          overrides: [savedMealSourceProvider.overrideWithValue(fake)],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('addSavedMealButton')));
        await tester.pumpAndSettle();
        await _fillAndSubmit(tester, name: ' chicken SALAD ');
        expect(find.textContaining('already exists'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('savedMealNameField')),
          'Tuna bowl',
        );
        await tester.tap(find.byKey(const Key('saveSavedMealButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('savedMealNameField')), findsNothing);
        expect(find.text('Tuna bowl'), findsOneWidget);
        expect(find.text('Chicken salad'), findsOneWidget);
      },
    );

    testWidgets('editing macros without renaming updates the meal without a '
        'false-positive conflict', (tester) async {
      final fake = FakeSavedMealSource();
      await fake.saveMeal(_meal(id: 'm1', name: 'Chicken salad'));

      await pumpApp(
        tester,
        const SavedMealsScreen(),
        overrides: [savedMealSourceProvider.overrideWithValue(fake)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editSavedMeal-m1')));
      await tester.pumpAndSettle();

      // Pre-filled with the existing values.
      final nameField = tester.widget<TextFormField>(
        find.byKey(const Key('savedMealNameField')),
      );
      expect(nameField.controller?.text, 'Chicken salad');

      await tester.enterText(
        find.byKey(const Key('savedMealEnergyField')),
        '500',
      );
      await tester.tap(find.byKey(const Key('saveSavedMealButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('savedMealNameField')), findsNothing);
      expect(find.text('500 kcal'), findsOneWidget);
      expect(find.text('Chicken salad'), findsOneWidget);
    });

    testWidgets(
      'renaming a meal to another existing meal\'s (trimmed/case-insensitive) '
      'name keeps the dialog open with the typed name and shows the error',
      (tester) async {
        final fake = FakeSavedMealSource();
        await fake.saveMeal(_meal(id: 'm1', name: 'Chicken salad'));
        await fake.saveMeal(_meal(id: 'm2', name: 'Tuna bowl'));

        await pumpApp(
          tester,
          const SavedMealsScreen(),
          overrides: [savedMealSourceProvider.overrideWithValue(fake)],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('editSavedMeal-m2')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('savedMealNameField')),
          ' CHICKEN salad ',
        );
        await tester.tap(find.byKey(const Key('saveSavedMealButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('savedMealNameField')), findsOneWidget);
        expect(find.textContaining('already exists'), findsOneWidget);
        final nameField = tester.widget<TextFormField>(
          find.byKey(const Key('savedMealNameField')),
        );
        expect(nameField.controller?.text, ' CHICKEN salad ');

        // Both original meals are unchanged — the rename never applied.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Chicken salad'), findsOneWidget);
        expect(find.text('Tuna bowl'), findsOneWidget);
      },
    );

    testWidgets('a name filter narrows the list case-insensitively', (
      tester,
    ) async {
      final fake = FakeSavedMealSource();
      await fake.saveMeal(_meal(id: 'm1', name: 'Chicken salad'));
      await fake.saveMeal(_meal(id: 'm2', name: 'Tuna bowl'));

      await pumpApp(
        tester,
        const SavedMealsScreen(),
        overrides: [savedMealSourceProvider.overrideWithValue(fake)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Chicken salad'), findsOneWidget);
      expect(find.text('Tuna bowl'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('savedMealNameFilter')),
        'CHICK',
      );
      await tester.pumpAndSettle();

      expect(find.text('Chicken salad'), findsOneWidget);
      expect(find.text('Tuna bowl'), findsNothing);
    });
  });
}
