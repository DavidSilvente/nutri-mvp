import 'package:nutri_mvp/core/result.dart';

import '../entities/diet_plan.dart';
import '../entities/diet_template.dart';
import '../entities/stored_diet_plan.dart';
import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_decoder.dart';
import '../ports/diet_plan_store.dart';

/// Stores a diet the user typed into the app.
///
/// A hand-written diet goes into the SAME store as an imported one, as a plan
/// document with hand-entered meals. That is the whole point: there is one place
/// a diet lives, so the day view, the calendar and adherence do not care where
/// it came from.
///
/// The label every group carries covers the full week, because a diet typed by
/// hand describes "my typical day" rather than a per-weekday menu. Nothing in
/// the model stops a future editor from splitting it.
class SaveManualDiet {
  SaveManualDiet({
    required DietPlanStore store,
    required DietPlanEncoder encoder,
    required DateTime Function() now,
  }) : _store = store,
       _encoder = encoder,
       _now = now;

  final DietPlanStore _store;
  final DietPlanEncoder _encoder;
  final DateTime Function() _now;

  /// The label used for the single day group of a hand-written diet.
  static const String everyDayLabel = 'EVERY DAY';

  /// Marks a stored plan as hand-written rather than imported.
  ///
  /// Read by the diet library to decide whether to offer an edit, which is a
  /// cheap check it can make without decoding every stored document. It drives
  /// the UI only — the editor still verifies the actual slots before writing, so
  /// a wrong label can hide the button but can never corrupt a plan.
  static const String manualSourceLabel = 'Created in the app';

  /// Persists the diet named [name] with [slots].
  ///
  /// [planId] is null when creating. Editing MUST pass the existing id, and the
  /// caller MUST reuse each slot's existing id, so the planned meals and
  /// alternative choices already keyed to them keep resolving.
  Future<Result<StoredDietPlan, NutritionFailure>> call({
    String? planId,
    required String name,
    required List<DietMealSlot> slots,
    bool makeActive = true,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(MalformedPlanFailure('a diet needs a name'));
    }
    if (slots.isEmpty) {
      return const Err(
        MalformedPlanFailure('a diet needs at least one meal'),
      );
    }
    final ids = slots.map((slot) => slot.id).toSet();
    if (ids.length != slots.length) {
      return const Err(
        MalformedPlanFailure('two meals cannot share the same id'),
      );
    }

    final id = planId ?? 'manual-${_now().microsecondsSinceEpoch}';

    final DietPlan plan;
    try {
      plan = DietPlan(
        id: id,
        name: trimmed,
        dayGroups: [
          DietPlanDayGroup(
            label: everyDayLabel,
            weekdays: {
              for (var weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++)
                weekday,
            },
            // Derived so the daily target is the sum of the meals rather than a
            // second figure that could disagree with them.
            template: DietTemplate.derived(
              id: '$id:g0',
              name: '$trimmed — $everyDayLabel',
              slots: slots,
            ),
          ),
        ],
      );
    } on ArgumentError catch (error) {
      return Err(MalformedPlanFailure('invalid diet: ${error.message}'));
    }

    final document = _encoder.encode(plan);
    final String encoded;
    switch (document) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        encoded = value;
    }

    return _store.savePlan(
      StoredDietPlan(
        id: id,
        name: trimmed,
        document: encoded,
        importedAt: _now(),
        isDefault: makeActive,
        sourceLabel: manualSourceLabel,
      ),
    );
  }
}
