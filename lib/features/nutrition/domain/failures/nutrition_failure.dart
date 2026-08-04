/// Platform-agnostic failures reported by a `NutritionHealthSource` through
/// `Result`, instead of throwing. These variants MUST NOT leak
/// platform-specific concepts (HealthKit/Health Connect/drift types).
sealed class NutritionFailure {
  const NutritionFailure();
}

/// The underlying source denied access to nutrition data (e.g. a
/// HealthKit/Health Connect authorization was refused by the user).
///
/// Manual/SQL-backed sources MUST NEVER produce this variant — it exists
/// purely so the domain can express "authorization was denied" without a
/// dedicated authorization method on the port.
final class PermissionDenied extends NutritionFailure {
  const PermissionDenied();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PermissionDenied;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'PermissionDenied()';
}

/// The underlying source is not available (e.g. the platform API required
/// to read/write nutrition data is missing or disabled).
final class SourceUnavailable extends NutritionFailure {
  const SourceUnavailable();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SourceUnavailable;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SourceUnavailable()';
}

/// A storage-level failure occurred while recording or querying nutrition
/// data, carrying a human-readable [reason].
final class StorageFailure extends NutritionFailure {
  const StorageFailure(this.reason);

  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageFailure && other.reason == reason);

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'StorageFailure(reason: $reason)';
}

/// Structured plan or food-table data could not be read because it is missing
/// required fields, carries the wrong types, or declares an unsupported schema
/// version.
///
/// Distinct from [StorageFailure]: the bytes were retrieved fine, their SHAPE is
/// wrong. Keeping them apart lets the UI say "this file is not a plan we
/// understand" instead of blaming the database.
final class MalformedPlanFailure extends NutritionFailure {
  const MalformedPlanFailure(this.reason);

  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MalformedPlanFailure && other.reason == reason);

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'MalformedPlanFailure(reason: $reason)';
}

/// A meal component references food ids that the food catalog cannot resolve,
/// so its macros cannot be derived.
///
/// Carries EVERY unresolved id rather than just the first, so an import can
/// report the whole gap in one pass instead of surfacing them one at a time.
final class UnknownFoodFailure extends NutritionFailure {
  UnknownFoodFailure(Set<String> foodIds)
    : foodIds = Set.unmodifiable(foodIds) {
    if (foodIds.isEmpty) {
      throw ArgumentError.value(
        foodIds,
        'foodIds',
        'must name at least one unresolved food',
      );
    }
  }

  final Set<String> foodIds;

  /// Ids in a stable order, for messages and assertions.
  List<String> get sortedIds => foodIds.toList()..sort();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnknownFoodFailure &&
          other.foodIds.length == foodIds.length &&
          other.foodIds.containsAll(foodIds));

  @override
  int get hashCode => Object.hashAllUnordered(foodIds);

  @override
  String toString() => 'UnknownFoodFailure(foodIds: ${sortedIds.join(', ')})';
}

/// A conflict failure reported when a uniqueness or ordering constraint is
/// violated (e.g. a duplicate template name or a slot already planned for the
/// same day).
final class ConflictFailure extends NutritionFailure {
  const ConflictFailure(this.reason);

  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictFailure && other.reason == reason);

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'ConflictFailure(reason: $reason)';
}
