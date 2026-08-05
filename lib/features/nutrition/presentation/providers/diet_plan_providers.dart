import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_draft_codec.dart';
import 'package:nutri_mvp/features/nutrition/data/codecs/diet_plan_codec.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/asset_bundled_diet_document_source.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/asset_food_table_source.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/claude_diet_plan_extractor.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/file_picker_pdf_source.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/gemini_diet_plan_extractor.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/printing_pdf_rasterizer.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/stored_diet_plan.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_decoder.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_plan_store.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/food_table_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/meal_slot_directory.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/option_choice_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/pdf_file_picker.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/active_diet_slot_directory.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/extracted_food_resolver.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_catalog.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/food_matcher.dart';
import 'package:nutri_mvp/features/nutrition/domain/services/stored_option_choices.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/apply_diet_to_days.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/bootstrap_diet_library.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_diet_day.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/import_diet_document.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/import_diet_pdf.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/resolve_active_diet.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/save_manual_diet.dart';
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

/// Turns the meals a diet prescribes into actual planned meals on given days.
final applyDietProvider = Provider<ApplyDietToDays>((ref) {
  return ApplyDietToDays(ref.watch(dietPlanSourceProvider));
});

/// Writes planned meals and substitutes for the planning UI.
final dietPlanControllerProvider =
    AsyncNotifierProvider<DietPlanController, void>(DietPlanController.new);

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

/// Writes a hand-authored diet back out as a plan document.
final dietPlanEncoderProvider = Provider<DietPlanEncoder>((ref) {
  return const DietPlanCodec();
});

/// Stores a diet typed into the app, in the same place imported ones live.
final saveManualDietProvider = Provider<SaveManualDiet>((ref) {
  return SaveManualDiet(
    store: ref.watch(dietPlanStoreProvider),
    encoder: ref.watch(dietPlanEncoderProvider),
    now: ref.watch(clockProvider),
  );
});

/// Free-text search over the shipped food table.
///
/// Built once and cached, because indexing the table is the expensive part and
/// the review screen searches on every keystroke. Kept out of the widget so a
/// test can serve a three-food table instead of the shipped one.
final foodMatcherProvider = FutureProvider<FoodMatcher>((ref) async {
  final result = await ref.watch(foodTableSourceProvider).loadFoods();
  return switch (result) {
    Ok(value: final foods) => FoodMatcher(FoodCatalog(foods)),
    Err(failure: final failure) => throw HealthFailureException(failure),
  };
});

/// Decodes any stored plan against the food table.
final decodeStoredDietProvider = Provider<DecodeStoredDiet>((ref) {
  return DecodeStoredDiet(
    foodTable: ref.watch(foodTableSourceProvider),
    decoder: ref.watch(dietPlanDecoderProvider),
  );
});

/// The user's active diet, decoded — the one fact every diet screen reads.
final resolveActiveDietProvider = Provider<ResolveActiveDiet>((ref) {
  return ResolveActiveDiet(
    store: ref.watch(dietPlanStoreProvider),
    decode: ref.watch(decodeStoredDietProvider),
  );
});

/// Names and orders the slots the calendar's planned meals point at.
final mealSlotDirectoryProvider = Provider<MealSlotDirectory>((ref) {
  return ActiveDietSlotDirectory(ref.watch(resolveActiveDietProvider));
});

/// Answers which option is in force for a given day, at day-selection level.
///
/// User-level preferences layer in later without this provider's callers
/// needing to change: the extra data lives inside [StoredOptionChoices].
final optionChoiceSourceProvider = Provider<OptionChoiceSource>((ref) {
  return StoredOptionChoices(ref.watch(dietPlanStoreProvider));
});

/// One stored diet, decoded, addressed by its id.
///
/// What the editor loads. Returns null when the id names nothing, which happens
/// if the diet was deleted from another screen while the editor was open.
final storedDietProvider = FutureProvider.family<DecodedDietPlan?, String>((
  ref,
  id,
) async {
  ref.watch(dietLibraryRevisionProvider);
  final plans = await ref.watch(storedDietPlansProvider.future);
  final plan = plans.where((p) => p.id == id).firstOrNull;
  if (plan == null) return null;

  final decoded = await ref.watch(decodeStoredDietProvider)(
    plan,
    isDefault: plan.isDefault,
  );
  return switch (decoded) {
    Ok(value: final value) => value,
    Err(failure: final failure) => throw HealthFailureException(failure),
  };
});

/// Reads what the active diet prescribes for a given day.
final getDietDayProvider = Provider<GetDietDay>((ref) {
  return GetDietDay(
    store: ref.watch(dietPlanStoreProvider),
    activeDiet: ref.watch(resolveActiveDietProvider),
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

// --- Reading a new diet PDF ------------------------------------------------

/// Renders a PDF's pages, so a plan with no text layer can still be read.
final pdfRasterizerProvider = Provider<PdfPageRasterizer>((ref) {
  return PrintingPdfRasterizer();
});

/// Turns rendered pages into a draft plan document.
///
/// Gemini wins when both keys are present: reading a plan is transcription
/// rather than reasoning, so the free tier does the job, and both adapters are
/// held to the same brief (`dietExtractionPrompt`). Build with
/// `--dart-define=GEMINI_API_KEY=...` or `--dart-define=ANTHROPIC_API_KEY=...`.
final dietPlanExtractorProvider = Provider<DietPlanExtractor>((ref) {
  if (GeminiDietPlanExtractor.isConfigured) {
    return GeminiDietPlanExtractor(
      apiKey: GeminiDietPlanExtractor.apiKeyFromEnvironment,
    );
  }
  return ClaudeDietPlanExtractor(
    apiKey: ClaudeDietPlanExtractor.apiKeyFromEnvironment,
  );
});

/// Whether this build can read a new PDF at all.
///
/// Exposed so the UI can hide the entry point instead of offering an import
/// that would fail on the first request: the keys are supplied at build time
/// and are absent from a plain `flutter run`.
final canImportDietPdfProvider = Provider<bool>((ref) {
  return GeminiDietPlanExtractor.isConfigured ||
      ClaudeDietPlanExtractor.isConfigured;
});

final dietDraftCodecProvider = Provider<DietPlanDraftCodec>((ref) {
  return const DietDraftCodec();
});

final pdfFilePickerProvider = Provider<PdfFilePicker>((ref) {
  return const FilePickerPdfSource();
});

/// Matches the foods a plan describes against the shipped table.
final extractedFoodResolverProvider = FutureProvider<ExtractedFoodResolver>((
  ref,
) async {
  return ExtractedFoodResolver(await ref.watch(foodMatcherProvider.future));
});

/// Reads a diet PDF in two phases, with the user's review in between.
///
/// Async because resolution needs the indexed food table, which is loaded from
/// an asset — the same cached index the review screen's search uses.
final importDietPdfProvider = FutureProvider<DietPdfImporter>((ref) async {
  return ImportDietPdf(
    rasterizer: ref.watch(pdfRasterizerProvider),
    extractor: ref.watch(dietPlanExtractorProvider),
    draftCodec: ref.watch(dietDraftCodecProvider),
    resolver: await ref.watch(extractedFoodResolverProvider.future),
    importDocument: ref.watch(importDietDocumentProvider),
    now: ref.watch(clockProvider),
    newPlanId: ref.watch(planIdFactoryProvider),
  );
});

/// Ids for newly imported plans.
///
/// A seam rather than a call to the clock inside the use case, so a test can
/// pin the id of the plan it just imported.
final planIdFactoryProvider = Provider<String Function()>((ref) {
  final now = ref.watch(clockProvider);
  return () => 'imported-${now().microsecondsSinceEpoch}';
});

/// One day of the active diet, with the swaps recorded for that day applied.
final dietDayControllerProvider =
    AsyncNotifierProvider.family<DietDayController, DietDay?, NutritionDay>(
      DietDayController.new,
    );

/// Every stored diet, active one first — the data behind the diet picker.
final storedDietPlansProvider = FutureProvider<List<StoredDietPlan>>((
  ref,
) async {
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
final bundledDietDocumentProvider = Provider<BundledDietDocumentSource>((ref) {
  return AssetBundledDietDocumentSource(bundle: ref.watch(assetBundleProvider));
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
