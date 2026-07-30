import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/hydration_screen.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/record_intake_screen.dart';

/// Screen that lists today's nutrition entries (energy and macros) and lets
/// the user navigate to [RecordIntakeScreen] to register a new one. Also
/// shows today's hydration total, kept strictly separate from the meal
/// list, with its own dedicated entry point (an app bar action, distinct
/// from the meal FAB) to [HydrationScreen].
class DailySummaryScreen extends ConsumerWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(nutritionControllerProvider);
    final hydrationAsync = ref.watch(hydrationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingestas de hoy'),
        actions: [
          IconButton(
            key: const Key('goToHydrationButton'),
            icon: const Icon(Icons.water_drop),
            tooltip: 'Registrar agua',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HydrationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: hydrationAsync.when(
                data: (entries) {
                  final totalMl = entries.fold<num>(
                    0,
                    (sum, entry) => sum + entry.volume.ml,
                  );
                  return Text('Hidratación de hoy: $totalMl ml');
                },
                loading: () => const Text('Hidratación de hoy: ...'),
                error: (error, stackTrace) =>
                    const Text('Hidratación de hoy: error'),
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('Sin ingestas registradas hoy'),
                  );
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      title: Text('${entry.energy.kcal} kcal'),
                      subtitle: Text(
                        'P: ${entry.macros.proteinG}g · '
                        'C: ${entry.macros.carbsG}g · '
                        'G: ${entry.macros.fatG}g',
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addIntakeButton'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RecordIntakeScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
