import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_template_editor_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_templates_screen.dart';

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
  group('DietTemplateEditorScreen', () {
    testWidgets('create mode shows empty form', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
          ],
          child: const MaterialApp(
            home: DietTemplateEditorScreen(templateId: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create diet template'), findsOneWidget);
      expect(find.byKey(const Key('templateNameField')), findsOneWidget);
      expect(find.byKey(const Key('dailyKcalField')), findsOneWidget);
      expect(find.byKey(const Key('addSlotButton')), findsOneWidget);
      expect(find.byKey(const Key('saveTemplateButton')), findsOneWidget);
    });

    testWidgets('edit mode loads existing template data', (tester) async {
      final fake = FakeDietPlanSource();
      final template = _template(id: 't1', name: 'Cut-A');
      await fake.saveTemplate(template);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dietPlanSourceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(
            home: DietTemplateEditorScreen(templateId: 't1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit diet template'), findsOneWidget);
      expect(find.text('Cut-A'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('edits an existing template and persists changes', (
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
            target: _target(kcal: 700, proteinG: 40, carbsG: 60, fatG: 20),
          ),
        ],
      );
      await fake.saveTemplate(template);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dietPlanSourceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(
            home: DietTemplateEditorScreen(templateId: 't1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit diet template'), findsOneWidget);
      expect(find.text('Cut-A'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('templateNameField')),
        'Cut-A-Updated',
      );
      await tester.enterText(
        find.byKey(const Key('slotLabelField_0')),
        'Morning',
      );
      await tester.enterText(
        find.byKey(const Key('slotKcalField_0')),
        '800',
      );
      await tester.enterText(
        find.byKey(const Key('dailyKcalField')),
        '800',
      );

      await tester.tap(find.byKey(const Key('saveTemplateButton')));
      await tester.pumpAndSettle();

      expect(find.byType(DietTemplateEditorScreen), findsNothing);

      final result = await fake.listTemplates();
      final templates = switch (result) {
        Ok(value: final list) => list,
        Err() => throw StateError('expected Ok'),
      };
      expect(templates.length, 1);
      final persisted = templates.first;
      expect(persisted.id, 't1');
      expect(persisted.name, 'Cut-A-Updated');
      expect(persisted.dailyTarget.energy.kcal, 800);
      expect(persisted.slots.length, 1);
      expect(persisted.slots[0].label, 'Morning');
      expect(persisted.slots[0].target.energy.kcal, 800);
      expect(persisted.slots[0].target.macros.proteinG, 40);
    });

    testWidgets('saves a new template and pops', (tester) async {
      final fake = FakeDietPlanSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dietPlanSourceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(
            home: DietTemplateEditorScreen(templateId: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('templateNameField')),
        'Cut-A',
      );
      await tester.enterText(
        find.byKey(const Key('dailyKcalField')),
        '1500',
      );
      await tester.enterText(
        find.byKey(const Key('dailyProteinField')),
        '90',
      );
      await tester.enterText(
        find.byKey(const Key('dailyCarbsField')),
        '130',
      );
      await tester.enterText(
        find.byKey(const Key('dailyFatField')),
        '45',
      );

      await tester.tap(find.byKey(const Key('addSlotButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('slotLabelField_0')),
        'Breakfast',
      );
      await tester.enterText(
        find.byKey(const Key('slotKcalField_0')),
        '1500',
      );
      await tester.enterText(
        find.byKey(const Key('slotProteinField_0')),
        '90',
      );
      await tester.enterText(
        find.byKey(const Key('slotCarbsField_0')),
        '130',
      );
      await tester.enterText(
        find.byKey(const Key('slotFatField_0')),
        '45',
      );

      await tester.tap(find.byKey(const Key('saveTemplateButton')));
      await tester.pumpAndSettle();

      expect(find.byType(DietTemplateEditorScreen), findsNothing);
      final result = await fake.listTemplates();
      final templates = switch (result) {
        Ok(value: final list) => list,
        Err() => throw StateError('expected Ok'),
      };
      expect(templates.length, 1);
      expect(templates.first.name, 'Cut-A');
      expect(templates.first.dailyTarget.energy.kcal, 1500);
      expect(templates.first.slots.length, 1);
      expect(templates.first.slots.first.label, 'Breakfast');
    });

    testWidgets('shows error when slot targets do not sum to daily target', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
          ],
          child: const MaterialApp(
            home: DietTemplateEditorScreen(templateId: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('templateNameField')),
        'Cut-A',
      );
      await tester.enterText(
        find.byKey(const Key('dailyKcalField')),
        '1500',
      );
      await tester.enterText(
        find.byKey(const Key('dailyProteinField')),
        '90',
      );
      await tester.enterText(
        find.byKey(const Key('dailyCarbsField')),
        '130',
      );
      await tester.enterText(
        find.byKey(const Key('dailyFatField')),
        '45',
      );

      await tester.tap(find.byKey(const Key('addSlotButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('slotLabelField_0')),
        'Breakfast',
      );
      await tester.enterText(
        find.byKey(const Key('slotKcalField_0')),
        '700',
      );
      await tester.enterText(
        find.byKey(const Key('slotProteinField_0')),
        '40',
      );
      await tester.enterText(
        find.byKey(const Key('slotCarbsField_0')),
        '60',
      );
      await tester.enterText(
        find.byKey(const Key('slotFatField_0')),
        '20',
      );

      await tester.tap(find.byKey(const Key('saveTemplateButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Slot targets must sum to the daily target'),
        findsOneWidget,
      );
    });

    testWidgets('duplicate template name shows error', (tester) async {
      final fake = FakeDietPlanSource();
      final template = _template(id: 't1', name: 'Cut-A');
      await fake.saveTemplate(template);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dietPlanSourceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(
            home: DietTemplateEditorScreen(templateId: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('templateNameField')),
        'Cut-A',
      );
      await tester.enterText(
        find.byKey(const Key('dailyKcalField')),
        '1500',
      );
      await tester.enterText(
        find.byKey(const Key('dailyProteinField')),
        '90',
      );
      await tester.enterText(
        find.byKey(const Key('dailyCarbsField')),
        '130',
      );
      await tester.enterText(
        find.byKey(const Key('dailyFatField')),
        '45',
      );

      await tester.tap(find.byKey(const Key('addSlotButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('slotLabelField_0')),
        'All',
      );
      await tester.enterText(
        find.byKey(const Key('slotKcalField_0')),
        '1500',
      );
      await tester.enterText(
        find.byKey(const Key('slotProteinField_0')),
        '90',
      );
      await tester.enterText(
        find.byKey(const Key('slotCarbsField_0')),
        '130',
      );
      await tester.enterText(
        find.byKey(const Key('slotFatField_0')),
        '45',
      );

      await tester.tap(find.byKey(const Key('saveTemplateButton')));
      await tester.pumpAndSettle();

      expect(find.text('Template name "Cut-A" already exists'), findsOneWidget);
    });
  });

  group('DietTemplatesScreen editor navigation', () {
    testWidgets('FAB navigates to editor for create', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
          ],
          child: const MaterialApp(home: DietTemplatesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addTemplateButton')));
      await tester.pumpAndSettle();

      expect(find.byType(DietTemplateEditorScreen), findsOneWidget);
      expect(find.text('Create diet template'), findsOneWidget);
    });

    testWidgets('tile tap navigates to editor for edit', (tester) async {
      final fake = FakeDietPlanSource();
      final template = _template(id: 't1', name: 'Cut-A');
      await fake.saveTemplate(template);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dietPlanSourceProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(home: DietTemplatesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('templateTile_0')));
      await tester.pumpAndSettle();

      expect(find.byType(DietTemplateEditorScreen), findsOneWidget);
      expect(find.text('Edit diet template'), findsOneWidget);
    });
  });
}
