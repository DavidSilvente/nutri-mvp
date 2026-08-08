import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/food_table_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/bootstrap_diet_library.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// In-memory [DietPlanStore] for widget and use-case tests.
///
/// Mirrors the SQL adapter's contract, including the parts that are easy to get
/// wrong: at most one active plan, the first stored plan becoming active, and
/// promoting a successor when the active plan is deleted.
class FakeDietPlanStore implements DietPlanStore {
  final List<StoredDietPlan> _plans = [];
  final Map<int, Map<String, String>> _selections = {};
  final Map<String, String> _preferences = {};

  /// Fails every call with this failure when set, so error paths are testable.
  NutritionFailure? failWith;

  @override
  Future<Result<List<StoredDietPlan>, NutritionFailure>> listPlans() async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    final sorted = _plans.toList()
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return b.importedAt.compareTo(a.importedAt);
      });
    return Ok(sorted);
  }

  @override
  Future<Result<StoredDietPlan?, NutritionFailure>> activePlan() async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    for (final plan in _plans) {
      if (plan.isDefault) return Ok(plan);
    }
    return const Ok(null);
  }

  @override
  Future<Result<StoredDietPlan, NutritionFailure>> savePlan(
    StoredDietPlan plan,
  ) async {
    final failure = failWith;
    if (failure != null) return Err(failure);

    final clashIndex = _plans.indexWhere(
      (p) => p.name == plan.name && p.id != plan.id,
    );
    if (clashIndex != -1) {
      return Err(
        ConflictFailure('Diet plan name "${plan.name}" already exists'),
      );
    }

    final existingIndex = _plans.indexWhere((p) => p.id == plan.id);
    final isFirstPlan =
        _plans.isEmpty || (_plans.length == 1 && existingIndex != -1);
    final shouldBeActive = plan.isDefault || isFirstPlan;

    if (shouldBeActive) {
      for (var i = 0; i < _plans.length; i++) {
        if (_plans[i].id != plan.id && _plans[i].isDefault) {
          _plans[i] = _plans[i].copyWith(isDefault: false);
        }
      }
    }

    final stored = plan.copyWith(isDefault: shouldBeActive);
    if (existingIndex == -1) {
      _plans.add(stored);
    } else {
      _plans[existingIndex] = stored;
    }
    return Ok(stored);
  }

  @override
  Future<Result<void, NutritionFailure>> setActivePlan(String id) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    if (!_plans.any((plan) => plan.id == id)) {
      return Err(StorageFailure('No diet plan with id "$id"'));
    }
    for (var i = 0; i < _plans.length; i++) {
      _plans[i] = _plans[i].copyWith(isDefault: _plans[i].id == id);
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, NutritionFailure>> deletePlan(String id) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index == -1) return const Ok(null);

    final wasActive = _plans[index].isDefault;
    _plans.removeAt(index);

    if (wasActive && _plans.isNotEmpty) {
      var newest = 0;
      for (var i = 1; i < _plans.length; i++) {
        if (_plans[i].importedAt.isAfter(_plans[newest].importedAt)) newest = i;
      }
      _plans[newest] = _plans[newest].copyWith(isDefault: true);
    }
    return const Ok(null);
  }

  @override
  Future<Result<Map<String, String>, NutritionFailure>> selectionsFor(
    NutritionDay day,
  ) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(Map.of(_selections[day.epochDay] ?? const {}));
  }

  @override
  Future<Result<void, NutritionFailure>> selectOption({
    required NutritionDay day,
    required String componentId,
    required String optionId,
  }) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    (_selections[day.epochDay] ??= {})[componentId] = optionId;
    return const Ok(null);
  }

  @override
  Future<Result<void, NutritionFailure>> clearSelection({
    required NutritionDay day,
    required String componentId,
  }) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    _selections[day.epochDay]?.remove(componentId);
    return const Ok(null);
  }

  @override
  Future<Result<Map<String, String>, NutritionFailure>>
  preferredOptions() async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(Map.of(_preferences));
  }

  @override
  Future<Result<void, NutritionFailure>> setPreferredOption({
    required String componentId,
    required String optionId,
  }) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    _preferences[componentId] = optionId;
    return const Ok(null);
  }

  @override
  Future<Result<void, NutritionFailure>> clearPreferredOption(
    String componentId,
  ) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    _preferences.remove(componentId);
    return const Ok(null);
  }
}

/// A [FoodTableSource] serving a handful of foods, so tests do not load the
/// shipped USDA asset.
class FakeFoodTableSource implements FoodTableSource {
  FakeFoodTableSource({List<FoodItem>? foods})
    : foods = foods ?? defaultFoods();

  final List<FoodItem> foods;

  NutritionFailure? failWith;

  static FoodItem food(
    String id, {
    String? name,
    num kcal = 100,
    num proteinG = 10,
    num carbsG = 10,
    num fatG = 2,
    FoodDataSource source = FoodDataSource.usdaSrLegacy,
    FoodPreparation preparation = FoodPreparation.raw,
  }) {
    return FoodItem(
      id: id,
      name: name ?? id,
      preparation: preparation,
      per100g: NutritionTarget(
        energy: Energy(kcal: kcal),
        macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
      ),
      source: source,
      sourceRef: source == FoodDataSource.usdaSrLegacy ? '000000' : null,
    );
  }

  static List<FoodItem> defaultFoods() => [
    food(
      'chicken_breast_grilled',
      name: 'Pollo, pechuga',
      kcal: 151,
      proteinG: 30.5,
      carbsG: 0,
      fatG: 3.2,
    ),
    food(
      'rice_white_raw',
      name: 'Arroz blanco',
      kcal: 365,
      proteinG: 7.1,
      carbsG: 80,
      fatG: 0.7,
    ),
    food(
      'beef_loin',
      name: 'Ternera, lomo',
      kcal: 138,
      proteinG: 22.9,
      carbsG: 0,
      fatG: 5.2,
    ),
    food(
      'ham_serrano',
      name: 'Jamón serrano',
      kcal: 241,
      proteinG: 31,
      carbsG: 0.3,
      fatG: 13,
      source: FoodDataSource.estimated,
    ),
  ];

  @override
  Future<Result<List<FoodItem>, NutritionFailure>> loadFoods() async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(foods);
  }
}

/// A [BundledDietDocumentSource] that ships nothing, so tests start with an
/// empty library unless they seed one themselves.
class FakeBundledDietDocumentSource implements BundledDietDocumentSource {
  FakeBundledDietDocumentSource({
    this.document,
    this.planId = 'fake-bundled',
    this.sourceLabel,
  });

  String? document;

  @override
  final String planId;

  @override
  final String? sourceLabel;

  @override
  Future<Result<String?, NutritionFailure>> loadDocument() async =>
      Ok(document);
}
