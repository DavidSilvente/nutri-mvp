import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_plan_codec.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/asset_bundled_diet_document_source.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/asset_food_table_source.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_decoder.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/food_table_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/apply_template_to_days.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/bootstrap_diet_library.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_diet_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/import_diet_document.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/diet_day_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/diet_plan_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart'
    show nutritionDatabaseProvider;

/// Resolves the [DietPlanSource] port. In production this is
/// [SqlDietPlanSource] over the same on-disk [nutritionDatabaseProvider] used by
/// nutrition and hydration. Tests override this provider with
/// `FakeDietPlanSource` to avoid touching drift entirely.
final dietPlanSourceProvider = Provider<DietPlanSource>((ref) {
  return SqlDietPlanSource(ref.watch(nutritionDatabaseProvider));
});

/// Turns a template into actual planned meals on given days.
final applyTemplateProvider = Provider<ApplyTemplateToDays>((ref) {
  return ApplyTemplateToDays(ref.watch(dietPlanSourceProvider));
});

/// Orchestrates diet templates and planned meals for the planning UI.
final dietPlanControllerProvider =
    AsyncNotifierProvider<DietPlanController, DietPlanState>(
      DietPlanController.new,
    );

// --- Imported diet plans (food-first) ------------------------------------
//
// These sit alongside the hand-entered [dietPlanSourceProvider] above rather
// than replacing it: an imported plan derives its macros from foods, while the
// in-app editor still builds templates by typing targets directly.

/// Resolves the [DietPlanStore] port, over the same on-disk database.
final dietPlanStoreProvider = Provider<DietPlanStore>((ref) {
  return SqlDietPlanStore(ref.watch(nutritionDatabaseProvider));
});

/// The bundle the food table asset is read from.
///
/// Exposed as its own provider so widget tests can serve a small table instead
/// of loading the shipped one.
final assetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

final foodTableSourceProvider = Provider<FoodTableSource>((ref) {
  return AssetFoodTableSource(bundle: ref.watch(assetBundleProvider));
});

final dietPlanDecoderProvider = Provider<DietPlanDecoder>((ref) {
  return const DietPlanCodec();
});

/// Reads what the active diet prescribes for a given day.
final getDietDayProvider = Provider<GetDietDay>((ref) {
  return GetDietDay(
    store: ref.watch(dietPlanStoreProvider),
    foodTable: ref.watch(foodTableSourceProvider),
    decoder: ref.watch(dietPlanDecoderProvider),
  );
});

/// Validates and stores a normalized plan document.
final importDietDocumentProvider = Provider<ImportDietDocument>((ref) {
  return ImportDietDocument(
    store: ref.watch(dietPlanStoreProvider),
    foodTable: ref.watch(foodTableSourceProvider),
    decoder: ref.watch(dietPlanDecoderProvider),
  );
});

/// One day of the active diet, with the swaps recorded for that day applied.
final dietDayControllerProvider =
    AsyncNotifierProvider.family<DietDayController, DietDay?, NutritionDay>(
      DietDayController.new,
    );

/// Every stored diet, active one first — the data behind the diet picker.
final storedDietPlansProvider =
    FutureProvider<List<StoredDietPlan>>((ref) async {
  ref.watch(dietLibraryRevisionProvider);
  final result = await ref.watch(dietPlanStoreProvider).listPlans();
  return switch (result) {
    Ok(value: final plans) => plans,
    Err(failure: final failure) => throw HealthFailureException(failure),
  };
});

/// Bumped whenever the set of stored plans or the active choice changes, so the
/// picker and every day view re-read instead of showing a stale diet.
final dietLibraryRevisionProvider = StateProvider<int>((ref) => 0);

/// The plan document that ships with the build, used to seed the library.
final bundledDietDocumentProvider =
    Provider<BundledDietDocumentSource>((ref) {
  return AssetBundledDietDocumentSource(
    bundle: ref.watch(assetBundleProvider),
  );
});

/// Clock seam, so tests can pin import timestamps.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final bootstrapDietLibraryProvider = Provider<BootstrapDietLibrary>((ref) {
  return BootstrapDietLibrary(
    store: ref.watch(dietPlanStoreProvider),
    import: ref.watch(importDietDocumentProvider),
    bundled: ref.watch(bundledDietDocumentProvider),
    now: ref.watch(clockProvider),
  );
});

/// Runs the first-run seed exactly once per app session.
///
/// Awaited by the diet screens before they read the library, so a fresh install
/// shows the shipped diet instead of an empty state that the user would have to
/// fix by hand.
final dietLibraryBootstrapProvider = FutureProvider<bool>((ref) async {
  final result = await ref.watch(bootstrapDietLibraryProvider).call();
  return switch (result) {
    Ok(value: final seeded) => seeded,
    Err(failure: final failure) => throw HealthFailureException(failure),
  };
});
