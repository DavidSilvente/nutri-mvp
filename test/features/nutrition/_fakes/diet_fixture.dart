import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/meal_slot_directory.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/meal_slot_index.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// One meal of a diet.
///
/// Defaults add up to something plausible so a test that only cares about
/// labels and ordering does not have to invent macros.
DietMealSlot mealSlot({
  required String id,
  String label = 'Meal',
  int position = 0,
  num kcal = 500,
  num proteinG = 30,
  num carbsG = 55,
  num fatG = 15,
  String? timeOfDay,
  List<String> notes = const [],
}) {
  return DietMealSlot(
    id: id,
    label: label,
    position: position,
    timeOfDay: timeOfDay,
    notes: notes,
    target: NutritionTarget(
      energy: Energy(kcal: kcal),
      macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
    ),
  );
}

/// A [MealSlotDirectory] that answers from slots handed to it.
///
/// Lets a use-case test say "these are the diet's meals" without standing up a
/// store, a food table and a codec just to name a slot.
class FakeMealSlotDirectory implements MealSlotDirectory {
  FakeMealSlotDirectory({
    List<DietMealSlot> slots = const [],
    this.dayGroupLabel = 'EVERY DAY',
  }) : slots = [...slots];

  /// Mutable so a test can define the diet AFTER the use case under test has
  /// already been handed the directory.
  final List<DietMealSlot> slots;

  final String dayGroupLabel;

  /// Fails every call with this failure when set, so error paths are testable.
  NutritionFailure? failWith;

  @override
  Future<Result<MealSlotIndex, NutritionFailure>> activeSlots() async {
    final failure = failWith;
    if (failure != null) return Err(failure);

    return Ok(
      MealSlotIndex({
        for (final slot in slots)
          slot.id: MealSlotInfo(
            label: slot.label,
            position: slot.position,
            dayGroupLabel: dayGroupLabel,
          ),
      }),
    );
  }
}
