/// A sealed result type representing either a success ([Ok]) or a
/// failure ([Err]), without relying on exceptions for expected error paths.
sealed class Result<S, F> {
  const Result();

  /// Whether this result is a success ([Ok]).
  bool get isOk => this is Ok<S, F>;

  /// Whether this result is a failure ([Err]).
  bool get isErr => this is Err<S, F>;

  /// Transforms the success value when this is an [Ok], leaving an [Err]
  /// untouched.
  Result<T, F> map<T>(T Function(S value) transform) {
    final self = this;
    return switch (self) {
      Ok<S, F>() => Ok<T, F>(transform(self.value)),
      Err<S, F>() => Err<T, F>(self.failure),
    };
  }
}

/// A successful [Result] carrying a [value].
final class Ok<S, F> extends Result<S, F> {
  const Ok(this.value);

  final S value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<S, F> && other.value == value);

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'Ok($value)';
}

/// A failed [Result] carrying a [failure].
final class Err<S, F> extends Result<S, F> {
  const Err(this.failure);

  final F failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Err<S, F> && other.failure == failure);

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @override
  String toString() => 'Err($failure)';
}
