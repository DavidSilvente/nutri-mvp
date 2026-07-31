import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_template_editor_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/planned_meal_screen.dart';

import '../../_fakes/fake_diet_plan_source.dart';

NutritionTarget _target({
  double kcal = 700,
  double proteinG = 40,
  double carbsG = 60,
  double fatG = 20,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
  );
}

DietTemplate _template({
  required String id,
  required String name,
  List<DietMealSlot>? slots,
}) {
  final resolvedSlots = slots ??
      [
        DietMealSlot(
          id: '${id}_slot_0',
          label: 'Breakfast',
          position: 0,
          target: _target(kcal: 700, proteinG: 40, carbsG: 60, fatG: 20),
        ),
        DietMealSlot(
          id: '${id}_slot_1',
          label: 'Lunch',
          position: 1,
          target: _target(kcal: 800, proteinG: 50, carbsG: 70, fatG: 25),
        ),
      ];
  return DietTemplate(
    id: id,
    name: name,
    dailyTarget: NutritionTarget.sum(resolvedSlots.map((s) => s.target)),
    slots: resolvedSlots,
  );
}

void main() {
  group('PlannedMealScreen', () {
    testWidgets('assign mode saves a planned meal for the selected day', (
      tester,
    ) async {
      final fake = FakeDietPlanSource();
      final template = _template(id: 't1', name: 'Cut-A');
      await fake.saveTemplate(template);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dietPlanSourceProvider.overrideWithValue(fake)],
          child: MaterialApp(
            home: PlannedMealScreen.assign(
              templateId: 't1',
              slotId: 't1_slot_0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan meal'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('dateField')), '2026-08-01');
      await tester.tap(find.byKey(const Key('savePlannedMealButton')));
      await tester.pumpAndSettle();

      expect(find.byType(PlannedMealScreen), findsNothing);

      final result = await fake.listPlannedMeals();
      final meals = switch (result) {
        Ok(value: final list) => list,
        Err() => throw StateError('expected Ok'),
      };
      expect(meals.length, 1);
      final meal = meals.first;
      expect(meal.slotId, 't1_slot_0');
      expect(meal.day, NutritionDay.fromDateTime(DateTime(2026, 8, 1)));
      expect(meal.targetSnapshot, template.slots[0].target);
    });

    testWidgets('edit mode allows reassigning to a different slot', (
      tester,
    ) async {
      final fake = FakeDietPlanSource();
      final template = _template(id: 't1', name: 'Cut-A');
      await fake.saveTemplate(template);

      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      final originalMeal = PlannedMeal(
        id: 'm1',
        slotId: 't1_slot_0',
        day: day,
        targetSnapshot: template.slots[0].target,
      );
      await fake.savePlannedMeal(originalMeal);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dietPlanSourceProvider.overrideWithValue(fake)],
          child: MaterialApp(
            home: PlannedMealScreen.edit(plannedMealId: 'm1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit planned meal'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);

      await tester.tap(find.byKey(const Key('slotDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lunch').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('savePlannedMealButton')));
      await tester.pumpAndSettle();

      expect(find.byType(PlannedMealScreen), findsNothing);

      final result = await fake.listPlannedMeals();
      final meals = switch (result) {
        Ok(value: final list) => list,
        Err() => throw StateError('expected Ok'),
      };
      expect(meals.length, 1);
      final meal = meals.first;
      expect(meal.id, 'm1');
      expect(meal.slotId, 't1_slot_1');
      expect(meal.targetSnapshot, template.slots[1].target);
    });

    testWidgets('duplicate same-day assignment shows conflict error', (
      tester,
    ) async {
      final fake = FakeDietPlanSource();
      final template = _template(
        id: 't1',
        name: 'Cut-A',
        slots: [
          DietMealSlot(
            id: 't1_slot_0',
            label: 'Breakfast',
            position: 0,
            target: _target(),
          ),
        ],
      );
      await fake.saveTemplate(template);

      final day = NutritionDay.fromDateTime(DateTime(2026, 8, 1));
      await fake.savePlannedMeal(
        PlannedMeal(
          id: 'm1',
          slotId: 't1_slot_0',
          day: day,
          targetSnapshot: template.slots[0].target,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dietPlanSourceProvider.overrideWithValue(fake)],
          child: MaterialApp(
            home: PlannedMealScreen.assign(
              templateId: 't1',
              slotId: 't1_slot_0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('dateField')), '2026-08-01');
      await tester.tap(find.byKey(const Key('savePlannedMealButton')));
      await tester.pumpAndSettle();

      expect(find.byType(PlannedMealScreen), findsOneWidget);
      expect(find.textContaining('already planned'), findsOneWidget);
    });

    testWidgets('rejects calendar overflow dates like 2026-02-31', (tester) async {
      final fake = FakeDietPlanSource();
      final template = _template(
        id: 't1',
        name: 'Cut-A',
        slots: [
          DietMealSlot(
            id: 't1_slot_0',
            label: 'Breakfast',
            position: 0,
            target: _target(),
          ),
        ],
      );
      await fake.saveTemplate(template);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dietPlanSourceProvider.overrideWithValue(fake)],
          child: MaterialApp(
            home: PlannedMealScreen.assign(
              templateId: 't1',
              slotId: 't1_slot_0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('dateField')), '2026-02-31');
      await tester.tap(find.byKey(const Key('savePlannedMealButton')));
      await tester.pumpAndSettle();

      expect(find.byType(PlannedMealScreen), findsOneWidget);
      expect(find.text('Use yyyy-MM-dd'), findsOneWidget);

      final result = await fake.listPlannedMeals();
      final meals = switch (result) {
        Ok(value: final list) => list,
        Err() => throw StateError('expected Ok'),
      };
      expect(meals, isEmpty);
    });

    testWidgets('rejects out of range month and day values', (tester) async {
      final fake = FakeDietPlanSource();
      final template = _template(
        id: 't1',
        name: 'Cut-A',
        slots: [
          DietMealSlot(
            id: 't1_slot_0',
            label: 'Breakfast',
            position: 0,
            target: _target(),
          ),
        ],
      );
      await fake.saveTemplate(template);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dietPlanSourceProvider.overrideWithValue(fake)],
          child: MaterialApp(
            home: PlannedMealScreen.assign(
              templateId: 't1',
              slotId: 't1_slot_0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('dateField')), '2026-13-01');
      await tester.tap(find.byKey(const Key('savePlannedMealButton')));
      await tester.pumpAndSettle();

      expect(find.byType(PlannedMealScreen), findsOneWidget);
      expect(find.text('Use yyyy-MM-dd'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('dateField')), '2026-00-10');
      await tester.tap(find.byKey(const Key('savePlannedMealButton')));
      await tester.pumpAndSettle();

      expect(find.byType(PlannedMealScreen), findsOneWidget);
      expect(find.text('Use yyyy-MM-dd'), findsOneWidget);

      final result = await fake.listPlannedMeals();
      final meals = switch (result) {
        Ok(value: final list) => list,
        Err() => throw StateError('expected Ok'),
      };
      expect(meals, isEmpty);
    });

    testWidgets('shows deferred substitutes section', (tester) async {
      final fake = FakeDietPlanSource();
      final template = _template(
        id: 't1',
        name: 'Cut-A',
        slots: [
          DietMealSlot(
            id: 't1_slot_0',
            label: 'Breakfast',
            position: 0,
            target: _target(),
          ),
        ],
      );
      await fake.saveTemplate(template);
      await fake.savePlannedMeal(
        PlannedMeal(
          id: 'm1',
          slotId: 't1_slot_0',
          day: NutritionDay.fromDateTime(DateTime(2026, 8, 1)),
          targetSnapshot: template.slots[0].target,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dietPlanSourceProvider.overrideWithValue(fake)],
          child: MaterialApp(
            home: PlannedMealScreen.edit(plannedMealId: 'm1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Substitutes'), findsOneWidget);
      expect(
        find.text('Substitute suggestions will appear here after menu capture.'),
        findsOneWidget,
      );
    });
  });

  group('DietTemplateEditorScreen planned-meal navigation', () {
    testWidgets('plan button on a slot opens PlannedMealScreen', (
      tester,
    ) async {
      final fake = FakeDietPlanSource();
      final template = _template(
        id: 't1',
        name: 'Cut-A',
        slots: [
          DietMealSlot(
            id: 't1_slot_0',
            label: 'Breakfast',
            position: 0,
            target: _target(),
          ),
        ],
      );
      await fake.saveTemplate(template);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dietPlanSourceProvider.overrideWithValue(fake)],
          child: const MaterialApp(
            home: DietTemplateEditorScreen(templateId: 't1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('planSlotButton_0')));
      await tester.pumpAndSettle();

      expect(find.byType(PlannedMealScreen), findsOneWidget);
      expect(find.text('Plan meal'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
    });
  });
}
