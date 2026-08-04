import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../services/derived_targets.dart';
import '../value_objects/nutrition_day.dart';

/// Domain port for answering "which option is in force" for a given
/// calendar day, at BOTH levels [OptionChoices] carries.
///
/// Stated as a port so a use case depends on the QUESTION — one call per day —
/// rather than on the store that answers it, mirroring how the meal slot
/// directory depends on "what are my meals called" instead of the machinery
/// behind it.
abstract interface class OptionChoiceSource {
  /// The day-scoped selections and the user's standing preferences, as of
  /// [day].
  Future<Result<OptionChoices, NutritionFailure>> choicesFor(NutritionDay day);
}
