import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Lists reusable diet templates.
///
/// Template creation/editing is intentionally deferred to the next slice; this
/// screen is the first autonomous UI step in the diet planning flow.
class DietTemplatesScreen extends ConsumerWidget {
  const DietTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(dietPlanControllerProvider);

    return Scaffold(
      key: const Key('dietTemplatesScreen'),
      appBar: AppBar(title: const Text('Diet templates')),
      body: stateAsync.when(
        data: (state) {
          final templates = state.templates;
          if (templates.isEmpty) {
            return const Center(
              key: Key('emptyTemplatesMessage'),
              child: Text('No diet templates yet'),
            );
          }
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                key: Key('templateTile_$index'),
                title: Text(template.name),
                subtitle: Text(
                  '${template.dailyTarget.energy.kcal.round()} kcal · '
                  'P: ${template.dailyTarget.macros.proteinG.round()}g · '
                  'C: ${template.dailyTarget.macros.carbsG.round()}g · '
                  'F: ${template.dailyTarget.macros.fatG.round()}g · '
                  '${template.slots.length} slots',
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addTemplateButton'),
        onPressed: () {
          // Editor deferred to PR 3B-B; this placeholder keeps the FAB present.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template editor coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
