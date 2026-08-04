import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_store.dart';
import '../ports/option_choice_source.dart';
import '../value_objects/nutrition_day.dart';
import 'derived_targets.dart';

/// Answers [OptionChoiceSource] from the store's day-scoped selections.
///
/// The one adapter between "which option is in force today" and the store
/// that records it, so use cases never call `DietPlanStore` directly for this.
///
/// [preferences] stays empty here: the user-level preference table does not
/// exist yet. Wiring it in is a data-only change confined to this class —
/// nothing above it (the port, or its callers) needs to change when it lands.
class StoredOptionChoices implements OptionChoiceSource {
  StoredOptionChoices(this._store);

  final DietPlanStore _store;

  @override
  Future<Result<OptionChoices, NutritionFailure>> choicesFor(
    NutritionDay day,
  ) async {
    final selectionsResult = await _store.selectionsFor(day);
    return switch (selectionsResult) {
      Err(failure: final failure) => Err(failure),
      Ok(value: final daySelections) => Ok(
        OptionChoices(daySelections: daySelections),
      ),
    };
  }
}
