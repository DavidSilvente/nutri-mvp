import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/format/nutrition_format.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/diet_template_editor_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/macro_breakdown.dart';

/// Lists reusable diet templates and navigates to the editor for create/edit.
class DietTemplatesScreen extends ConsumerWidget {
  const DietTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(dietPlanControllerProvider);

    return Scaffold(
      key: const Key('dietTemplatesScreen'),
      appBar: AppBar(title: const Text('My diets')),
      body: SafeArea(
        child: stateAsync.when(
          data: (state) {
            final templates = state.templates;
            if (templates.isEmpty) return const _EmptyTemplates();

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: templates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _TemplateCard(
                template: templates[index],
                index: index,
                onTap: () => _openEditor(context, templates[index].id),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addTemplateButton'),
        // Explicit tag: this screen shares a subtree with the day view's FAB
        // inside the home IndexedStack, and two default-tagged heroes in one
        // subtree is a runtime error.
        heroTag: 'addTemplateFab',
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New diet'),
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.index,
    required this.onTap,
  });

  final DietTemplate template;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        key: Key('templateTile_$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                NutritionFormat.kcal(template.dailyTarget.energy.kcal),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              MacroSummaryLine(target: template.dailyTarget),
              const SizedBox(height: 12),
              Text(
                '${template.slots.length} '
                '${template.slots.length == 1 ? 'meal' : 'meals'} a day',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  const _EmptyTemplates();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      key: const Key('emptyTemplatesMessage'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No diet templates yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'A template is your diet for a typical day: the meals it has '
              'and the macros each one should hit. You then assign those '
              'meals to calendar days.',
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
