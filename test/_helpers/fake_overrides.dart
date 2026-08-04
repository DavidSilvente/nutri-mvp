import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/food_table_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/bootstrap_diet_library.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';

import '../features/nutrition/_fakes/fake_diet_plan_source.dart';
import '../features/nutrition/_fakes/fake_diet_plan_store.dart';
import '../features/nutrition/_fakes/fake_hydration_source.dart';
import '../features/nutrition/_fakes/fake_nutrition_source.dart';

/// Overrides every port the app shell touches with an in-memory fake, so a
/// widget test never reaches drift, the filesystem, or a bundled asset.
///
/// Kept in one place because [HomeScreen] builds ALL of its destinations inside
/// an `IndexedStack`: a screen the test never opens still resolves its
/// providers, so forgetting one override hangs the test on a spinner rather than
/// failing with a useful message.
///
/// Pass a fake to reuse the same instance the test asserts against; omit it to
/// get a fresh empty one.
List<Override> fakeAppOverrides({
  FakeNutritionSource? nutritionSource,
  FakeHydrationSource? hydrationSource,
  FakeDietPlanSource? dietPlanSource,
  DietPlanStore? dietPlanStore,
  FoodTableSource? foodTable,
  BundledDietDocumentSource? bundledDiet,
  DateTime Function()? clock,
}) {
  return [
    nutritionSourceProvider.overrideWithValue(
      nutritionSource ?? FakeNutritionSource(),
    ),
    hydrationSourceProvider.overrideWithValue(
      hydrationSource ?? FakeHydrationSource(),
    ),
    dietPlanSourceProvider.overrideWithValue(
      dietPlanSource ?? FakeDietPlanSource(),
    ),
    dietPlanStoreProvider.overrideWithValue(
      dietPlanStore ?? FakeDietPlanStore(),
    ),
    foodTableSourceProvider.overrideWithValue(
      foodTable ?? FakeFoodTableSource(),
    ),
    bundledDietDocumentProvider.overrideWithValue(
      bundledDiet ?? FakeBundledDietDocumentSource(),
    ),
    clockProvider.overrideWithValue(
      clock ?? () => DateTime.utc(2026, 8, 1, 12),
    ),
  ];
}
