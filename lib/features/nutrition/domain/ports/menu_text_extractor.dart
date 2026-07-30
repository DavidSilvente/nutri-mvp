import 'package:nutri_mvp/core/result.dart';

import '../../domain/entities/menu_photo.dart';
import '../../domain/failures/nutrition_failure.dart';

/// Domain port for extracting text labels from a menu photo.
///
/// The MVP uses a no-op implementation that returns an empty list. A future
/// OCR/AI adapter can replace the registered implementation without changing
/// domain or UI contracts.
abstract interface class MenuTextExtractor {
  /// Extracts a list of candidate text labels from [photo].
  Future<Result<List<String>, NutritionFailure>> extract(MenuPhoto photo);
}
