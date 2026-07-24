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
