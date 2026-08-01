import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';

/// Screen to register water intake (in ml) and view today's hydration
/// entries. Fully independent from `RecordIntakeScreen`/`DailySummaryScreen`
/// — hydration is its own aggregate with its own flow (see `hydration-log`
/// design), mirroring the record+daily pattern of nutrition in a single
/// screen instead of two.
class HydrationScreen extends ConsumerStatefulWidget {
  const HydrationScreen({super.key});

  @override
  ConsumerState<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends ConsumerState<HydrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _volumeController = TextEditingController();

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final entry = HydrationEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      recordedAt: DateTime.now(),
      volume: WaterVolume(ml: num.parse(_volumeController.text)),
    );

    await ref.read(hydrationControllerProvider.notifier).record(entry);

    if (!mounted) return;
    _volumeController.clear();
  }

  String? _requiredNonNegativeNumber(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    final parsed = num.tryParse(value);
    if (parsed == null || parsed < 0) return 'Debe ser un número >= 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(hydrationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hidratación de hoy')),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('volumeField'),
                      controller: _volumeController,
                      decoration: const InputDecoration(labelText: 'Agua (ml)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _requiredNonNegativeNumber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('submitButton'),
                    onPressed: _submit,
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(child: Text('Sin registros de agua hoy'));
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(title: Text('${entry.volume.ml} ml'));
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
    );
  }
}
