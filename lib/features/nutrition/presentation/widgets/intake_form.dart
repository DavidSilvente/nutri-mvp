import 'package:flutter/material.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/composition_editor.dart';

/// What [IntakeForm] currently holds, decided by its active tab.
sealed class IntakeFormValue {
  const IntakeFormValue();
}

/// The Food tab's value: a composition, derived exactly the way saving will
/// derive it — through [DerivedTargets.compose].
class ComposedIntakeFormValue extends IntakeFormValue {
  const ComposedIntakeFormValue(this.composition);
  final DerivedComposition composition;
}

/// The Macros tab's value: hand-typed numbers, already a target.
class ManualIntakeFormValue extends IntakeFormValue {
  const ManualIntakeFormValue(this.target);
  final NutritionTarget target;
}

/// The dual-mode intake form: **Food** (search foods, enter grams, macros
/// derived) or **Macros** (hand-typed, today's original four fields).
///
/// Switching tabs does NOT copy numbers across — a half-built composition
/// silently overwriting hand-typed macros, or the reverse, would be the
/// worst kind of surprise. Each tab keeps its own state; [IntakeFormState]
/// exposes whichever one is currently active through [IntakeFormState.value]
/// and [IntakeFormState.validate], read by the embedding screen at submit
/// time via a [GlobalKey].
///
/// A plain conditional swap — not [TabBarView] — drives the two panes: this
/// form is embedded inside an unbounded [ListView] (see
/// `RecordIntakeScreen`), and [TabBarView] requires a bounded height its
/// host does not give it. [TabBar] still switches the mode with a real tap
/// target; only the swipe-page animation between panes is traded away, which
/// a form has no need for.
class IntakeForm extends StatefulWidget {
  const IntakeForm({
    super.key,
    this.initialTarget,
    this.foodFirstByDefault = true,
  });

  /// Prefill for the Macros tab — a planned meal's target, or a chosen
  /// alternative's macros. Null for a blank entry.
  final NutritionTarget? initialTarget;

  /// Which tab opens selected. Food-first is the DEFAULT for a blank entry
  /// (D1). A caller that already knows the numbers (a non-null
  /// [initialTarget]) should open on Macros instead: pre-filling four known
  /// numbers is strictly better than asking the user to re-derive them from
  /// foods, which is exactly what a prefill exists to avoid — see
  /// `RecordIntakeScreen`'s existing prefill contract.
  final bool foodFirstByDefault;

  @override
  State<IntakeForm> createState() => IntakeFormState();
}

class IntakeFormState extends State<IntakeForm>
    with SingleTickerProviderStateMixin {
  static const foodTabIndex = 0;
  static const macrosTabIndex = 1;

  late final TabController _tabController;
  final _macrosFormKey = GlobalKey<FormState>();
  List<CompositionLine> _lines = const [];
  late final TextEditingController _energyController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  bool get _isFoodTab => _tabController.index == foodTabIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.foodFirstByDefault ? foodTabIndex : macrosTabIndex,
    )..addListener(() => setState(() {}));

    final prefill = widget.initialTarget;
    _energyController = TextEditingController(
      text: prefill == null ? '' : NutritionFormat.amount(prefill.energy.kcal),
    );
    _proteinController = TextEditingController(
      text: prefill == null
          ? ''
          : NutritionFormat.amount(prefill.macros.proteinG),
    );
    _carbsController = TextEditingController(
      text: prefill == null
          ? ''
          : NutritionFormat.amount(prefill.macros.carbsG),
    );
    _fatController = TextEditingController(
      text: prefill == null ? '' : NutritionFormat.amount(prefill.macros.fatG),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _energyController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  /// Validates the active tab. The Food tab has none — an empty or partial
  /// composition is a valid submission, matching [DerivedTargets.compose]'s
  /// own "never fails" contract.
  bool validate() => _isFoodTab || _macrosFormKey.currentState!.validate();

  /// The value the active tab currently holds.
  IntakeFormValue get value => _isFoodTab
      ? ComposedIntakeFormValue(_compose())
      : ManualIntakeFormValue(_manualTarget());

  NutritionTarget _manualTarget() => NutritionTarget(
    energy: Energy(kcal: num.parse(_energyController.text)),
    macros: Macros(
      proteinG: num.parse(_proteinController.text),
      carbsG: num.parse(_carbsController.text),
      fatG: num.parse(_fatController.text),
    ),
  );

  /// Derived exactly the way saving will derive it: through
  /// [DerivedTargets.compose], over a catalog built from just this form's
  /// own resolved lines. Every line here comes fresh from [FoodPickerSheet],
  /// so all of them resolve — there is no edit-path unresolved case on this
  /// (create-only) form, unlike `CompositionEditor`'s own reuse in slice 7.
  DerivedComposition _compose() {
    final byId = <String, FoodItem>{};
    for (final line in _lines) {
      if (line.food case final food?) byId[food.id] = food;
    }
    return DerivedTargets.compose([
      for (final line in _lines) line.toIngredient(),
    ], FoodCatalog(byId.values));
  }

  String? _requiredNonNegativeNumber(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    final parsed = num.tryParse(value);
    if (parsed == null || parsed < 0) return 'Debe ser un número >= 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(key: Key('foodFirstTab'), text: 'Food'),
            Tab(key: Key('manualEntryTab'), text: 'Macros'),
          ],
        ),
        const SizedBox(height: 16),
        if (_isFoodTab)
          CompositionEditor(
            lines: _lines,
            onChanged: (lines) => setState(() => _lines = lines),
          )
        else
          Form(
            key: _macrosFormKey,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('energyField'),
                  controller: _energyController,
                  decoration: const InputDecoration(labelText: 'Energía (kcal)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNonNegativeNumber,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('proteinField'),
                  controller: _proteinController,
                  decoration: const InputDecoration(labelText: 'Proteína (g)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNonNegativeNumber,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('carbsField'),
                  controller: _carbsController,
                  decoration: const InputDecoration(
                    labelText: 'Carbohidratos (g)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNonNegativeNumber,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('fatField'),
                  controller: _fatController,
                  decoration: const InputDecoration(labelText: 'Grasa (g)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNonNegativeNumber,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
