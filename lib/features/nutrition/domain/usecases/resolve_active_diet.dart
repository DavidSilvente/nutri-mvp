import 'package:nutri_mvp/core/result.dart';

import '../entities/stored_diet_plan.dart';
import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_decoder.dart';
import '../ports/diet_plan_store.dart';
import '../ports/food_table_source.dart';
import '../services/food_catalog.dart';

/// Turns a stored plan into a usable diet: its document decoded against the
/// food table, plus whatever recipes the document defines.
///
/// Sits on its own because two callers need it for different plans — the day and
/// calendar views want the active one, the editor wants the one being edited —
/// and the catalog load is the expensive half.
class DecodeStoredDiet {
  DecodeStoredDiet({
    required FoodTableSource foodTable,
    required DietPlanDecoder decoder,
  }) : _foodTable = foodTable,
       _decoder = decoder;

  final FoodTableSource _foodTable;
  final DietPlanDecoder _decoder;

  Future<Result<DecodedDietPlan, NutritionFailure>> call(
    StoredDietPlan plan, {
    bool isDefault = false,
  }) async {
    final foods = await _foodTable.loadFoods();
    final FoodCatalog baseCatalog;
    switch (foods) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final items):
        baseCatalog = FoodCatalog(items);
    }

    return _decoder.decode(
      plan.document,
      baseCatalog: baseCatalog,
      // MUST be the stored id: per-day alternative choices are keyed by ids
      // namespaced with it, so decoding under a different one orphans them.
      planId: plan.id,
      isDefault: isDefault,
      sourceLabel: plan.sourceLabel,
    );
  }
}

/// Reads the user's ACTIVE diet and decodes it.
///
/// Every screen that needs to know what the diet prescribes goes through here,
/// which is what makes "the active diet" a single fact rather than something
/// each caller assembles for itself. Before this existed the day view resolved
/// the store, the food table and the decoder on its own, while the calendar read
/// an entirely separate table of templates — and the two disagreed.
///
/// Returns `Ok(null)` when nothing has been imported or created yet. That is an
/// ordinary state, not a failure, so callers can show an empty state.
class ResolveActiveDiet {
  ResolveActiveDiet({
    required DietPlanStore store,
    required DecodeStoredDiet decode,
  }) : _store = store,
       _decode = decode;

  final DietPlanStore _store;
  final DecodeStoredDiet _decode;

  Future<Result<DecodedDietPlan?, NutritionFailure>> call() async {
    final activePlan = await _store.activePlan();
    switch (activePlan) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final plan):
        if (plan == null) return const Ok(null);
        return _decode(plan, isDefault: true);
    }
  }
}
