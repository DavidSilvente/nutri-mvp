import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/menu_photo.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/menu_text_extractor.dart';

/// No-op implementation of [MenuTextExtractor] used for the MVP.
///
/// It always succeeds with an empty list, keeping manual entry as the only
/// input path and deferring OCR/AI integration to a future adapter.
class NoopMenuTextExtractor implements MenuTextExtractor {
  @override
  Future<Result<List<String>, NutritionFailure>> extract(
    MenuPhoto photo,
  ) async {
    return const Ok<List<String>, NutritionFailure>([]);
  }
}
