import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_plan_codec.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/diet_template.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/meal_slot_directory.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/meal_slot_index.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/save_manual_diet.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// One meal of a hand-written diet.
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

/// A diet as `SaveManualDiet` would have stored it: a plan document of
/// hand-entered meals, covering every weekday.
///
/// Tests seed this into a `FakeDietPlanStore` instead of building a document by
/// hand, so they exercise the same encode the app writes and cannot drift from
/// the shape the decoder expects.
StoredDietPlan manualDiet({
  String id = 'diet-1',
  String name = 'Test diet',
  required List<DietMealSlot> slots,
  bool isDefault = true,
  Set<int>? weekdays,
  DateTime? importedAt,
}) {
  final plan = DietPlan(
    id: id,
    name: name,
    dayGroups: [
      DietPlanDayGroup(
        label: SaveManualDiet.everyDayLabel,
        weekdays:
            weekdays ??
            {
              for (var weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++)
                weekday,
            },
        template: DietTemplate.derived(
          id: '$id:g0',
          name: '$name — ${SaveManualDiet.everyDayLabel}',
          slots: slots,
        ),
      ),
    ],
  );

  final encoded = const DietPlanCodec().encode(plan);
  final document = switch (encoded) {
    Ok(value: final value) => value,
    Err(failure: final failure) =>
      throw StateError('fixture diet failed to encode: $failure'),
  };

  return StoredDietPlan(
    id: id,
    name: name,
    document: document,
    importedAt: importedAt ?? DateTime.utc(2026, 8, 1),
    isDefault: isDefault,
    sourceLabel: SaveManualDiet.manualSourceLabel,
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
