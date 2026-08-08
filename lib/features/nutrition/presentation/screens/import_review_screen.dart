import 'package:flutter/material.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/extracted_food_resolver.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/import_review.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/food_picker_sheet.dart';

/// Where the user settles what an imported plan actually says.
///
/// The resolver places most lines on a food-table entry by itself, but a
/// plausible-looking match it is not sure about is exactly the case that must
/// not pass silently: the user would end up with a lunch whose macros were a
/// guess, presented as if they came from a published table. So every doubtful
/// line lands here, and the import cannot run until each one has a food.
///
/// Pops a `List<ReviewedFood>` on confirmation, or null if the user backs out.
class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.resolutions,
    required this.sourceLabel,
  });

  /// The resolver's verdict for every food line in the plan, in plan order.
  final List<FoodResolution> resolutions;

  /// Where the plan came from, normally the file name.
  final String sourceLabel;

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  late ImportReview _review = ImportReview.from(widget.resolutions);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Review the plan')),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.sourceLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Every line has to land on a food we know the composition '
                    'of. Lines we could not place confidently are yours to '
                    'settle — otherwise their macros would be a guess.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PendingBanner(review: _review),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: _review.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ReviewLineCard(
                  entry: _review.entries[index],
                  index: index,
                  onChoose: () => _choose(index),
                  onEditQuantity: () => _editQuantity(index),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            key: const Key('confirmImportButton'),
            onPressed: _review.isComplete ? _confirm : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_confirmLabel(_review)),
          ),
        ),
      ),
    );
  }

  static String _confirmLabel(ImportReview review) {
    if (review.isComplete) {
      final foods = review.length == 1 ? 'food' : 'foods';
      return 'Import ${review.length} $foods';
    }
    return review.pendingCount == 1
        ? '1 line still needs a food'
        : '${review.pendingCount} lines still need a food';
  }

  Future<void> _choose(int index) async {
    final entry = _review.entries[index];
    final picked = await FoodPickerSheet.show(
      context,
      title: entry.extracted.rawText,
      initialCandidates: entry.resolution.candidates,
      emptyCandidatesMessage:
          'Nothing matched this line automatically. '
          'Search for the food above.',
    );
    if (picked == null) return;

    setState(() {
      _review = _review.select(index, picked.food, score: picked.score);
    });
  }

  /// Corrects how much a line calls for.
  ///
  /// The other half of the check: the right food at the wrong weight is still
  /// wrong, and misreading a parenthesised total as a per-unit weight is the
  /// mistake an extraction is most likely to make invisibly.
  Future<void> _editQuantity(int index) async {
    final entry = _review.entries[index];
    final corrected = await showDialog<FoodQuantity>(
      context: context,
      builder: (_) => _QuantityDialog(entry: entry),
    );
    if (corrected == null) return;

    setState(() => _review = _review.setQuantity(index, corrected));
  }

  void _confirm() => Navigator.of(context).pop(_review.decisions);
}

/// How much is left, stated plainly rather than left for the user to count.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.review});

  final ImportReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = review.isComplete;
    final background = done
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.errorContainer;
    final foreground = done
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onErrorContainer;

    return Container(
      key: const Key('reviewPendingBanner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_outline : Icons.error_outline,
            size: 20,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              done
                  ? 'Every line is settled'
                  : '${review.pendingCount} of ${review.length} lines need '
                        'your call',
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// One plan line: what it said, and what it will be imported as.
class _ReviewLineCard extends StatelessWidget {
  const _ReviewLineCard({
    required this.entry,
    required this.index,
    required this.onChoose,
    required this.onEditQuantity,
  });

  final ImportReviewEntry entry;
  final int index;
  final VoidCallback onChoose;
  final VoidCallback onEditQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extracted = entry.extracted;

    return Card(
      key: Key('reviewLine-$index'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(extracted.rawText, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _quantityLine(entry),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: entry.quantityWasCorrected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: entry.quantityWasCorrected
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('editQuantityButton-$index'),
                  icon: const Icon(Icons.straighten_rounded, size: 18),
                  tooltip: 'Correct the amount',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEditQuantity,
                ),
              ],
            ),
            if (extracted.brandNormalizedFrom case final brand?) ...[
              const SizedBox(height: 4),
              Text(
                'Brand dropped for matching: $brand',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const Divider(height: 24),
            if (entry.food case final food?)
              _ChosenFood(
                name: food.name,
                per100gKcal: food.per100g.energy.kcal,
                trailing: entry.chosenByUser
                    ? 'Your pick'
                    : _confidenceLabel(entry.score),
              )
            else
              _Unsettled(candidateCount: entry.resolution.candidates.length),
            const SizedBox(height: 12),
            OutlinedButton(
              key: Key('chooseFoodButton-$index'),
              onPressed: onChoose,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(entry.isSettled ? 'Change food' : 'Choose a food'),
            ),
          ],
        ),
      ),
    );
  }

  /// "140 g" or "2 slices · 60 g" — a parenthesised weight in a plan is the
  /// TOTAL for the quantity, so both numbers are shown rather than multiplied.
  static String _quantityLine(ImportReviewEntry entry) {
    final quantity = entry.effectiveQuantity;
    final buffer = StringBuffer();
    if (quantity.count case final count?) {
      buffer.write('${NutritionFormat.amount(count)} ');
      buffer.write(quantity.unit ?? 'units');
      buffer.write(' · ');
    }
    buffer.write(NutritionFormat.grams(quantity.grams));
    buffer.write(' · ${entry.extracted.canonicalName}');
    if (entry.extracted.preparation.trim().isNotEmpty) {
      buffer.write(', ${entry.extracted.preparation}');
    }
    if (entry.quantityWasCorrected) buffer.write('  (corrected)');
    return buffer.toString();
  }

  static String _confidenceLabel(double? score) =>
      score == null ? 'Matched' : 'Match ${(score * 100).round()}%';
}

class _ChosenFood extends StatelessWidget {
  const _ChosenFood({
    required this.name,
    required this.per100gKcal,
    required this.trailing,
  });

  final String name;
  final num per100gKcal;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                '${NutritionFormat.kcal(per100gKcal)} per 100 g',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          trailing,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Unsettled extends StatelessWidget {
  const _Unsettled({required this.candidateCount});

  final int candidateCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.help_outline, size: 20, color: theme.colorScheme.error),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            candidateCount == 0
                ? 'Nothing in the food table matched this line'
                : 'No confident match — $candidateCount option'
                      '${candidateCount == 1 ? '' : 's'} to check',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

/// Corrects the amount one plan line calls for.
///
/// The weight is what every macro is derived from, so it is the field that must
/// be right. Count and unit are the plan's own wording, kept so the day view can
/// echo it ("2 porciones") instead of translating everything into grams.
class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.entry});

  final ImportReviewEntry entry;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final FoodQuantity _current = widget.entry.effectiveQuantity;
  late final _grams = TextEditingController(
    text: NutritionFormat.amount(_current.grams),
  );
  late final _count = TextEditingController(
    text: _current.count == null ? '' : NutritionFormat.amount(_current.count!),
  );
  late final _unit = TextEditingController(text: _current.unit ?? '');

  @override
  void dispose() {
    _grams.dispose();
    _count.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Correct the amount'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.entry.extracted.rawText,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'A weight in brackets is the TOTAL for the quantity, not the '
                'weight of one unit.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('quantityGramsField'),
                controller: _grams,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Total weight (g)',
                  helperText: 'Every macro is derived from this',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = num.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) return 'Must be above 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('quantityCountField'),
                controller: _count,
                decoration: const InputDecoration(
                  labelText: 'Units (optional)',
                  hintText: 'e.g. 2 for "2 porciones"',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  final parsed = num.tryParse(text);
                  if (parsed == null || parsed <= 0) return 'Must be above 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('quantityUnitField'),
                controller: _unit,
                decoration: const InputDecoration(
                  labelText: 'Unit wording (optional)',
                  hintText: 'e.g. porcion',
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
          key: const Key('saveQuantityButton'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final count = num.tryParse(_count.text.trim());
    final unit = _unit.text.trim();
    Navigator.of(context).pop(
      FoodQuantity(
        grams: num.parse(_grams.text.trim()),
        count: count,
        // A unit without a count says nothing, so it is dropped rather than
        // stored as wording with no number attached.
        unit: count == null || unit.isEmpty ? null : unit,
      ),
    );
  }
}
