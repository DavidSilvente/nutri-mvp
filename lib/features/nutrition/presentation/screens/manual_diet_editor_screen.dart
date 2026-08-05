import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/number_field.dart';

/// Writes a diet by hand: a name and the meals of a typical day, each with the
/// macros it should hit.
///
/// The result is stored as a plan document, exactly like an imported PDF, so the
/// day view, the calendar and adherence read it through the same path and never
/// need to know it was typed rather than imported.
///
/// [planId] is null when creating. Editing an existing diet REUSES its slot ids,
/// because the calendar's planned meals point at them; that is why each row
/// carries an id rather than being identified by its position.
class ManualDietEditorScreen extends ConsumerWidget {
  const ManualDietEditorScreen({super.key, this.planId});

  final String? planId;

  bool get _isCreate => planId == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = Text(_isCreate ? 'New diet' : 'Edit diet');

    if (planId case final id?) {
      final dietAsync = ref.watch(storedDietProvider(id));
      return dietAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: title),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: title),
          body: _Message(text: _describe(error)),
        ),
        data: (diet) {
          if (diet == null) {
            return Scaffold(
              appBar: AppBar(title: title),
              body: const _Message(text: 'This diet no longer exists.'),
            );
          }

          final slots = diet.plan.dayGroups
              .expand((group) => group.template.slots)
              .toList(growable: false);

          // A plan read from a PDF carries the foods it prescribes, and this
          // editor only knows how to type macros. Offering to "edit" it would
          // mean replacing prescribed foods with bare totals, so it says no
          // instead — the way to change an imported plan is to re-import it.
          if (slots.any((slot) => slot.isDerived)) {
            return Scaffold(
              appBar: AppBar(title: title),
              body: const _Message(
                key: Key('importedDietNotEditable'),
                text:
                    'This diet came from a PDF, so its meals are made of '
                    'foods rather than typed macros. Import the PDF again to '
                    'change it.',
              ),
            );
          }

          return _EditorScaffold(
            title: title,
            planId: id,
            initialName: diet.plan.name,
            initialSlots: slots,
          );
        },
      );
    }

    return _EditorScaffold(title: title, initialSlots: const []);
  }

  static String _describe(Object error) {
    if (error is HealthFailureException) {
      return switch (error.failure) {
        MalformedPlanFailure(reason: final reason) => reason,
        StorageFailure(reason: final reason) => reason,
        _ => 'Could not load this diet.',
      };
    }
    return error.toString();
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _EditorScaffold extends ConsumerStatefulWidget {
  const _EditorScaffold({
    required this.title,
    required this.initialSlots,
    this.planId,
    this.initialName,
  });

  final Widget title;
  final String? planId;
  final String? initialName;
  final List<DietMealSlot> initialSlots;

  @override
  ConsumerState<_EditorScaffold> createState() => _EditorScaffoldState();
}

/// The editable state of one meal row.
///
/// Carries [id] so an edit reuses the slot identity the calendar already points
/// at, instead of the row's position standing in for it.
class _MealRow {
  _MealRow({required this.id});

  factory _MealRow.fromSlot(DietMealSlot slot) {
    final row = _MealRow(id: slot.id);
    row.label.text = slot.label;
    row.kcal.text = _plain(slot.target.energy.kcal);
    row.protein.text = _plain(slot.target.macros.proteinG);
    row.carbs.text = _plain(slot.target.macros.carbsG);
    row.fat.text = _plain(slot.target.macros.fatG);
    return row;
  }

  final String id;
  final TextEditingController label = TextEditingController();
  final TextEditingController kcal = TextEditingController();
  final TextEditingController protein = TextEditingController();
  final TextEditingController carbs = TextEditingController();
  final TextEditingController fat = TextEditingController();

  void dispose() {
    label.dispose();
    kcal.dispose();
    protein.dispose();
    carbs.dispose();
    fat.dispose();
  }

  NutritionTarget readTarget() => NutritionTarget(
    energy: Energy(kcal: _parse(kcal.text)),
    macros: Macros(
      proteinG: _parse(protein.text),
      carbsG: _parse(carbs.text),
      fatG: _parse(fat.text),
    ),
  );

  DietMealSlot readSlot(int position) => DietMealSlot(
    id: id,
    label: label.text.trim(),
    position: position,
    target: readTarget(),
  );

  static double _parse(String text) =>
      num.tryParse(text.trim())?.toDouble() ?? 0;

  /// Whole numbers without a trailing `.0`, since that is how they were typed.
  static String _plain(num value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();
}

class _EditorScaffoldState extends ConsumerState<_EditorScaffold> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<_MealRow> _meals = [];
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _meals.addAll(widget.initialSlots.map(_MealRow.fromSlot));
    // A brand-new diet opens with one row: an empty list with an "add" button
    // makes the user guess that meals are what goes here.
    if (_meals.isEmpty) _meals.add(_MealRow(id: _newSlotId()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final meal in _meals) {
      meal.dispose();
    }
    super.dispose();
  }

  String _newSlotId() =>
      'manual-slot-${DateTime.now().microsecondsSinceEpoch}-${_meals.length}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = NutritionTarget.sum(_meals.map((m) => m.readTarget()));

    return Scaffold(
      appBar: AppBar(title: widget.title),
      body: Form(
        key: _formKey,
        // Rebuilds the running total as macros are typed, so the daily figure is
        // derived on screen rather than being a second number to keep in sync.
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            TextFormField(
              key: const Key('dietNameField'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Diet name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily total', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      NutritionFormat.kcal(total.energy.kcal),
                      key: const Key('dailyTotalKcal'),
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'P ${total.macros.proteinG.round()} g  ·  '
                      'C ${total.macros.carbsG.round()} g  ·  '
                      'F ${total.macros.fatG.round()} g',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adds up from the meals below — no need to type it.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Meals', style: theme.textTheme.titleMedium),
                FilledButton.tonalIcon(
                  key: const Key('addMealButton'),
                  onPressed: _addMeal,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add meal'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _meals.length; i++) _mealCard(i),
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Text(
                error,
                key: const Key('manualDietError'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('saveDietButton'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save diet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealCard(int index) {
    final meal = _meals[index];

    return Card(
      key: Key('mealCard_$index'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('mealLabelField_$index'),
                    controller: meal.label,
                    decoration: const InputDecoration(labelText: 'Meal name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                ),
                // The last meal cannot be removed: a diet with no meals is not
                // a diet, and the save would reject it anyway.
                if (_meals.length > 1)
                  IconButton(
                    key: Key('removeMealButton_$index'),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove this meal',
                    onPressed: () => _removeMeal(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: NumberField(
                    fieldKey: Key('mealKcalField_$index'),
                    controller: meal.kcal,
                    label: 'kcal',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(
                    fieldKey: Key('mealProteinField_$index'),
                    controller: meal.protein,
                    label: 'P (g)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(
                    fieldKey: Key('mealCarbsField_$index'),
                    controller: meal.carbs,
                    label: 'C (g)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(
                    fieldKey: Key('mealFatField_$index'),
                    controller: meal.fat,
                    label: 'F (g)',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addMeal() => setState(() => _meals.add(_MealRow(id: _newSlotId())));

  void _removeMeal(int index) {
    setState(() {
      _meals[index].dispose();
      _meals.removeAt(index);
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final result = await ref.read(saveManualDietProvider)(
      planId: widget.planId,
      name: _nameController.text,
      slots: [for (var i = 0; i < _meals.length; i++) _meals[i].readSlot(i)],
      // Creating a diet is how the user says which one they are on; editing the
      // one they are already following must not quietly switch them off it.
      makeActive: widget.planId == null,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Err(failure: final failure):
        setState(() => _error = _describe(failure));
      case Ok():
        // Both the picker and every cached day view have to re-read: the set of
        // diets changed, and so may the active one.
        ref.read(dietLibraryRevisionProvider.notifier).state++;
        ref.invalidate(dietDayControllerProvider);
        Navigator.of(context).pop();
    }
  }

  static String _describe(NutritionFailure failure) => switch (failure) {
    ConflictFailure(reason: final reason) => reason,
    MalformedPlanFailure(reason: final reason) => reason,
    StorageFailure(reason: final reason) => reason,
    _ => 'Could not save this diet.',
  };
}
