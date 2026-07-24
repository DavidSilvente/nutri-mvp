/// Water intake, expressed in milliliters (ml).
///
/// [ml] MUST be non-negative.
class WaterVolume {
  WaterVolume({required this.ml}) {
    if (ml < 0) {
      throw ArgumentError.value(ml, 'ml', 'must be >= 0');
    }
  }

  final num ml;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is WaterVolume && other.ml == ml);

  @override
  int get hashCode => ml.hashCode;

  @override
  String toString() => 'WaterVolume(ml: $ml)';
}
