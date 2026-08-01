import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/planned_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/diet_plan_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Assigns a diet template slot to a calendar day, or edits an existing
/// planned meal by reassigning it to a different slot.
///
/// Use [PlannedMealScreen.assign] when planning a new meal from a template
/// slot. Use [PlannedMealScreen.edit] when changing an existing planned meal.
class PlannedMealScreen extends ConsumerStatefulWidget {
  const PlannedMealScreen.assign({
    super.key,
    required this.templateId,
    required this.slotId,
  }) : plannedMealId = null;

  const PlannedMealScreen.edit({
    super.key,
    required this.plannedMealId,
  })  : templateId = null,
        slotId = null;

  final String? plannedMealId;
  final String? templateId;
  final String? slotId;

  bool get _isAssign => plannedMealId == null;

  @override
  ConsumerState<PlannedMealScreen> createState() => _PlannedMealScreenState();
}

class _PlannedMealScreenState extends ConsumerState<PlannedMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  DietTemplate? _template;
  DietMealSlot? _selectedSlot;
  String? _error;
  bool _initialized = false;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _initializeFromState(DietPlanState state) {
    if (_initialized) return;

    if (widget._isAssign) {
      _template = state.templates.firstWhere(
        (t) => t.id == widget.templateId,
      );
      _selectedSlot = _template!.slots.firstWhere(
        (s) => s.id == widget.slotId,
      );
    } else {
      final meal = state.plannedMeals.firstWhere(
        (m) => m.id == widget.plannedMealId,
      );
      _template = state.templates.firstWhere(
        (t) => t.slots.any((s) => s.id == meal.slotId),
      );
      _selectedSlot = _template!.slots.firstWhere(
        (s) => s.id == meal.slotId,
      );
    }

    final day = _initialDay(state);
    _dateController.text = _formatDay(day);
    _initialized = true;
  }

  NutritionDay _initialDay(DietPlanState state) {
    if (!widget._isAssign) {
      final meal = state.plannedMeals.firstWhere(
        (m) => m.id == widget.plannedMealId,
      );
      if (meal.day != null) return meal.day!;
    }
    return NutritionDay.fromDateTime(DateTime.now());
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSlot == null) return;

    final day = _parseDay(_dateController.text);
    if (day == null) return;

    final mealId = widget.plannedMealId ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final meal = PlannedMeal(
      id: mealId,
      slotId: _selectedSlot!.id,
      day: day,
      targetSnapshot: _selectedSlot!.target,
    );

    final container = ProviderScope.containerOf(context);
    await container
        .read(dietPlanControllerProvider.notifier)
        .assignMealToDay(meal);

    final state = container.read(dietPlanControllerProvider);
    if (state.hasError) {
      final message = _formatError(state.error);
      setState(() => _error = message);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  static String _formatDay(NutritionDay day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  static NutritionDay? _parseDay(String text) {
    final parts = text.trim().split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final dateTime = DateTime(year, month, day);
    if (dateTime.year != year ||
        dateTime.month != month ||
        dateTime.day != day) {
      return null;
    }
    return NutritionDay.fromDateTime(dateTime);
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

  static String? _validateDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (_parseDay(value) == null) return 'Use yyyy-MM-dd';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(dietPlanControllerProvider);

    if (!_initialized) {
      if (stateAsync.isLoading) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget._isAssign ? 'Plan meal' : 'Edit planned meal'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (stateAsync.hasError || !stateAsync.hasValue) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget._isAssign ? 'Plan meal' : 'Edit planned meal'),
          ),
          body: const Center(child: Text('Failed to load plan data')),
        );
      }
      _initializeFromState(stateAsync.value!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget._isAssign ? 'Plan meal' : 'Edit planned meal'),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Template: ${_template!.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('dateField'),
            controller: _dateController,
            decoration: const InputDecoration(
              labelText: 'Date (yyyy-MM-dd)',
              hintText: '2026-08-01',
            ),
            validator: _validateDate,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<DietMealSlot>(
            key: const Key('slotDropdown'),
            initialValue: _selectedSlot,
            decoration: const InputDecoration(labelText: 'Meal slot'),
            items: _template!.slots.map((slot) {
              return DropdownMenuItem<DietMealSlot>(
                value: slot,
                child: Text(slot.label),
              );
            }).toList(),
            onChanged: (slot) => setState(() => _selectedSlot = slot),
            validator: (value) => value == null ? 'Select a slot' : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Target snapshot: '
            '${_selectedSlot?.target.energy.kcal.round()} kcal · '
            'P: ${_selectedSlot?.target.macros.proteinG.round()}g · '
            'C: ${_selectedSlot?.target.macros.carbsG.round()}g · '
            'F: ${_selectedSlot?.target.macros.fatG.round()}g',
            key: const Key('targetSnapshot'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Substitutes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Substitute suggestions will appear here after menu capture.',
            key: Key('substitutesSection'),
          ),
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
            key: const Key('savePlannedMealButton'),
            onPressed: _save,
            child: const Text('Save planned meal'),
          ),
        ],
      ),
    );
  }
}
