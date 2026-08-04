import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../services/meal_slot_index.dart';

/// Domain port for naming and ordering the meal slots a planned meal refers to.
///
/// A [PlannedMeal] stores only a slot id and the target it was frozen at. Turning
/// that back into "Breakfast, first meal of the day" needs the diet it came from,
/// and the day and month views need nothing else from it.
///
/// Stated as a port so those use cases depend on the QUESTION rather than on the
/// machinery that answers it: resolving the active diet means reading a store,
/// loading a food composition table and decoding a document, none of which a
/// use case about adherence should know about.
abstract interface class MealSlotDirectory {
  /// The slots of the user's current diet.
  ///
  /// An empty index when no diet is active. That is an ordinary state — intake
  /// logged before any diet existed still has to render — so it is NOT a
  /// failure.
  Future<Result<MealSlotIndex, NutritionFailure>> activeSlots();
}
