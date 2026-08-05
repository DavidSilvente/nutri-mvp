import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/option_choice_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// An [OptionChoiceSource] answered from maps handed to it directly, so a use
/// case test can state "these are today's choices" without standing up a
/// store.
///
/// Both maps apply regardless of which [NutritionDay] is asked about: a real
/// implementation would key [daySelections] by day, but PR1's callers only
/// ever resolve one day at a time, so this fake keeps the simpler shape its
/// tests need.
class FakeOptionChoiceSource implements OptionChoiceSource {
  /// Component id -> option id, as if recorded for whichever day is asked
  /// about.
  Map<String, String> daySelections = const {};

  /// Component id -> option id, the user's standing preference.
  Map<String, String> preferences = const {};

  /// Fails every call with this failure when set, so error paths are testable.
  NutritionFailure? failWith;

  @override
  Future<Result<OptionChoices, NutritionFailure>> choicesFor(
    NutritionDay day,
  ) async {
    final failure = failWith;
    if (failure != null) return Err(failure);

    return Ok(
      OptionChoices(daySelections: daySelections, preferences: preferences),
    );
  }
}
