import 'package:flutter/services.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/bootstrap_diet_library.dart';

/// Serves the diet plan document that ships in the app bundle.
class AssetBundledDietDocumentSource implements BundledDietDocumentSource {
  AssetBundledDietDocumentSource({
    AssetBundle? bundle,
    this.assetKey = defaultAssetKey,
    this.planId = defaultPlanId,
    this.sourceLabel = defaultSourceLabel,
  }) : _bundle = bundle ?? rootBundle;

  static const String defaultAssetKey =
      'assets/diets/nutrium_david_2950kcal.json';
  static const String defaultPlanId = 'bundled-nutrium-2950';
  static const String defaultSourceLabel = 'DAVID GALERA AJUSTE 2950KCAL.pdf';

  final AssetBundle _bundle;
  final String assetKey;

  @override
  final String planId;

  @override
  final String? sourceLabel;

  @override
  Future<Result<String?, NutritionFailure>> loadDocument() async {
    try {
      return Ok(await _bundle.loadString(assetKey));
    } catch (e) {
      // A build without the seed asset is a valid configuration, not a failure:
      // the library simply starts empty and the user imports their own plan.
      return const Ok(null);
    }
  }
}
