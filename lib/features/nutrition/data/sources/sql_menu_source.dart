import 'package:drift/drift.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/menu_photo.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/menu_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

/// Production [MenuSource] adapter backed by local `drift` (SQLite)
/// storage. Menu photo metadata and manually entered items persist on disk
/// and survive app restarts.
///
/// `drift` types (rows, tables, the generated database class) are CONFINED
/// to this file and [NutritionDatabase] — nothing here leaks into the
/// domain. This adapter NEVER produces [PermissionDenied]: that failure is
/// exclusive to platform-backed sources.
class SqlMenuSource implements MenuSource {
  SqlMenuSource(this._db);

  final NutritionDatabase _db;

  @override
  Future<Result<List<MenuPhoto>, NutritionFailure>> listPhotos() async {
    try {
      final rows = await (_db.select(_db.menuPhotos)
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .get();
      return Ok(rows.map(_toPhoto).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuPhoto, NutritionFailure>> savePhoto(MenuPhoto photo) async {
    try {
      await _db
          .into(_db.menuPhotos)
          .insert(_toPhotoCompanion(photo), mode: InsertMode.insertOrReplace);
      return Ok(photo);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> deletePhoto(String id) async {
    try {
      await (_db.delete(_db.menuPhotos)..where((row) => row.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<MenuItem>, NutritionFailure>> listItems(
    String photoId,
  ) async {
    try {
      final rows = await (_db.select(_db.menuItems)
            ..where((row) => row.photoId.equals(photoId)))
          .get();
      return Ok(rows.map(_toItem).toList(growable: false));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuItem, NutritionFailure>> saveItem(MenuItem item) async {
    try {
      await _db
          .into(_db.menuItems)
          .insert(_toItemCompanion(item), mode: InsertMode.insertOrReplace);
      return Ok(item);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, NutritionFailure>> deleteItem(String id) async {
    try {
      await (_db.delete(_db.menuItems)..where((row) => row.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  MenuPhotosCompanion _toPhotoCompanion(MenuPhoto photo) {
    return MenuPhotosCompanion.insert(
      id: photo.id,
      localUri: photo.localUri.toString(),
      createdAt: photo.createdAt,
    );
  }

  MenuPhoto _toPhoto(MenuPhotoRow row) {
    return MenuPhoto(
      id: row.id,
      localUri: Uri.parse(row.localUri),
      createdAt: row.createdAt,
    );
  }

  MenuItemsCompanion _toItemCompanion(MenuItem item) {
    final target = _targetValues(item.target);
    return MenuItemsCompanion.insert(
      id: item.id,
      photoId: item.photoId,
      label: item.label,
      energyKcal: target.energyKcal,
      proteinG: target.proteinG,
      carbsG: target.carbsG,
      fatG: target.fatG,
    );
  }

  MenuItem _toItem(MenuItemRow row) {
    return MenuItem(
      id: row.id,
      photoId: row.photoId,
      label: row.label,
      target: _toTarget(
        energyKcal: row.energyKcal,
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
      ),
    );
  }

  NutritionTarget _toTarget({
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) {
    return NutritionTarget(
      energy: Energy(kcal: energyKcal),
      macros: Macros(
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
      ),
    );
  }

  ({double energyKcal, double proteinG, double carbsG, double fatG})
      _targetValues(NutritionTarget target) {
    return (
      energyKcal: target.energy.kcal.toDouble(),
      proteinG: target.macros.proteinG.toDouble(),
      carbsG: target.macros.carbsG.toDouble(),
      fatG: target.macros.fatG.toDouble(),
    );
  }
}
