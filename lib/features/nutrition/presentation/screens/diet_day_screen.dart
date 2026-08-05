import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_diet_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/component_options_sheet.dart';
import 'package:nutri_mvp/features/nutrition/presentation/widgets/section_dot.dart';

/// What the active diet prescribes for one day, meal by meal.
///
/// Shows the derived energy and macros for each meal and for the day, and lets
/// the user swap any single item for one of the alternatives the dietitian
/// listed — per item, not per meal, because that is how the plan is written.
class DietDayScreen extends ConsumerWidget {
  const DietDayScreen({required this.day, super.key});

  final NutritionDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The seed must settle before the library is read, or a fresh install shows
    // an empty state that then pops into a diet.
    final bootstrap = ref.watch(dietLibraryBootstrapProvider);
    if (bootstrap.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dayState = ref.watch(dietDayControllerProvider(day));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My diet'),
        actions: [
          IconButton(
            key: const Key('openDietLibrary'),
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch diet',
            onPressed: () => Navigator.of(context).pushNamed('/diets'),
          ),
        ],
      ),
      body: dayState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(message: error.toString()),
        data: (dietDay) => dietDay == null
            ? const _EmptyState()
            : _DayContent(dietDay: dietDay, day: day),
      ),
    );
  }
}

class _DayContent extends ConsumerWidget {
  const _DayContent({required this.dietDay, required this.day});

  final DietDay dietDay;
  final NutritionDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _DaySummary(dietDay: dietDay),
        for (final meal in dietDay.meals) _MealCard(meal: meal, day: day),
      ],
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.dietDay});

  final DietDay dietDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = dietDay.target;
    final delta = dietDay.declaredEnergyDelta;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dietDay.planName, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              dietDay.dayGroupLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${target.energy.kcal.round()} kcal',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'P ${target.macros.proteinG.round()} g  ·  '
              'C ${target.macros.carbsG.round()} g  ·  '
              'F ${target.macros.fatG.round()} g',
              style: theme.textTheme.bodyMedium,
            ),
            if (delta != null) ...[
              const SizedBox(height: 8),
              // Stated plainly rather than hidden: derived macros come from a
              // published table, so they will not match a round headline, and
              // pretending otherwise would be dishonest.
              Text(
                'Plan states ${dietDay.declaredDailyEnergyKcal!.round()} kcal '
                '(${delta >= 0 ? '+' : ''}${delta.round()})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (dietDay.needsReview) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Some items use estimated values',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealCard extends ConsumerWidget {
  const _MealCard({required this.meal, required this.day});

  final DietDayMeal meal;
  final NutritionDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (meal.timeOfDay != null) ...[
                    Text(
                      meal.timeOfDay!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(meal.label, style: theme.textTheme.titleSmall),
                  ),
                  Text(
                    '${meal.target.energy.kcal.round()} kcal',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            for (final component in meal.components)
              _ComponentTile(component: component, day: day),
            if (meal.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ExpansionTile(
                  key: Key('notes-${meal.slotId}'),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text('Notes', style: theme.textTheme.labelMedium),
                  children: [
                    for (final note in meal.notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(note, style: theme.textTheme.bodySmall),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComponentTile extends ConsumerWidget {
  const _ComponentTile({required this.component, required this.day});

  final DietDayComponent component;
  final NutritionDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      key: Key('component-${component.componentId}'),
      dense: true,
      title: Text(component.chosen.rawText),
      subtitle: Row(
        children: [
          Text(
            '${component.target.energy.kcal.round()} kcal · '
            'P ${component.target.macros.proteinG.round()} · '
            'C ${component.target.macros.carbsG.round()} · '
            'F ${component.target.macros.fatG.round()}',
            style: theme.textTheme.bodySmall,
          ),
          if (component.needsReview) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.info_outline,
              size: 13,
              color: theme.colorScheme.tertiary,
            ),
          ],
        ],
      ),
      leading: component.sectionLabel == null
          ? null
          : SectionDot(label: component.sectionLabel!),
      trailing: component.hasAlternatives
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (component.isDeviation)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.swap_horiz,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                Text(
                  '${component.options.length}',
                  style: theme.textTheme.labelSmall,
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            )
          : null,
      onTap: component.hasAlternatives
          ? () => showComponentOptionsSheet(
              context: context,
              component: component,
              day: day,
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 48),
            const SizedBox(height: 16),
            Text(
              'Nothing planned for this day',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Either no diet is active, or the active plan does not cover '
              'this weekday.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pushNamed('/diets'),
              child: const Text('Choose a diet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Extension point kept deliberately small: the day screen renders provenance
/// as an icon, and the sheet spells it out. Both read the same enum.
extension FoodDataSourceLabel on FoodDataSource {
  String get label => switch (this) {
    FoodDataSource.usdaSrLegacy => 'USDA composition table',
    FoodDataSource.planRecipe => 'Recipe from your plan',
    FoodDataSource.estimated => 'Estimated — worth checking',
  };
}
