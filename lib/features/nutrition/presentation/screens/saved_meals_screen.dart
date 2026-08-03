import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/saved_meal.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/macro_breakdown.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/number_field.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/saved_meal_write_mixin.dart';

/// Lists the user's saved-meal catalogue and lets them create or delete
/// entries.
///
/// Picking a saved meal as an alternative to a planned meal, editing an
/// existing one, and promoting a logged entry into the catalogue are handled
/// elsewhere (the alternatives sheet and the day-plan screen).
class SavedMealsScreen extends ConsumerStatefulWidget {
  const SavedMealsScreen({super.key});

  @override
  ConsumerState<SavedMealsScreen> createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends ConsumerState<SavedMealsScreen> {
  final _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(savedMealControllerProvider);

    return Scaffold(
      key: const Key('savedMealsScreen'),
      appBar: AppBar(title: const Text('My meals')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                key: const Key('savedMealNameFilter'),
                controller: _filterController,
                decoration: const InputDecoration(
                  labelText: 'Filter by name',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _filter = value),
              ),
            ),
            Expanded(
              child: stateAsync.when(
                // A failed create/delete never touches the catalogue (the
                // source rejects it before writing), and Riverpod's
                // `AsyncNotifier` preserves the previous list on the
                // resulting `AsyncError` (`copyWithPrevious`, applied
                // automatically by `state = ...`). Rendering that preserved
                // data instead of the error keeps this screen showing the
                // unchanged list while `_SavedMealDialog` surfaces the
                // failure inline — no separate resync is needed.
                skipError: true,
                data: (meals) {
                  final query = _filter.trim().toLowerCase();
                  final visible = query.isEmpty
                      ? meals
                      : meals
                          .where((m) => m.name.toLowerCase().contains(query))
                          .toList(growable: false);

                  if (visible.isEmpty) {
                    return meals.isEmpty
                        ? const _EmptySavedMeals()
                        : const _NoFilterMatches();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _SavedMealCard(meal: visible[index]),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: $error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addSavedMealButton'),
        // Explicit tag: this screen shares a subtree with other tabs' FABs
        // inside the home IndexedStack, and two default-tagged heroes in
        // one subtree is a runtime error.
        heroTag: 'addSavedMealFab',
        onPressed: () => _createMeal(context),
        icon: const Icon(Icons.add),
        label: const Text('New meal'),
      ),
    );
  }

  Future<void> _createMeal(BuildContext context) async {
    final newId = ref.read(savedMealIdFactoryProvider)();
    // The dialog performs (and awaits) the save itself, closing only on
    // success. That way a failure — a duplicate name is the likely one —
    // never loses what the user typed: the dialog just stays open with the
    // error shown inline so they can fix the name and retry.
    await showDialog<void>(
      context: context,
      builder: (_) => _SavedMealDialog(id: newId),
    );
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
                  key: Key('editSavedMeal-${meal.id}'),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editMeal(context),
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

  Future<void> _editMeal(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SavedMealDialog(id: meal.id, existing: meal),
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

/// Invites the user to try a different filter when their query matches
/// nothing, without implying the catalogue itself is empty.
class _NoFilterMatches extends StatelessWidget {
  const _NoFilterMatches();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      key: const Key('noSavedMealFilterMatches'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No saved meals match that name',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Captures a new saved meal, or edits an existing one: a name, its macros,
/// and an optional note.
///
/// [existing] is null for a create, and the meal being edited otherwise —
/// the form is pre-filled with its values, and [id] is its own id, so the
/// save is treated as an update rather than a conflicting create (see
/// `SavedMealSource.saveMeal`).
///
/// Saves itself and only closes on success. On failure (a duplicate name is
/// the likely one — e.g. a rename that collides with another entry) it
/// stays open with the error shown inline next to the name field — the
/// typed values are never lost, so the user can just fix the name and retry.
class _SavedMealDialog extends ConsumerStatefulWidget {
  const _SavedMealDialog({required this.id, this.existing});

  final String id;
  final SavedMeal? existing;

  @override
  ConsumerState<_SavedMealDialog> createState() => _SavedMealDialogState();
}

class _SavedMealDialogState extends ConsumerState<_SavedMealDialog>
    with SavedMealWriteMixin<_SavedMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _energy = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _name.text = existing.name;
      _energy.text = existing.target.energy.kcal.toStringAsFixed(0);
      _protein.text = existing.target.macros.proteinG.toStringAsFixed(0);
      _carbs.text = existing.target.macros.carbsG.toStringAsFixed(0);
      _fat.text = existing.target.macros.fatG.toStringAsFixed(0);
      _note.text = existing.portionNote ?? '';
    }
  }

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
      title: Text(widget.existing == null ? 'New meal' : 'Edit meal'),
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
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  key: const Key('savedMealDialogError'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              NumberField(
                fieldKey: const Key('savedMealEnergyField'),
                controller: _energy,
                label: 'Energy (kcal)',
              ),
              const SizedBox(height: 12),
              NumberField(
                fieldKey: const Key('savedMealProteinField'),
                controller: _protein,
                label: 'Protein (g)',
              ),
              const SizedBox(height: 12),
              NumberField(
                fieldKey: const Key('savedMealCarbsField'),
                controller: _carbs,
                label: 'Carbs (g)',
              ),
              const SizedBox(height: 12),
              NumberField(
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
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('saveSavedMealButton'),
          onPressed: saving ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
          child: saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final note = _note.text.trim();
    final meal = SavedMeal(
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
    );

    await submitSavedMealWrite(
      () => ref.read(savedMealControllerProvider.notifier).saveMeal(meal),
    );
  }
}
