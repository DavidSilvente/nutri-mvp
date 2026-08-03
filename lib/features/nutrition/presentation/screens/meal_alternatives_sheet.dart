import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/meal_substitute.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/alternative_ranker.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_day_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/swap_tolerance.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/substitute_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/record_intake_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/macro_breakdown.dart';

/// "I don't fancy that today" — the alternatives defined for a planned meal,
/// closest match first.
///
/// Ranking is by macro distance to the meal's frozen target, so the option at
/// the top is the one that costs the plan least. Picking one logs it against
/// the SAME planned meal, which is what keeps a swap from counting as a miss.
class MealAlternativesSheet extends ConsumerWidget {
  const MealAlternativesSheet({
    super.key,
    required this.detail,
    required this.day,
  });

  final PlannedMealDetail detail;
  final NutritionDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = (
      plannedMealId: detail.meal.id,
      target: detail.target,
    );
    final rankedAsync = ref.watch(rankedSubstitutesProvider(query));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              'Alternatives for ${detail.label}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Ranked by how close they are to '
              '${NutritionFormat.kcal(detail.target.energy.kcal)} · '
              'P ${NutritionFormat.amount(detail.target.macros.proteinG)} · '
              'C ${NutritionFormat.amount(detail.target.macros.carbsG)} · '
              'F ${NutritionFormat.amount(detail.target.macros.fatG)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            rankedAsync.when(
              data: (groups) {
                if (groups.isEmpty) return const _NoAlternatives();

                AlternativeGroup? planGroup;
                AlternativeGroup? savedGroup;
                for (final group in groups) {
                  switch (group.origin) {
                    case AlternativeOrigin.plan:
                      planGroup = group;
                    case AlternativeOrigin.savedMeal:
                      savedGroup = group;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (planGroup != null)
                      _AlternativeGroupSection(
                        title: 'From your plan',
                        group: planGroup,
                        onPick: (option) => _pick(context, option),
                      ),
                    const SizedBox(height: 20),
                    if (savedGroup != null)
                      _AlternativeGroupSection(
                        title: 'From your meals',
                        group: savedGroup,
                        onPick: (option) => _pick(context, option),
                      )
                    else
                      const _NoSavedMealsCta(),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text(
                'Could not load alternatives.\n$error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('addAlternativeButton'),
              onPressed: () => _addAlternative(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add an alternative'),
            ),
          ],
        );
      },
    );
  }

  /// Logging an alternative records ITS macros against the planned meal, so
  /// the day stays honest: you get credit for swapping, judged on what you
  /// ate. This is unchanged whether the pick came from the plan's own
  /// substitutes or the user's saved-meal catalogue — there is no separate
  /// confirmation dialog; this prefilled, editable screen is the
  /// confirmation.
  void _pick(BuildContext context, AlternativeOption option) {
    // Resolve the navigator BEFORE popping: once the sheet is dismissed this
    // element is on its way out, and looking anything up from its context
    // afterwards is undefined.
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => RecordIntakeScreen(
          day: day,
          plannedMeal: detail,
          prefill: option.ranked.target,
          prefillLabel: option.ranked.label,
        ),
      ),
    );
  }

  Future<void> _addAlternative(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<MealSubstitute>(
      context: context,
      builder: (_) => _AddAlternativeDialog(plannedMealId: detail.meal.id),
    );
    if (created == null) return;

    await ref
        .read(dietPlanControllerProvider.notifier)
        .saveSubstitute(created);
  }
}

/// One origin's ranked options, under a badged section title.
///
/// "From your plan" and "From your meals" are rendered by two of these,
/// never interleaved — the badge is what tells the user which is which.
class _AlternativeGroupSection extends StatelessWidget {
  const _AlternativeGroupSection({
    required this.title,
    required this.group,
    required this.onPick,
  });

  final String title;
  final AlternativeGroup group;
  final ValueChanged<AlternativeOption> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < group.options.length; i++) ...[
          _AlternativeCard(
            option: group.options[i],
            isClosest: i == 0,
            onPick: () => onPick(group.options[i]),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.option,
    required this.isClosest,
    required this.onPick,
  });

  final AlternativeOption option;
  final bool isClosest;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = option.ranked;
    final deviation = option.deviation;

    return Card(
      key: Key('alternativeCard-${ranked.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ranked.label,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (isClosest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Closest match',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              NutritionFormat.kcal(ranked.target.energy.kcal),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            MacroSummaryLine(target: ranked.target),
            const SizedBox(height: 4),
            // Shown BEFORE the user picks, so the tradeoff is visible up
            // front rather than discovered after logging it.
            Text(
              _deltaLine(deviation),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (deviation.isOffTarget) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Off target',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: Key('pickAlternativeButton-${ranked.id}'),
              onPressed: onPick,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Eat this instead'),
            ),
          ],
        ),
      ),
    );
  }

  static String _deltaLine(MacroDeviation deviation) {
    return 'P ${_signed(deviation.proteinG)} · '
        'C ${_signed(deviation.carbsG)} · '
        'F ${_signed(deviation.fatG)}';
  }

  static String _signed(double grams) {
    final magnitude = NutritionFormat.grams(grams.abs());
    if (grams > 0) return '+$magnitude';
    if (grams < 0) return '-$magnitude';
    return magnitude;
  }
}

/// Invites the user to build their saved-meal catalogue when it is empty,
/// in place of the "From your meals" section — an empty catalogue is not an
/// error, and plan substitutes keep working either way.
class _NoSavedMealsCta extends StatelessWidget {
  const _NoSavedMealsCta();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('noSavedMealsCta'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bookmark_add_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Save the meals you eat often to see them here as '
              'alternatives too.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAlternatives extends StatelessWidget {
  const _NoAlternatives();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.no_meals_outlined,
            size: 30,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('No alternatives yet', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            'Add the options you would happily swap in for this meal. '
            'They get ranked by how close they are to its macros.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Captures a new substitute: a name and the macros it brings.
class _AddAlternativeDialog extends StatefulWidget {
  const _AddAlternativeDialog({required this.plannedMealId});

  final String plannedMealId;

  @override
  State<_AddAlternativeDialog> createState() => _AddAlternativeDialogState();
}

class _AddAlternativeDialogState extends State<_AddAlternativeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _energy = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _energy.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New alternative'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('alternativeLabelField'),
                controller: _label,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _NumberField(
                fieldKey: const Key('alternativeEnergyField'),
                controller: _energy,
                label: 'Energy (kcal)',
              ),
              const SizedBox(height: 12),
              _NumberField(
                fieldKey: const Key('alternativeProteinField'),
                controller: _protein,
                label: 'Protein (g)',
              ),
              const SizedBox(height: 12),
              _NumberField(
                fieldKey: const Key('alternativeCarbsField'),
                controller: _carbs,
                label: 'Carbs (g)',
              ),
              const SizedBox(height: 12),
              _NumberField(
                fieldKey: const Key('alternativeFatField'),
                controller: _fat,
                label: 'Fat (g)',
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
          key: const Key('saveAlternativeButton'),
          onPressed: _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      MealSubstitute(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        plannedMealId: widget.plannedMealId,
        label: _label.text.trim(),
        target: NutritionTarget(
          energy: Energy(kcal: num.parse(_energy.text)),
          macros: Macros(
            proteinG: num.parse(_protein.text),
            carbsG: num.parse(_carbs.text),
            fatG: num.parse(_fat.text),
          ),
        ),
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
