import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/macro_breakdown.dart';

/// Lists the user's saved-meal catalogue and lets them create or delete
/// entries.
///
/// Picking a saved meal as an alternative to a planned meal, editing an
/// existing one, and promoting a logged entry into the catalogue are handled
/// elsewhere (the alternatives sheet and the day-plan screen).
class SavedMealsScreen extends ConsumerWidget {
  const SavedMealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(savedMealControllerProvider);

    return Scaffold(
      key: const Key('savedMealsScreen'),
      appBar: AppBar(title: const Text('My meals')),
      body: SafeArea(
        child: stateAsync.when(
          data: (meals) {
            if (meals.isEmpty) return const _EmptySavedMeals();

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: meals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _SavedMealCard(meal: meals[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addSavedMealButton'),
        // Explicit tag: this screen shares a subtree with other tabs' FABs
        // inside the home IndexedStack, and two default-tagged heroes in
        // one subtree is a runtime error.
        heroTag: 'addSavedMealFab',
        onPressed: () => _createMeal(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New meal'),
      ),
    );
  }

  Future<void> _createMeal(BuildContext context, WidgetRef ref) async {
    final newId = ref.read(savedMealIdFactoryProvider)();
    final created = await showDialog<SavedMeal>(
      context: context,
      builder: (_) => _SavedMealDialog(id: newId),
    );
    if (created == null) return;

    await ref.read(savedMealControllerProvider.notifier).saveMeal(created);

    final state = ref.read(savedMealControllerProvider);
    if (!state.hasError) return;
    if (!context.mounted) return;

    final message = _formatError(state.error);
    // A failed write (e.g. a duplicate name) never touches the catalogue, so
    // resync the controller instead of leaving it on the AsyncError branch —
    // the list keeps showing the unchanged catalogue and the failure is
    // surfaced as a transient SnackBar instead of a full-screen error.
    ref.invalidate(savedMealControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _formatError(Object? error) {
    if (error is HealthFailureException) {
      return switch (error.failure) {
        ConflictFailure(reason: final reason) => reason,
        _ => 'Could not save this meal',
      };
    }
    return 'Could not save this meal';
  }
}

class _SavedMealCard extends ConsumerWidget {
  const _SavedMealCard({required this.meal});

  final SavedMeal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      key: Key('savedMealTile-${meal.id}'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(meal.name, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  key: Key('deleteSavedMeal-${meal.id}'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              NutritionFormat.kcal(meal.target.energy.kcal),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            MacroSummaryLine(target: meal.target),
            if (meal.portionNote != null) ...[
              const SizedBox(height: 8),
              Text(
                meal.portionNote!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this meal?'),
        content: Text(
          '"${meal.name}" will be removed from your catalogue. Meals you '
          'already logged from it are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteSavedMeal'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(savedMealControllerProvider.notifier)
        .deleteSavedMeal(meal.id);
  }
}

class _EmptySavedMeals extends StatelessWidget {
  const _EmptySavedMeals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      key: const Key('emptySavedMealsMessage'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_add_outlined,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No saved meals yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Save the meals you eat often so they show up as alternatives '
              'whenever a planned meal does not appeal.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Captures a new saved meal: a name, its macros, and an optional note.
class _SavedMealDialog extends StatefulWidget {
  const _SavedMealDialog({required this.id});

  final String id;

  @override
  State<_SavedMealDialog> createState() => _SavedMealDialogState();
}

class _SavedMealDialogState extends State<_SavedMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _energy = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _energy.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New meal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('savedMealNameField'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 12),
              _NumberField(
                fieldKey: const Key('savedMealEnergyField'),
                controller: _energy,
                label: 'Energy (kcal)',
              ),
              const SizedBox(height: 12),
              _NumberField(
                fieldKey: const Key('savedMealProteinField'),
                controller: _protein,
                label: 'Protein (g)',
              ),
              const SizedBox(height: 12),
              _NumberField(
                fieldKey: const Key('savedMealCarbsField'),
                controller: _carbs,
                label: 'Carbs (g)',
              ),
              const SizedBox(height: 12),
              _NumberField(
                fieldKey: const Key('savedMealFatField'),
                controller: _fat,
                label: 'Fat (g)',
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('savedMealNoteField'),
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Portion note (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('saveSavedMealButton'),
          onPressed: _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final note = _note.text.trim();
    Navigator.of(context).pop(
      SavedMeal(
        id: widget.id,
        name: _name.text.trim(),
        target: NutritionTarget(
          energy: Energy(kcal: num.parse(_energy.text)),
          macros: Macros(
            proteinG: num.parse(_protein.text),
            carbsG: num.parse(_carbs.text),
            fatG: num.parse(_fat.text),
          ),
        ),
        portionNote: note.isEmpty ? null : note,
        createdAt: DateTime.now(),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final parsed = num.tryParse(value);
        if (parsed == null || parsed < 0) return 'Must be a number >= 0';
        return null;
      },
    );
  }
}
