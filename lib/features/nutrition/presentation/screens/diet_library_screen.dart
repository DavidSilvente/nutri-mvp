import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// The user's diet library: every imported plan, with exactly one marked as the
/// current diet.
///
/// Picking a diet here is what the day and calendar views read from, so the
/// choice is a single tap and its effect is immediate.
class DietLibraryScreen extends ConsumerWidget {
  const DietLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(dietLibraryBootstrapProvider);
    final plans = ref.watch(storedDietPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My diets')),
      body: bootstrap.isLoading
          ? const Center(child: CircularProgressIndicator())
          : plans.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(error.toString(), textAlign: TextAlign.center),
                ),
              ),
              data: (stored) => stored.isEmpty
                  ? const _NoDiets()
                  : _DietList(plans: stored),
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
  const _NoDiets();

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
          ],
        ),
      ),
    );
  }
}
