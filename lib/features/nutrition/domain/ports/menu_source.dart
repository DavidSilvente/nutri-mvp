import 'package:nutri_mvp/core/result.dart';

import '../../domain/entities/menu_photo.dart';
import '../../domain/failures/nutrition_failure.dart';

/// Domain port for reading and writing menu photo metadata and the manually
/// entered items associated with a stored photo.
///
/// This port is intentionally limited to metadata persistence; the actual
/// image file copy is handled by [MenuPhotoCapture] before the photo is passed
/// here.
abstract interface class MenuSource {
  /// Returns all stored menu photos, ordered by recency.
  Future<Result<List<MenuPhoto>, NutritionFailure>> listPhotos();

  /// Persists [photo] metadata.
  Future<Result<MenuPhoto, NutritionFailure>> savePhoto(MenuPhoto photo);

  /// Deletes the photo identified by [id] and its associated items.
  Future<Result<void, NutritionFailure>> deletePhoto(String id);

  /// Returns all manually entered items for the photo identified by [photoId].
  Future<Result<List<MenuItem>, NutritionFailure>> listItems(String photoId);

  /// Persists [item] scoped to its [photoId].
  Future<Result<MenuItem, NutritionFailure>> saveItem(MenuItem item);

  /// Deletes the item identified by [id].
  Future<Result<void, NutritionFailure>> deleteItem(String id);
}
