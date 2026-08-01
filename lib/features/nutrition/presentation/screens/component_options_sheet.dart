import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_diet_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Lets the user pick one of the alternatives the dietitian listed for a single
/// item, for one day only.
Future<void> showComponentOptionsSheet({
  required BuildContext context,
  required DietDayComponent component,
  required NutritionDay day,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ComponentOptionsSheet(component: component, day: day),
  );
}

class _ComponentOptionsSheet extends ConsumerWidget {
  const _ComponentOptionsSheet({required this.component, required this.day});

  final DietDayComponent component;
  final NutritionDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(dietDayControllerProvider(day).notifier);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              component.sectionLabel ?? 'Alternatives',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              // These come straight from the plan and are already nutritionally
              // interchangeable, computed by whoever wrote it. The app does not
              // re-rank them, so the user sees the author's order.
              'Options your plan lists as equivalent, in its own order',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: RadioGroup<String>(
              groupValue: component.chosen.id,
              onChanged: (value) async {
                if (value == null || value == component.chosen.id) return;
                Navigator.of(context).pop();
                await controller.chooseOption(
                  componentId: component.componentId,
                  optionId: value,
                );
              },
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: component.options.length,
                itemBuilder: (context, index) {
                  final option = component.options[index];
                  final isPlanDefault = index == 0;
                  return RadioListTile<String>(
                    key: Key('option-${option.id}'),
                    value: option.id,
                    title: Text(option.rawText),
                    subtitle: isPlanDefault
                        ? Text(
                            "Plan's first choice",
                            style: theme.textTheme.bodySmall,
                          )
                        : null,
                  );
                },
              ),
            ),
          ),
          if (component.isDeviation)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: TextButton.icon(
                key: const Key('resetComponentOption'),
                icon: const Icon(Icons.undo),
                label: const Text("Back to the plan's choice"),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await controller.resetOption(component.componentId);
                },
              ),
            ),
        ],
      ),
    );
  }
}
