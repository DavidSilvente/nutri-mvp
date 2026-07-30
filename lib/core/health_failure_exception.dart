import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';

/// Wraps a [NutritionFailure] so it can travel through an `AsyncValue.error`
/// (which requires an [Object], not a domain-specific sealed type).
///
/// Named agnostic of any single aggregate (nutrition, hydration, ...) since
/// [NutritionFailure] is the shared failure type reused across the
/// nutrition-tracking feature's independent aggregates — see the
/// `hydration-log` design for the rationale on reusing this failure type.
class HealthFailureException implements Exception {
  const HealthFailureException(this.failure);

  final NutritionFailure failure;

  @override
  String toString() => 'HealthFailureException($failure)';
}
