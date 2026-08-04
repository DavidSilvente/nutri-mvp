/// An imported diet plan as it sits in storage: metadata plus the normalized
/// document it was imported from.
///
/// The [document] is kept verbatim rather than exploded into rows because the
/// plan is immutable once imported. Decoding it into a `DietPlan` needs a food
/// catalog, which is a concern of the read path, not of storage.
class StoredDietPlan {
  StoredDietPlan({
    required this.id,
    required this.name,
    required this.document,
    required DateTime importedAt,
    this.declaredDailyEnergyKcal,
    this.isDefault = false,
    this.sourceLabel,
  }) : importedAt = importedAt.toUtc() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (document.trim().isEmpty) {
      throw ArgumentError.value(document, 'document', 'must not be empty');
    }
  }

  final String id;
  final String name;

  /// The normalized plan JSON, decodable by `DietPlanCodec`.
  final String document;

  /// When the plan was imported, ALWAYS normalized to UTC.
  ///
  /// Normalized because storage round-trips lose the UTC flag: drift persists a
  /// timestamp and hands it back as a local `DateTime`, so the same instant
  /// compares unequal (`2026-08-01T00:00Z` vs `2026-08-01T02:00+02:00`) and
  /// entity equality would break for no real difference. Anchoring on UTC keeps
  /// a stored plan equal to the one that was written.
  final DateTime importedAt;

  /// Headline daily energy the source plan advertised. Display only.
  final num? declaredDailyEnergyKcal;

  /// Whether this is the user's current diet.
  final bool isDefault;

  final String? sourceLabel;

  StoredDietPlan copyWith({bool? isDefault}) => StoredDietPlan(
    id: id,
    name: name,
    document: document,
    importedAt: importedAt,
    declaredDailyEnergyKcal: declaredDailyEnergyKcal,
    isDefault: isDefault ?? this.isDefault,
    sourceLabel: sourceLabel,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredDietPlan &&
          other.id == id &&
          other.name == name &&
          other.document == document &&
          other.importedAt == importedAt &&
          other.declaredDailyEnergyKcal == declaredDailyEnergyKcal &&
          other.isDefault == isDefault &&
          other.sourceLabel == sourceLabel);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    document,
    importedAt,
    declaredDailyEnergyKcal,
    isDefault,
    sourceLabel,
  );

  @override
  String toString() =>
      'StoredDietPlan(id: $id, name: $name, isDefault: $isDefault, '
      'importedAt: $importedAt)';
}
