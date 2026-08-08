import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_store.dart';
import '../ports/option_choice_source.dart';
import '../value_objects/nutrition_day.dart';
import 'derived_targets.dart';

/// Answers [OptionChoiceSource] from the store's day-scoped selections and the
/// user's standing preferences.
///
/// The one adapter between "which option is in force today" and the store
/// that records it, so use cases never call `DietPlanStore` directly for this.
class StoredOptionChoices implements OptionChoiceSource {
  StoredOptionChoices(this._store);

  final DietPlanStore _store;

  @override
  Future<Result<OptionChoices, NutritionFailure>> choicesFor(
    NutritionDay day,
  ) async {
    final selectionsResult = await _store.selectionsFor(day);
    final Map<String, String> daySelections;
    switch (selectionsResult) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        daySelections = value;
    }

    final preferencesResult = await _store.preferredOptions();
    return switch (preferencesResult) {
      Err(failure: final failure) => Err(failure),
      Ok(value: final preferences) => Ok(
        OptionChoices(daySelections: daySelections, preferences: preferences),
      ),
    };
  }
}
