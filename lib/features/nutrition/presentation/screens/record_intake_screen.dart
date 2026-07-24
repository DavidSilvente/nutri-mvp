import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/water_volume.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';

/// Screen to register a new nutrition intake: energy, macros (protein,
/// carbs, fat) and water.
class RecordIntakeScreen extends ConsumerStatefulWidget {
  const RecordIntakeScreen({super.key});

  @override
  ConsumerState<RecordIntakeScreen> createState() => _RecordIntakeScreenState();
}

class _RecordIntakeScreenState extends ConsumerState<RecordIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _energyController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _waterController = TextEditingController();

  @override
  void dispose() {
    _energyController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final entry = NutritionEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      recordedAt: DateTime.now(),
      energy: Energy(kcal: num.parse(_energyController.text)),
      macros: Macros(
        proteinG: num.parse(_proteinController.text),
        carbsG: num.parse(_carbsController.text),
        fatG: num.parse(_fatController.text),
      ),
      water: WaterVolume(ml: num.parse(_waterController.text)),
    );

    await ref.read(nutritionControllerProvider.notifier).record(entry);

    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  String? _requiredNonNegativeNumber(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    final parsed = num.tryParse(value);
    if (parsed == null || parsed < 0) return 'Debe ser un número >= 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ingesta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('energyField'),
              controller: _energyController,
              decoration: const InputDecoration(labelText: 'Energía (kcal)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _requiredNonNegativeNumber,
            ),
            TextFormField(
              key: const Key('proteinField'),
              controller: _proteinController,
              decoration: const InputDecoration(labelText: 'Proteína (g)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _requiredNonNegativeNumber,
            ),
            TextFormField(
              key: const Key('carbsField'),
              controller: _carbsController,
              decoration: const InputDecoration(labelText: 'Carbohidratos (g)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _requiredNonNegativeNumber,
            ),
            TextFormField(
              key: const Key('fatField'),
              controller: _fatController,
              decoration: const InputDecoration(labelText: 'Grasa (g)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _requiredNonNegativeNumber,
            ),
            TextFormField(
              key: const Key('waterField'),
              controller: _waterController,
              decoration: const InputDecoration(labelText: 'Agua (ml)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _requiredNonNegativeNumber,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('submitButton'),
              onPressed: _submit,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
