import '../value_objects/energy.dart';
import '../value_objects/food_quantity.dart';
import '../value_objects/macros.dart';
import '../value_objects/nutrition_target.dart';

/// Where a food's macro values came from.
///
/// This is surfaced in the UI, not just bookkeeping: a value the user can trust
/// (a published composition table) and a value someone guessed must not look
/// identical on screen.
enum FoodDataSource {
  /// USDA FoodData Central, SR Legacy. Public domain (CC0 1.0).
  usdaSrLegacy,

  /// A recipe printed in the imported diet plan, with its own nutrition table
  /// computed by the dietitian. Authoritative for that plan — it beats a
  /// generic table entry, because it is what the plan actually prescribes.
  planRecipe,

  /// No published entry matched, so the value is a reference estimate that the
  /// user should review.
  estimated;

  /// Whether a value from this source warrants a review prompt in the UI.
  bool get needsReview => this == FoodDataSource.estimated;
}

/// How a food is prepared, which materially changes its composition.
///
/// This is NOT cosmetic. Raw and boiled rice differ by roughly 3x in energy
/// density (365 vs 130 kcal/100 g), so dropping the preparation state while
/// matching a plan line to a food is one of the largest error sources in the
/// whole import.
enum FoodPreparation {
  raw,
  boiled,
  baked,
  grilled,
  roasted,
  cooked,
  cured,
  canned,
  readyToEat;

  static FoodPreparation parse(String raw) => switch (raw) {
    'raw' => FoodPreparation.raw,
    'boiled' => FoodPreparation.boiled,
    'baked' => FoodPreparation.baked,
    'grilled' => FoodPreparation.grilled,
    'roasted' => FoodPreparation.roasted,
    'cooked' => FoodPreparation.cooked,
    'cured' => FoodPreparation.cured,
    'canned' => FoodPreparation.canned,
    'ready_to_eat' => FoodPreparation.readyToEat,
    _ => throw ArgumentError.value(raw, 'preparation', 'unknown value'),
  };

  String get wireName => switch (this) {
    FoodPreparation.raw => 'raw',
    FoodPreparation.boiled => 'boiled',
    FoodPreparation.baked => 'baked',
    FoodPreparation.grilled => 'grilled',
    FoodPreparation.roasted => 'roasted',
    FoodPreparation.cooked => 'cooked',
    FoodPreparation.cured => 'cured',
    FoodPreparation.canned => 'canned',
    FoodPreparation.readyToEat => 'ready_to_eat',
  };
}

/// A food with a known composition per 100 g.
///
/// This is the entity the whole food-first model rests on: meal components
/// reference a [FoodItem] plus a quantity, and every macro figure shown to the
/// user is DERIVED from those two things rather than typed in by hand.
class FoodItem {
  FoodItem({
    required this.id,
    required this.name,
    required this.preparation,
    required this.per100g,
    required this.source,
    this.sourceRef,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
  }

  /// Stable slug (e.g. `chicken_breast_grilled`).
  final String id;

  /// Display name, in the language of the plan the food came from.
  final String name;

  final FoodPreparation preparation;

  /// Composition per 100 g.
  final NutritionTarget per100g;

  final FoodDataSource source;

  /// Identifier within [source] (e.g. an FDC id). Null for estimates.
  final String? sourceRef;

  /// Scales this food's composition to [quantity].
  NutritionTarget targetFor(FoodQuantity quantity) {
    final factor = quantity.per100gFactor;
    return NutritionTarget(
      energy: Energy(kcal: per100g.energy.kcal.toDouble() * factor),
      macros: Macros(
        proteinG: per100g.macros.proteinG.toDouble() * factor,
        carbsG: per100g.macros.carbsG.toDouble() * factor,
        fatG: per100g.macros.fatG.toDouble() * factor,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodItem &&
          other.id == id &&
          other.name == name &&
          other.preparation == preparation &&
          other.per100g == per100g &&
          other.source == source &&
          other.sourceRef == sourceRef);

  @override
  int get hashCode =>
      Object.hash(id, name, preparation, per100g, source, sourceRef);

  @override
  String toString() =>
      'FoodItem(id: $id, name: $name, preparation: ${preparation.wireName}, '
      'per100g: $per100g, source: $source, sourceRef: $sourceRef)';
}
