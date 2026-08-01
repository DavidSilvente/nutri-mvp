import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/day_format.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_day_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';

/// Screen to register a nutrition intake: energy and macros. Water is NOT
/// part of this flow — hydration has its own dedicated screen.
///
/// Three ways in, all the same form:
/// * free-standing (no [day], no [plannedMeal]) — an unplanned intake today;
/// * attached to a [day] — the same, but backdated to that day;
/// * attached to a [plannedMeal] — the intake counts towards that meal's
///   adherence, and the fields start pre-filled with its target.
class RecordIntakeScreen extends ConsumerStatefulWidget {
  const RecordIntakeScreen({
    super.key,
    this.day,
    this.plannedMeal,
    this.prefill,
    this.prefillLabel,
  });

  /// The day this intake belongs to. Defaults to today.
  final NutritionDay? day;

  /// The planned meal this intake fulfils, if any.
  final PlannedMealDetail? plannedMeal;

  /// Values to start from. Defaults to the planned meal's target when a meal
  /// is given; used to carry a chosen alternative's macros over.
  final NutritionTarget? prefill;

  /// Name of the alternative the prefill came from, shown as confirmation of
  /// what is being logged.
  final String? prefillLabel;

  @override
  ConsumerState<RecordIntakeScreen> createState() => _RecordIntakeScreenState();
}

class _RecordIntakeScreenState extends ConsumerState<RecordIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _energyController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    // Pre-filling with the target is the difference between logging a planned
    // meal in one tap and re-typing four numbers you already decided on.
    final prefill = widget.prefill ?? widget.plannedMeal?.target;
    _energyController = TextEditingController(
      text: prefill == null
          ? ''
          : NutritionFormat.amount(prefill.energy.kcal),
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
    _energyController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final entry = NutritionEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      recordedAt: _recordedAt(),
      energy: Energy(kcal: num.parse(_energyController.text)),
      macros: Macros(
        proteinG: num.parse(_proteinController.text),
        carbsG: num.parse(_carbsController.text),
        fatG: num.parse(_fatController.text),
      ),
      plannedMealId: widget.plannedMeal?.meal.id,
    );

    await ref.read(nutritionControllerProvider.notifier).record(entry);

    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Entries are grouped by the calendar DAY of [NutritionEntry.recordedAt],
  /// so an intake logged into a given day must carry that day's date —
  /// otherwise it would silently land on whatever day the clock says.
  ///
  /// The time of day still comes from the clock, which keeps entries ordered
  /// within the day. The date is taken from [widget.day] unconditionally
  /// rather than "only when it is not today": deriving it from a comparison
  /// makes the result depend on two sources of truth instead of one.
  DateTime _recordedAt() {
    final day = widget.day;
    final now = DateTime.now();
    if (day == null) return now;
    return DateTime(
      day.year,
      day.month,
      day.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
    );
  }

  String? _requiredNonNegativeNumber(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    final parsed = num.tryParse(value);
    if (parsed == null || parsed < 0) return 'Debe ser un número >= 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meal = widget.plannedMeal;
    final day = widget.day;

    return Scaffold(
      appBar: AppBar(
        title: Text(meal == null ? 'Registrar ingesta' : 'Log ${meal.label}'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (meal != null || day != null) ...[
                _ContextCard(
                  mealLabel: meal?.label,
                  day: day,
                  prefillLabel: widget.prefillLabel,
                ),
                const SizedBox(height: 20),
              ],
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
              if (meal != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Adjust these to what you actually ate — the plan is met '
                  'as long as you land close.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('submitButton'),
                onPressed: _submit,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.mealLabel,
    required this.day,
    required this.prefillLabel,
  });

  final String? mealLabel;
  final NutritionDay? day;
  final String? prefillLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              prefillLabel != null
                  ? Icons.swap_horiz_rounded
                  : Icons.restaurant_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prefillLabel ?? mealLabel ?? 'Unplanned intake',
                    style: theme.textTheme.titleSmall,
                  ),
                  if (day != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DayFormat.full(day!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (prefillLabel != null && mealLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Counts towards $mealLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
