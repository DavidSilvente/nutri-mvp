import 'package:nutri_mvp/core/result.dart';

import '../entities/stored_diet_plan.dart';
import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_decoder.dart';
import '../ports/diet_plan_store.dart';
import '../ports/food_table_source.dart';
import '../services/food_catalog.dart';

/// Stores a normalized diet plan document, but only after proving it decodes.
///
/// Validation happens BEFORE the write on purpose. A document that references an
/// unknown food or has the wrong shape would otherwise be persisted and then
/// fail every time the day view tried to read it, leaving the user with a diet
/// they cannot open and no clue why. Failing at import points at the real
/// problem while the user is still in the import flow.
class ImportDietDocument {
  ImportDietDocument({
    required DietPlanStore store,
    required FoodTableSource foodTable,
    required DietPlanDecoder decoder,
  })  : _store = store,
        _foodTable = foodTable,
        _decoder = decoder;

  final DietPlanStore _store;
  final FoodTableSource _foodTable;
  final DietPlanDecoder _decoder;

  /// Validates and stores [document].
  ///
  /// [makeActive] promotes the plan to the user's current diet. The first plan
  /// ever imported becomes active regardless (enforced by the store).
  Future<Result<StoredDietPlan, NutritionFailure>> call({
    required String id,
    required String document,
    required DateTime importedAt,
    String? name,
    String? sourceLabel,
    bool makeActive = false,
  }) async {
    final foods = await _foodTable.loadFoods();
    final FoodCatalog baseCatalog;
    switch (foods) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final items):
        baseCatalog = FoodCatalog(items);
    }

    final decoded = _decoder.decode(
      document,
      baseCatalog: baseCatalog,
      planId: id,
      sourceLabel: sourceLabel,
    );
    switch (decoded) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        return _store.savePlan(StoredDietPlan(
          id: id,
          // The document names itself; an explicit [name] only overrides that
          // when the user retitles the import.
          name: name ?? value.plan.name,
          document: document,
          importedAt: importedAt,
          declaredDailyEnergyKcal: value.plan.declaredDailyEnergyKcal,
          isDefault: makeActive,
          sourceLabel: sourceLabel,
        ));
    }
  }
}
