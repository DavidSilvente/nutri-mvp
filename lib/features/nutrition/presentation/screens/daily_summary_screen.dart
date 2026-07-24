import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/screens/record_intake_screen.dart';

/// Screen that lists today's nutrition entries (energy, macros and water)
/// and lets the user navigate to [RecordIntakeScreen] to register a new one.
class DailySummaryScreen extends ConsumerWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(nutritionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ingestas de hoy')),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Sin ingestas registradas hoy'));
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
                  'G: ${entry.macros.fatG}g · '
                  'Agua: ${entry.water.ml}ml',
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
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
