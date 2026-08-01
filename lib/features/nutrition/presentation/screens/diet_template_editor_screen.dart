import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/planned_meal_screen.dart';

/// Creates a new diet template or edits an existing one.
///
/// [templateId] is `null` for create mode. Slots are edited inline and must
/// sum to the daily target before the form can be saved.
class DietTemplateEditorScreen extends ConsumerStatefulWidget {
  const DietTemplateEditorScreen({super.key, required this.templateId});

  final String? templateId;

  @override
  ConsumerState<DietTemplateEditorScreen> createState() =>
      _DietTemplateEditorScreenState();
}

class _DietTemplateEditorScreenState
    extends ConsumerState<DietTemplateEditorScreen> {
  DietTemplate? _template;
  Object? _lastError;
  bool _loaded = false;

  bool get _isCreate => widget.templateId == null;

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(dietPlanControllerProvider);

    if (!_loaded && stateAsync.hasValue) {
      _template = widget.templateId == null
          ? null
          : stateAsync.value!.templates.firstWhere(
              (t) => t.id == widget.templateId,
              orElse: () => throw StateError('Template not found'),
            );
      _loaded = true;
    }

    if (!_loaded && stateAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _isCreate ? 'Create diet template' : 'Edit diet template',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isCreate ? 'Create diet template' : 'Edit diet template',
        ),
      ),
      body: _TemplateForm(
        template: _template,
        initialError: _lastError,
        onError: (error) => setState(() => _lastError = error),
      ),
    );
  }
}

class _TemplateForm extends StatefulWidget {
  const _TemplateForm({
    this.template,
    this.initialError,
    this.onError,
  });

  final DietTemplate? template;
  final Object? initialError;
  final ValueChanged<Object?>? onError;

  @override
  State<_TemplateForm> createState() => _TemplateFormState();
}

class _SlotForm {
  _SlotForm({required this.id});

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

  static _SlotForm fromSlot(DietMealSlot slot) {
    final form = _SlotForm(id: slot.id);
    form.label.text = slot.label;
    form.kcal.text = slot.target.energy.kcal.toStringAsFixed(0);
    form.protein.text = slot.target.macros.proteinG.toStringAsFixed(0);
    form.carbs.text = slot.target.macros.carbsG.toStringAsFixed(0);
    form.fat.text = slot.target.macros.fatG.toStringAsFixed(0);
    return form;
  }

  NutritionTarget readTarget() {
    return NutritionTarget(
      energy: Energy(kcal: _parse(kcal.text)),
      macros: Macros(
        proteinG: _parse(protein.text),
        carbsG: _parse(carbs.text),
        fatG: _parse(fat.text),
      ),
    );
  }

  DietMealSlot readSlot(int position) {
    return DietMealSlot(
      id: id,
      label: label.text.trim(),
      position: position,
      target: readTarget(),
    );
  }

  static double _parse(String text) {
    final parsed = num.tryParse(text.trim());
    return parsed?.toDouble() ?? 0;
  }
}

class _TemplateFormState extends State<_TemplateForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final List<_SlotForm> _slots = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = _formatError(widget.initialError);
    _initializeFromTemplate();
  }

  @override
  void didUpdateWidget(covariant _TemplateForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template?.id != widget.template?.id) {
      _initializeFromTemplate();
    }
    if (oldWidget.initialError != widget.initialError &&
        widget.initialError != null) {
      setState(() => _error = _formatError(widget.initialError));
    }
  }

  void _initializeFromTemplate() {
    final template = widget.template;
    if (template == null) return;

    _nameController.text = template.name;
    _kcalController.text = template.dailyTarget.energy.kcal.toStringAsFixed(0);
    _proteinController.text =
        template.dailyTarget.macros.proteinG.toStringAsFixed(0);
    _carbsController.text =
        template.dailyTarget.macros.carbsG.toStringAsFixed(0);
    _fatController.text =
        template.dailyTarget.macros.fatG.toStringAsFixed(0);

    for (final slot in _slots) {
      slot.dispose();
    }
    _slots.clear();
    _slots.addAll(template.slots.map(_SlotForm.fromSlot));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    for (final slot in _slots) {
      slot.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    widget.onError?.call(null);
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final dailyTarget = NutritionTarget(
      energy: Energy(kcal: _parse(_kcalController.text)),
      macros: Macros(
        proteinG: _parse(_proteinController.text),
        carbsG: _parse(_carbsController.text),
        fatG: _parse(_fatController.text),
      ),
    );

    final slots = <DietMealSlot>[];
    for (var i = 0; i < _slots.length; i++) {
      slots.add(_slots[i].readSlot(i));
    }

    final summed = NutritionTarget.sum(slots.map((s) => s.target));
    if (!summed.equalsWithinTolerance(dailyTarget)) {
      setState(() => _error = 'Slot targets must sum to the daily target');
      return;
    }

    final template = DietTemplate(
      id: widget.template?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      dailyTarget: dailyTarget,
      slots: slots,
    );

    final container = ProviderScope.containerOf(context);
    await container
        .read(dietPlanControllerProvider.notifier)
        .saveTemplate(template);

    final state = container.read(dietPlanControllerProvider);
    if (state.hasError) {
      final message = _formatError(state.error);
      setState(() => _error = message);
      widget.onError?.call(state.error);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _addSlot() {
    setState(() {
      _slots.add(
        _SlotForm(id: DateTime.now().microsecondsSinceEpoch.toString()),
      );
    });
  }

  void _removeSlot(int index) {
    setState(() {
      _slots[index].dispose();
      _slots.removeAt(index);
    });
  }

  void _openPlannedMealScreen(String slotId) {
    final template = widget.template;
    if (template == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlannedMealScreen.assign(
          templateId: template.id,
          slotId: slotId,
        ),
      ),
    );
  }

  static double _parse(String text) {
    final parsed = num.tryParse(text.trim());
    return parsed?.toDouble() ?? 0;
  }

  static String? _formatError(Object? error) {
    if (error == null) return null;
    if (error is HealthFailureException) {
      return switch (error.failure) {
        ConflictFailure(reason: final reason) => reason,
        StorageFailure(reason: final reason) => reason,
        _ => 'Save failed',
      };
    }
    return error.toString();
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (num.tryParse(value.trim()) == null) return 'Must be a number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            key: const Key('templateNameField'),
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Template name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text('Daily target'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('dailyKcalField'),
                  controller: _kcalController,
                  decoration: const InputDecoration(labelText: 'kcal'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNumber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: const Key('dailyProteinField'),
                  controller: _proteinController,
                  decoration: const InputDecoration(labelText: 'P (g)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNumber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: const Key('dailyCarbsField'),
                  controller: _carbsController,
                  decoration: const InputDecoration(labelText: 'C (g)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNumber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: const Key('dailyFatField'),
                  controller: _fatController,
                  decoration: const InputDecoration(labelText: 'F (g)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meal slots',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.tonalIcon(
                key: const Key('addSlotButton'),
                onPressed: _addSlot,
                icon: const Icon(Icons.add),
                label: const Text('Add slot'),
              ),
            ],
          ),
          ..._buildSlotEditors(),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('saveTemplateButton'),
            onPressed: _save,
            child: const Text('Save template'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlotEditors() {
    return _slots.asMap().entries.map((entry) {
      final index = entry.key;
      final slot = entry.value;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: Key('slotLabelField_$index'),
                      controller: slot.label,
                      decoration: const InputDecoration(
                        labelText: 'Slot label',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (widget.template != null)
                    IconButton(
                      key: Key('planSlotButton_$index'),
                      icon: const Icon(Icons.event_available),
                      tooltip: 'Plan meal',
                      onPressed: () => _openPlannedMealScreen(slot.id),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: Key('slotKcalField_$index'),
                      controller: slot.kcal,
                      decoration: const InputDecoration(labelText: 'kcal'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _requiredNumber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: Key('slotProteinField_$index'),
                      controller: slot.protein,
                      decoration: const InputDecoration(labelText: 'P (g)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _requiredNumber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: Key('slotCarbsField_$index'),
                      controller: slot.carbs,
                      decoration: const InputDecoration(labelText: 'C (g)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _requiredNumber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: Key('slotFatField_$index'),
                      controller: slot.fat,
                      decoration: const InputDecoration(labelText: 'F (g)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _requiredNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _removeSlot(index),
                child: const Text('Remove'),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
