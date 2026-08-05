import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/save_entry_as_meal_dialog.dart';

import '../../../../_helpers/pump_app.dart';
import '../../_fakes/fake_saved_meal_source.dart';

NutritionEntry _entry({
  String id = 'e1',
  num kcal = 270,
  num protein = 30,
  num carbs = 20,
  num fat = 10,
  String? plannedMealId,
}) {
  return NutritionEntry(
    id: id,
    recordedAt: DateTime.utc(2026, 8, 1, 13),
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: protein, carbsG: carbs, fatG: fat),
    plannedMealId: plannedMealId,
  );
}

SavedMeal _meal({required String id, required String name}) {
  return SavedMeal(
    id: id,
    name: name,
    target: NutritionTarget(
      energy: Energy(kcal: 300),
      macros: Macros(proteinG: 20, carbsG: 30, fatG: 10),
    ),
    createdAt: DateTime.utc(2026, 8, 1),
  );
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required NutritionEntry entry,
  required FakeSavedMealSource savedMealSource,
}) async {
  await pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => SaveEntryAsMealDialog(entry: entry),
          ),
          child: const Text('open'),
        ),
      ),
    ),
    overrides: [savedMealSourceProvider.overrideWithValue(savedMealSource)],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('SaveEntryAsMealDialog', () {
    testWidgets('shows a required name field, an optional note field, and the '
        'entry macros read-only', (tester) async {
      await _pumpDialog(
        tester,
        entry: _entry(),
        savedMealSource: FakeSavedMealSource(),
      );

      expect(find.byKey(const Key('saveEntryAsMealNameField')), findsOneWidget);
      expect(find.byKey(const Key('saveEntryAsMealNoteField')), findsOneWidget);
      expect(find.text('270 kcal'), findsOneWidget);
      expect(find.text('P 30 · C 20 · F 10'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmSaveEntryAsMealButton')));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('confirming with a name creates a saved meal copying the entry '
        'macros and closes the dialog', (tester) async {
      final savedMealSource = FakeSavedMealSource();
      final entry = _entry();

      await _pumpDialog(tester, entry: entry, savedMealSource: savedMealSource);

      await tester.enterText(
        find.byKey(const Key('saveEntryAsMealNameField')),
        'Post-workout shake',
      );
      await tester.enterText(
        find.byKey(const Key('saveEntryAsMealNoteField')),
        'One scoop, whole milk',
      );
      await tester.tap(find.byKey(const Key('confirmSaveEntryAsMealButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saveEntryAsMealNameField')), findsNothing);

      final result = await savedMealSource.listSavedMeals();
      final meals = (result as Ok<List<SavedMeal>, NutritionFailure>).value;
      expect(meals, hasLength(1));
      expect(meals.single.name, 'Post-workout shake');
      expect(meals.single.portionNote, 'One scoop, whole milk');
      expect(meals.single.target.energy, entry.energy);
      expect(meals.single.target.macros, entry.macros);
    });

    testWidgets(
      'promoting under a name that already exists keeps the dialog open, '
      'shows the error inline, and preserves the typed name',
      (tester) async {
        final savedMealSource = FakeSavedMealSource();
        await savedMealSource.saveMeal(
          _meal(id: 'm1', name: 'Post-workout shake'),
        );

        await _pumpDialog(
          tester,
          entry: _entry(id: 'e2'),
          savedMealSource: savedMealSource,
        );

        await tester.enterText(
          find.byKey(const Key('saveEntryAsMealNameField')),
          'Post-workout shake',
        );
        await tester.tap(find.byKey(const Key('confirmSaveEntryAsMealButton')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('saveEntryAsMealNameField')),
          findsOneWidget,
        );
        expect(find.textContaining('already exists'), findsOneWidget);

        final nameField = tester.widget<TextFormField>(
          find.byKey(const Key('saveEntryAsMealNameField')),
        );
        expect(nameField.controller?.text, 'Post-workout shake');

        final result = await savedMealSource.listSavedMeals();
        final meals = (result as Ok<List<SavedMeal>, NutritionFailure>).value;
        expect(meals, hasLength(1));
      },
    );
  });
}
