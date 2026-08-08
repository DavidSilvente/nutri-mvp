import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_nutrition_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/food_item.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/derived_targets.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/food_quantity.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/logged_ingredient.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

NutritionEntry buildEntry({required String id, required DateTime recordedAt}) {
  return NutritionEntry(
    id: id,
    recordedAt: recordedAt,
    energy: Energy(kcal: 500),
    macros: Macros(proteinG: 30, carbsG: 40, fatG: 15),
  );
}

/// A food whose per-100g composition is 200 kcal / 20P / 10C / 5F, used by
/// the composition round-trip tests below.
FoodItem _food(String id) => FoodItem(
  id: id,
  name: 'Food $id',
  preparation: FoodPreparation.raw,
  per100g: NutritionTarget(
    energy: Energy(kcal: 200),
    macros: Macros(proteinG: 20, carbsG: 10, fatG: 5),
  ),
  source: FoodDataSource.usdaSrLegacy,
);

void main() {
  group('SqlNutritionSource', () {
    late NutritionDatabase database;
    late SqlNutritionSource source;

    setUp(() {
      database = NutritionDatabase(NativeDatabase.memory());
      source = SqlNutritionSource(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('round-trips: record then entriesOn returns it', () async {
      final entry = buildEntry(id: 'a', recordedAt: DateTime(2026, 7, 24, 9));

      final recordResult = await source.record(entry);
      final queryResult = await source.entriesOn(
        NutritionDay.fromDateTime(entry.recordedAt),
      );

      expect(recordResult, isA<Ok<void, NutritionFailure>>());
      final entries =
          (queryResult as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, [entry]);
    });

    test('entriesOn filters by day, excluding other days', () async {
      final day1 = buildEntry(id: 'day1', recordedAt: DateTime(2026, 7, 24));
      final day2 = buildEntry(id: 'day2', recordedAt: DateTime(2026, 7, 25));

      await source.record(day1);
      await source.record(day2);

      final result = await source.entriesOn(
        NutritionDay.fromDateTime(day1.recordedAt),
      );

      final entries =
          (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, [day1]);
    });

    test('entriesOn returns an empty list for a day with no entries', () async {
      final result = await source.entriesOn(
        NutritionDay.fromDateTime(DateTime(2026, 1, 1)),
      );

      final entries =
          (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, isEmpty);
    });

    test('data persists across separate SqlNutritionSource instances '
        'sharing the same database (simulates surviving a restart)', () async {
      final entry = buildEntry(
        id: 'restart',
        recordedAt: DateTime(2026, 7, 24, 10),
      );
      await source.record(entry);

      final reopenedSource = SqlNutritionSource(database);
      final result = await reopenedSource.entriesOn(
        NutritionDay.fromDateTime(entry.recordedAt),
      );

      final entries =
          (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
      expect(entries, [entry]);
    });

    test(
      'records a composed entry and rehydrates its ingredients in position '
      'order, including an unresolved foodId',
      () async {
        final catalog = FoodCatalog([_food('chicken_breast'), _food('rice')]);
        final ingredients = [
          LoggedIngredient(
            foodId: 'rice',
            quantity: FoodQuantity(grams: 100, count: 1, unit: 'cup'),
          ),
          LoggedIngredient(
            foodId: 'discontinued_food',
            quantity: FoodQuantity(grams: 50),
          ),
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 150),
          ),
        ];
        final composition = DerivedTargets.compose(ingredients, catalog);
        final entry = NutritionEntry.composed(
          id: 'composed-1',
          recordedAt: DateTime(2026, 8, 1, 12),
          composition: composition,
        );

        await source.record(entry);
        final result = await source.entriesOn(
          NutritionDay.fromDateTime(entry.recordedAt),
        );

        final entries =
            (result as Ok<List<NutritionEntry>, NutritionFailure>).value;
        expect(entries, [entry]);
        // Order matters independently of entity equality: entity `==`
        // already compares ingredients element-wise, so this pins the
        // read path's `ORDER BY position ASC` contract explicitly.
        expect(
          entries.single.ingredients.map((i) => i.foodId).toList(),
          ['rice', 'discontinued_food', 'chicken_breast'],
        );
      },
    );

    test(
      'a legacy entry with zero ingredient rows loads with an empty '
      'ingredient list and its stored flat macros unchanged',
      () async {
        final entry = buildEntry(
          id: 'legacy-1',
          recordedAt: DateTime(2026, 8, 2, 8),
        );

        await source.record(entry);
        final result = await source.entriesOn(
          NutritionDay.fromDateTime(entry.recordedAt),
        );

        final loaded =
            (result as Ok<List<NutritionEntry>, NutritionFailure>)
                .value
                .single;
        expect(loaded.ingredients, isEmpty);
        expect(loaded.energy, entry.energy);
        expect(loaded.macros, entry.macros);
      },
    );

    test(
      'round-trip consistency: the stored flat target matches '
      'DerivedTargets.compose of the stored ingredient rows',
      () async {
        final catalog = FoodCatalog([_food('chicken_breast'), _food('rice')]);
        final ingredients = [
          LoggedIngredient(
            foodId: 'chicken_breast',
            quantity: FoodQuantity(grams: 150),
          ),
          LoggedIngredient(foodId: 'rice', quantity: FoodQuantity(grams: 80)),
        ];
        final entry = NutritionEntry.composed(
          id: 'consistency-1',
          recordedAt: DateTime(2026, 8, 3, 13),
          composition: DerivedTargets.compose(ingredients, catalog),
        );

        await source.record(entry);
        final result = await source.entriesOn(
          NutritionDay.fromDateTime(entry.recordedAt),
        );
        final stored =
            (result as Ok<List<NutritionEntry>, NutritionFailure>)
                .value
                .single;

        final storedFlatTarget = NutritionTarget(
          energy: stored.energy,
          macros: stored.macros,
        );
        final recomposed = DerivedTargets.compose(
          stored.ingredients,
          catalog,
        ).target;
        expect(
          storedFlatTarget.equalsWithinTolerance(recomposed, tolerance: 0.01),
          isTrue,
        );
      },
    );
  });
}
