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
class SavedMeal {
  SavedMeal({
    required this.id,
    required this.name,
    required this.target,
    this.portionNote,
    required DateTime createdAt,
  }) : createdAt = createdAt.toUtc() {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
  }

  final String id;
  final String name;
  final NutritionTarget target;

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
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedMeal &&
          other.id == id &&
          other.name == name &&
          other.target == target &&
          other.portionNote == portionNote &&
          other.createdAt == createdAt);

  @override
  int get hashCode =>
      Object.hash(id, name, target, portionNote, createdAt);

  @override
  String toString() =>
      'SavedMeal(id: $id, name: $name, target: $target, '
      'portionNote: $portionNote, createdAt: $createdAt)';
}
