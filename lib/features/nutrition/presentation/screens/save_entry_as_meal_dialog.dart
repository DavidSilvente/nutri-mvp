import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/macro_breakdown.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/saved_meal_write_mixin.dart';

/// Promotes a logged [NutritionEntry] into the saved-meal catalogue.
///
/// `NutritionEntry` carries no label of its own, so a name is the only thing
/// this dialog asks for (plus an optional portion note); energy and macros
/// are shown read-only and copied verbatim — the point of promotion is "that
/// thing I actually ate", so letting them be edited here would let the
/// catalogue drift from the logged fact.
///
/// Saves itself and only closes on success, via the shared
/// [SavedMealWriteMixin] also used by `_SavedMealDialog` on the "My meals"
/// screen: on failure (a duplicate name is the likely one) it stays open
/// with the error shown inline so the user can fix the name and retry
/// instead of losing what they typed.
class SaveEntryAsMealDialog extends ConsumerStatefulWidget {
  const SaveEntryAsMealDialog({super.key, required this.entry});

  final NutritionEntry entry;

  @override
  ConsumerState<SaveEntryAsMealDialog> createState() =>
      _SaveEntryAsMealDialogState();
}

class _SaveEntryAsMealDialogState extends ConsumerState<SaveEntryAsMealDialog>
    with SavedMealWriteMixin<SaveEntryAsMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = NutritionTarget(
      energy: widget.entry.energy,
      macros: widget.entry.macros,
    );

    return AlertDialog(
      title: const Text('Save as a meal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const Key('saveEntryAsMealNameField'),
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
                  key: const Key('saveEntryAsMealError'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                NutritionFormat.kcal(target.energy.kcal),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              MacroSummaryLine(target: target),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('saveEntryAsMealNoteField'),
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
          key: const Key('confirmSaveEntryAsMealButton'),
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

    await submitSavedMealWrite(
      () => ref.read(savedMealControllerProvider.notifier).promoteEntry(
            widget.entry,
            name: _name.text.trim(),
            portionNote: note.isEmpty ? null : note,
          ),
    );
  }
}
