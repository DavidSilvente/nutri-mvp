import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_template_editor_screen.dart';

/// Lists reusable diet templates and navigates to the editor for create/edit.
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
                onTap: () => _openEditor(context, template.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addTemplateButton'),
        onPressed: () => _openEditor(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditor(BuildContext context, String? templateId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DietTemplateEditorScreen(templateId: templateId),
      ),
    );
  }
}
