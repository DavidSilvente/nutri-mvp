import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/pdf_file_picker.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/import_review.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/import_review_screen.dart';

/// The user's diet library: every imported plan, with exactly one marked as the
/// current diet.
///
/// Picking a diet here is what the day and calendar views read from, so the
/// choice is a single tap and its effect is immediate.
class DietLibraryScreen extends ConsumerStatefulWidget {
  const DietLibraryScreen({super.key});

  @override
  ConsumerState<DietLibraryScreen> createState() => _DietLibraryScreenState();
}

class _DietLibraryScreenState extends ConsumerState<DietLibraryScreen> {
  /// What the import is doing, or null when it is not running.
  ///
  /// Held as state rather than shown in a modal dialog so the screen stays
  /// inspectable while reading runs, and so a rebuild cannot lose the barrier.
  String? _importStatus;

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(dietLibraryBootstrapProvider);
    final plans = ref.watch(storedDietPlansProvider);
    final canImport = ref.watch(canImportDietPdfProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My diets'),
        actions: [
          if (canImport)
            IconButton(
              key: const Key('importDietPdfButton'),
              icon: const Icon(Icons.upload_file_rounded),
              tooltip: 'Import a diet PDF',
              onPressed: _importStatus == null ? _import : null,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (bootstrap.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            plans.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(error.toString(), textAlign: TextAlign.center),
                ),
              ),
              data: (stored) => stored.isEmpty
                  ? _NoDiets(onImport: canImport ? _import : null)
                  : _DietList(plans: stored),
            ),
          if (_importStatus case final status?) _ImportBarrier(status: status),
        ],
      ),
    );
  }

  /// Pick a PDF, read it, let the user settle its foods, then store it.
  ///
  /// The review sits in the middle on purpose: a plan the app cannot fully
  /// place is the normal case, and storing it without asking would attach
  /// guessed macros to real meals.
  Future<void> _import() async {
    final picked = await ref.read(pdfFilePickerProvider).pickPdf();
    if (picked case Err(failure: final failure)) {
      _report(failure);
      return;
    }
    // Backing out of the picker is a decision, not an error.
    final file = (picked as Ok<PickedPdf?, NutritionFailure>).value;
    if (file == null) return;

    setState(() => _importStatus = 'Reading ${file.name}…');
    final DietImportDraft draft;
    try {
      final importer = await ref.read(importDietPdfProvider.future);
      final prepared = await importer.prepare(file.bytes);
      switch (prepared) {
        case Err(failure: final failure):
          _report(failure);
          return;
        case Ok(value: final value):
          draft = value;
      }
    } finally {
      if (mounted) setState(() => _importStatus = null);
    }
    if (!mounted) return;

    final decisions = await Navigator.of(context).push<List<ReviewedFood>>(
      MaterialPageRoute(
        builder: (_) => ImportReviewScreen(
          resolutions: draft.resolutions,
          sourceLabel: file.name,
        ),
      ),
    );
    // Leaving the review without confirming abandons the import.
    if (decisions == null || !mounted) return;

    setState(() => _importStatus = 'Saving the plan…');
    try {
      final importer = await ref.read(importDietPdfProvider.future);
      final stored = await importer.complete(
        draft,
        decisions,
        sourceLabel: file.name,
        makeActive: true,
      );
      switch (stored) {
        case Err(failure: final failure):
          _report(failure);
        case Ok():
          _refreshLibrary();
          _say('Imported ${file.name}');
      }
    } finally {
      if (mounted) setState(() => _importStatus = null);
    }
  }

  void _refreshLibrary() {
    ref.read(dietLibraryRevisionProvider.notifier).state++;
    ref.invalidate(dietDayControllerProvider);
  }

  /// Says which step broke, in the words of the failure that broke it.
  void _report(NutritionFailure failure) {
    _say(switch (failure) {
      MalformedPlanFailure(reason: final reason) => 'Could not read the plan: '
          '$reason',
      UnknownFoodFailure(sortedIds: final ids) =>
        'The plan still mentions foods we do not know: ${ids.join(', ')}',
      StorageFailure(reason: final reason) => reason,
      _ => 'The import failed.',
    });
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Blocks the library while an import step runs, and says which step it is.
class _ImportBarrier extends StatelessWidget {
  const _ImportBarrier({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: ColoredBox(
        key: const Key('importBarrier'),
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(status, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  'Reading a scanned plan takes a couple of minutes.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DietList extends ConsumerWidget {
  const _DietList({required this.plans});

  final List<StoredDietPlan> plans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _DietTile(plan: plan, canDelete: plans.length > 1);
      },
    );
  }
}

class _DietTile extends ConsumerWidget {
  const _DietTile({required this.plan, required this.canDelete});

  final StoredDietPlan plan;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      key: Key('dietPlan-${plan.id}'),
      leading: Icon(
        plan.isDefault ? Icons.check_circle : Icons.circle_outlined,
        color: plan.isDefault ? theme.colorScheme.primary : null,
      ),
      title: Text(plan.name),
      subtitle: Text(
        [
          if (plan.declaredDailyEnergyKcal != null)
            '${plan.declaredDailyEnergyKcal!.round()} kcal',
          if (plan.sourceLabel != null) plan.sourceLabel!,
        ].join('  ·  '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: canDelete
          ? IconButton(
              key: Key('deleteDietPlan-${plan.id}'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            )
          : null,
      selected: plan.isDefault,
      onTap: plan.isDefault ? null : () => _activate(ref),
    );
  }

  Future<void> _activate(WidgetRef ref) async {
    final result = await ref.read(dietPlanStoreProvider).setActivePlan(plan.id);
    if (result.isOk) _invalidate(ref);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this diet?'),
        content: Text(
          '"${plan.name}" will be removed. Days you already logged are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteDiet'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref.read(dietPlanStoreProvider).deletePlan(plan.id);
    if (result.isOk) _invalidate(ref);
  }

  /// Bumps the library revision so the picker and every cached day view re-read.
  void _invalidate(WidgetRef ref) {
    ref.read(dietLibraryRevisionProvider.notifier).state++;
    ref.invalidate(dietDayControllerProvider);
  }
}

class _NoDiets extends StatelessWidget {
  const _NoDiets({this.onImport});

  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'No diets yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Import a diet plan to get started.',
              textAlign: TextAlign.center,
            ),
            if (onImport case final onImport?) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('importFirstDietButton'),
                onPressed: onImport,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Import a diet PDF'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
