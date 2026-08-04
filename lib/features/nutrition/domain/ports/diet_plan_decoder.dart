import 'package:nutri_mvp/core/result.dart';

import '../entities/diet_plan.dart';
import '../failures/nutrition_failure.dart';
import '../services/food_catalog.dart';

/// A decoded plan document: the plan plus the catalog its foods resolve against.
///
/// The catalog travels with the plan because a plan can define its own recipes,
/// and anything that later recomputes macros (swapping an alternative, editing
/// grams) must resolve foods against the SAME catalog the decode used.
class DecodedDietPlan {
  const DecodedDietPlan({required this.plan, required this.catalog});

  final DietPlan plan;
  final FoodCatalog catalog;
}

/// Domain port for turning a stored plan document into a [DietPlan].
///
/// The document format is a data-layer concern, so the domain states only what
/// it needs — "give me the plan and its catalog" — and an adapter owns the JSON.
/// Without this port a use case would have to import the codec directly and the
/// domain would depend on the data layer.
abstract interface class DietPlanDecoder {
  /// Decodes [document], resolving foods against [baseCatalog] plus any recipes
  /// the document defines.
  ///
  /// [planId] namespaces the generated ids and MUST be stable for a given
  /// stored plan, since per-day alternative selections are keyed by them.
  Result<DecodedDietPlan, NutritionFailure> decode(
    String document, {
    required FoodCatalog baseCatalog,
    required String planId,
    bool isDefault = false,
    String? sourceLabel,
  });
}
