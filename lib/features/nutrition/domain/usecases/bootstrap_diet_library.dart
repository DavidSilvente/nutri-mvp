import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';
import '../ports/diet_plan_store.dart';
import 'import_diet_document.dart';

/// Loads a plan document that ships with the app.
///
/// A port so the domain does not care whether the bytes come from an asset
/// bundle, a file, or a test string.
abstract interface class BundledDietDocumentSource {
  /// The document to seed the library with, or null when the build ships none.
  Future<Result<String?, NutritionFailure>> loadDocument();

  /// Stable id for the seeded plan, so repeated runs update rather than
  /// duplicate it.
  String get planId;

  /// Human-readable origin, e.g. the original PDF file name.
  String? get sourceLabel;
}

/// Seeds the diet library on first run, so the app opens with the user's real
/// diet instead of an empty screen.
///
/// Only acts when the library is EMPTY. Once the user owns diets, re-seeding
/// would resurrect a plan they deleted or quietly change which one is active, so
/// a non-empty library is left strictly alone.
class BootstrapDietLibrary {
  BootstrapDietLibrary({
    required DietPlanStore store,
    required ImportDietDocument import,
    required BundledDietDocumentSource bundled,
    required DateTime Function() now,
  })  : _store = store,
        _import = import,
        _bundled = bundled,
        _now = now;

  final DietPlanStore _store;
  final ImportDietDocument _import;
  final BundledDietDocumentSource _bundled;
  final DateTime Function() _now;

  /// Returns true when a plan was seeded, false when nothing needed doing.
  Future<Result<bool, NutritionFailure>> call() async {
    final existing = await _store.listPlans();
    switch (existing) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final plans):
        if (plans.isNotEmpty) return const Ok(false);
    }

    final document = await _bundled.loadDocument();
    final String? source;
    switch (document) {
      case Err(failure: final failure):
        return Err(failure);
      case Ok(value: final value):
        source = value;
    }
    if (source == null) return const Ok(false);

    final imported = await _import(
      id: _bundled.planId,
      document: source,
      importedAt: _now(),
      sourceLabel: _bundled.sourceLabel,
      makeActive: true,
    );
    return switch (imported) {
      Ok() => const Ok(true),
      Err(failure: final failure) => Err(failure),
    };
  }
}
