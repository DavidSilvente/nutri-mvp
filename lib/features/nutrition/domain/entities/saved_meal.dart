import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// A user-owned catalogue entry: a named meal with a nutritional target,
/// created directly or promoted from a logged [NutritionEntry].
///
/// [SavedMeal] is independent of `MenuItems` and `MealSubstitute` — it is not
/// scoped to any plan or planned meal, and deleting it never cascades into
/// logged intake, which is an independent snapshot copy (see
/// `NutritionEntry`).
///
/// Numeric validation ([target]'s energy/macros) is delegated entirely to
/// [Energy] and [Macros]. This entity only guards its own invariant: the
/// name.
///
/// [ingredients] is the OPTIONAL food-first composition backing [target],
/// mirroring `MealComponent.options`; empty for a hand-typed meal or one
/// saved before this change. Unlike a logged [NutritionEntry], a saved meal
/// is a reusable TEMPLATE — editing its composition and re-saving via
/// [SavedMeal.composed] recomputes only [target], and never mutates any
/// entry a previous log already copied from it. The plain constructor is for
/// storage rehydration and manual entry only — see the equivalent note on
/// [NutritionEntry].
class SavedMeal {
  SavedMeal({
    required this.id,
    required this.name,
    required this.target,
    this.portionNote,
    required DateTime createdAt,
    List<LoggedIngredient> ingredients = const [],
  }) : createdAt = createdAt.toUtc(),
       ingredients = List.unmodifiable(ingredients) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
  }

  /// Builds a meal whose [target] is DERIVED from [composition].
  factory SavedMeal.composed({
    required String id,
    required String name,
    required DerivedComposition composition,
    String? portionNote,
    required DateTime createdAt,
  }) => SavedMeal(
    id: id,
    name: name,
    target: composition.target,
    portionNote: portionNote,
    createdAt: createdAt,
    ingredients: composition.ingredients,
  );

  final String id;
  final String name;
  final NutritionTarget target;
  final List<LoggedIngredient> ingredients;

  /// Optional free-text note (e.g. a portion size). Excluded from all
  /// macro/energy math and ranking.
  final String? portionNote;

  /// When this meal was saved, ALWAYS normalized to UTC.
  ///
  /// Normalized for the same reason as `StoredDietPlan.importedAt`: storage
  /// round-trips lose the UTC flag, so the same instant would otherwise
  /// compare unequal after a read-back and break entity equality for no real
  /// difference.
  final DateTime createdAt;

  /// The name, trimmed and case-folded, for uniqueness comparisons.
  ///
  /// Kept as a single derived getter so every caller (the SQL adapter, the
  /// fake) compares duplicates the same way instead of re-implementing the
  /// trim + case-fold rule independently.
  String get normalizedName => name.trim().toLowerCase();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SavedMeal) return false;
    if (other.id != id ||
        other.name != name ||
        other.target != target ||
        other.portionNote != portionNote ||
        other.createdAt != createdAt ||
        other.ingredients.length != ingredients.length) {
      return false;
    }
    for (var i = 0; i < ingredients.length; i++) {
      if (other.ingredients[i] != ingredients[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    target,
    portionNote,
    createdAt,
    Object.hashAll(ingredients),
  );

  @override
  String toString() =>
      'SavedMeal(id: $id, name: $name, target: $target, '
      'portionNote: $portionNote, createdAt: $createdAt, '
      'ingredients: $ingredients)';
}
