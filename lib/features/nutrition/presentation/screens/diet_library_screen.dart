import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/pdf_file_picker.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/import_review.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/save_manual_diet.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/import_review_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/manual_diet_editor_screen.dart';

/// The user's diets: every one they have, with exactly one marked as current.
///
/// The ONLY place a diet is managed — chosen, imported, written by hand, edited
/// or deleted. There used to be a second screen listing hand-built templates
/// that the day and calendar views read from instead, which is how a user could
/// import a diet and still be told they had none.
///
/// Picking a diet here is what every other screen reads from, so the choice is a
/// single tap and its effect is immediate.
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
      key: const Key('dietLibraryScreen'),
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
                  ? _NoDiets(
                      onImport: canImport ? _import : null,
                      onCreate: () => _openEditor(),
                    )
                  : _DietList(plans: stored),
            ),
          if (_importStatus case final status?) _ImportBarrier(status: status),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createDietButton'),
        // Explicit tag: this screen shares a subtree with the day view's FAB
        // inside the home IndexedStack, and two default-tagged heroes in one
        // subtree is a runtime error.
        heroTag: 'createDietFab',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Write a diet'),
      ),
    );
  }

  /// Opens the hand-written diet editor, for a new diet or an existing one.
  void _openEditor([String? planId]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManualDietEditorScreen(planId: planId),
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
      padding: const EdgeInsets.only(bottom: 96),
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

  /// Whether this diet was typed in the app, and so can be edited here.
  ///
  /// An imported plan prescribes foods; this app can only edit typed macros, so
  /// offering an edit would mean replacing the dietitian's foods with totals.
  bool get _isHandWritten =>
      plan.sourceLabel == SaveManualDiet.manualSourceLabel;

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isHandWritten)
            IconButton(
              key: Key('editDietPlan-${plan.id}'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit this diet',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ManualDietEditorScreen(planId: plan.id),
                ),
              ),
            ),
          // The last diet stays: deleting it would leave the day view with
          // nothing to read and no obvious way back.
          if (canDelete)
            IconButton(
              key: Key('deleteDietPlan-${plan.id}'),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete this diet',
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
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
  const _NoDiets({required this.onCreate, this.onImport});

  final VoidCallback onCreate;

  /// Null on a build with no extraction key, where importing would fail on the
  /// first request. Writing a diet by hand always works, so it is the offer that
  /// is always present.
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('noDietsMessage'),
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
              'Import the plan your dietitian gave you, or write one yourself.',
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
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('createFirstDietButton'),
              onPressed: onCreate,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Write a diet by hand'),
            ),
          ],
        ),
      ),
    );
  }
}
