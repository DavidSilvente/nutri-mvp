import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/menu_photo.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/menu_source.dart';

/// In-memory [MenuSource] test double.
///
/// Mirrors the contract the real SQL adapter MUST honor: photos are ordered by
/// recency, items are scoped to a photo, and deleting a photo removes its
/// items. This fake NEVER produces [PermissionDenied]: that failure is
/// exclusive to platform-backed sources.
class FakeMenuSource implements MenuSource {
  final Map<String, MenuPhoto> _photos = {};
  final Map<String, MenuItem> _items = {};

  @override
  Future<Result<List<MenuPhoto>, NutritionFailure>> listPhotos() async {
    final values = _photos.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Ok(values);
  }

  @override
  Future<Result<MenuPhoto, NutritionFailure>> savePhoto(MenuPhoto photo) async {
    _photos[photo.id] = photo;
    return Ok(photo);
  }

  @override
  Future<Result<void, NutritionFailure>> deletePhoto(String id) async {
    _photos.remove(id);
    _items.removeWhere((_, item) => item.photoId == id);
    return const Ok(null);
  }

  @override
  Future<Result<List<MenuItem>, NutritionFailure>> listItems(
    String photoId,
  ) async {
    final matches = _items.values
        .where((item) => item.photoId == photoId)
        .toList(growable: false);
    return Ok(matches);
  }

  @override
  Future<Result<MenuItem, NutritionFailure>> saveItem(MenuItem item) async {
    _items[item.id] = item;
    return Ok(item);
  }

  @override
  Future<Result<void, NutritionFailure>> deleteItem(String id) async {
    _items.remove(id);
    return const Ok(null);
  }
}
