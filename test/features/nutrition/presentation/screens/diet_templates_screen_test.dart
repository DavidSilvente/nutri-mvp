import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_template_editor_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_templates_screen.dart';

import '../../../../_helpers/pump_app.dart';
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
          id: '${id}_slot',
          label: 'Meal',
          position: 0,
          target: _target(kcal: 700),
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
  group('DietTemplatesScreen', () {
    testWidgets('shows an empty message when there are no templates', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const DietTemplatesScreen(),
        overrides: [
          dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('No diet templates yet'), findsOneWidget);
    });

    testWidgets('lists templates from the controller', (tester) async {
      final fake = FakeDietPlanSource();
      final template = _template(id: 't1', name: 'Cut-A');
      await fake.saveTemplate(template);

      await pumpApp(
        tester,
        const DietTemplatesScreen(),
        overrides: [dietPlanSourceProvider.overrideWithValue(fake)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Cut-A'), findsOneWidget);
      expect(find.text('700 kcal'), findsOneWidget);
      expect(find.text('P 40 · C 60 · F 20'), findsOneWidget);
      expect(find.text('1 meal a day'), findsOneWidget);
    });

    testWidgets('FAB navigates to the editor for create', (tester) async {
      await pumpApp(
        tester,
        const DietTemplatesScreen(),
        overrides: [
          dietPlanSourceProvider.overrideWithValue(FakeDietPlanSource()),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addTemplateButton')));
      await tester.pumpAndSettle();

      expect(find.byType(DietTemplateEditorScreen), findsOneWidget);
      expect(find.text('Create diet template'), findsOneWidget);
    });
  });
}
