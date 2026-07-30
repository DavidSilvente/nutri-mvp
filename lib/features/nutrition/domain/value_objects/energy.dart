/// Energy intake, expressed in kilocalories (kcal).
///
/// [kcal] MUST be non-negative.
class Energy {
  Energy({required this.kcal}) {
    if (kcal < 0) {
      throw ArgumentError.value(kcal, 'kcal', 'must be >= 0');
    }
  }

  final num kcal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Energy && other.kcal == kcal);

  @override
  int get hashCode => kcal.hashCode;

  @override
  String toString() => 'Energy(kcal: $kcal)';
}
