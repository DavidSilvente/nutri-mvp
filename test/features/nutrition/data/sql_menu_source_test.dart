import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_menu_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/menu_photo.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

NutritionTarget _target({
  double kcal = 500,
  double proteinG = 35,
  double carbsG = 40,
  double fatG = 20,
}) {
  return NutritionTarget(
    energy: Energy(kcal: kcal),
    macros: Macros(proteinG: proteinG, carbsG: carbsG, fatG: fatG),
  );
}

MenuPhoto _photo({
  required String id,
  required String path,
  required DateTime createdAt,
}) {
  return MenuPhoto(
    id: id,
    localUri: Uri.parse(path),
    createdAt: createdAt,
  );
}

MenuItem _item({
  required String id,
  required String photoId,
  required String label,
  NutritionTarget? target,
}) {
  return MenuItem(
    id: id,
    photoId: photoId,
    label: label,
    target: target ?? _target(),
  );
}

void main() {
  group('SqlMenuSource', () {
    late NutritionDatabase database;
    late SqlMenuSource source;

    setUp(() {
      database = NutritionDatabase(NativeDatabase.memory());
      source = SqlMenuSource(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('savePhoto persists a photo so it is returned by listPhotos', () async {
      final photo = _photo(
        id: 'photo-1',
        path: 'file:///data/photos/menu_1.jpg',
        createdAt: DateTime(2026, 8, 1, 12, 30),
      );

      final saveResult = await source.savePhoto(photo);
      final listResult = await source.listPhotos();

      expect(saveResult, isA<Ok<MenuPhoto, NutritionFailure>>());
      expect((saveResult as Ok<MenuPhoto, NutritionFailure>).value, photo);
      final photos =
          (listResult as Ok<List<MenuPhoto>, NutritionFailure>).value;
      expect(photos, [photo]);
    });

    test('listPhotos orders photos by recency, newest first', () async {
      final older = _photo(
        id: 'older',
        path: 'file:///data/photos/older.jpg',
        createdAt: DateTime(2026, 8, 1, 10, 0),
      );
      final newer = _photo(
        id: 'newer',
        path: 'file:///data/photos/newer.jpg',
        createdAt: DateTime(2026, 8, 1, 14, 0),
      );

      await source.savePhoto(older);
      await source.savePhoto(newer);

      final result = await source.listPhotos();
      final photos =
          (result as Ok<List<MenuPhoto>, NutritionFailure>).value;
      expect(photos, [newer, older]);
    });

    test('deletePhoto removes the photo and its items', () async {
      final photo = _photo(
        id: 'photo-1',
        path: 'file:///data/photos/menu_1.jpg',
        createdAt: DateTime(2026, 8, 1, 12, 30),
      );
      final item = _item(
        id: 'item-1',
        photoId: 'photo-1',
        label: 'Grilled Salmon',
        target: _target(kcal: 450, proteinG: 40, carbsG: 30, fatG: 15),
      );

      await source.savePhoto(photo);
      await source.saveItem(item);
      final deleteResult = await source.deletePhoto('photo-1');
      final photosResult = await source.listPhotos();
      final itemsResult = await source.listItems('photo-1');

      expect(deleteResult, isA<Ok<void, NutritionFailure>>());
      expect(
        (photosResult as Ok<List<MenuPhoto>, NutritionFailure>).value,
        isEmpty,
      );
      expect(
        (itemsResult as Ok<List<MenuItem>, NutritionFailure>).value,
        isEmpty,
      );
    });

    test('saveItem persists an item scoped to its photo', () async {
      final photo = _photo(
        id: 'photo-1',
        path: 'file:///data/photos/menu_1.jpg',
        createdAt: DateTime(2026, 8, 1, 12, 30),
      );
      final item = _item(
        id: 'item-1',
        photoId: 'photo-1',
        label: 'Grilled Salmon',
        target: _target(kcal: 450, proteinG: 40, carbsG: 30, fatG: 15),
      );

      await source.savePhoto(photo);
      final saveResult = await source.saveItem(item);
      final listResult = await source.listItems('photo-1');

      expect(saveResult, isA<Ok<MenuItem, NutritionFailure>>());
      final items =
          (listResult as Ok<List<MenuItem>, NutritionFailure>).value;
      expect(items, [item]);
    });

    test('listItems does not leak items across photos', () async {
      final photoA = _photo(
        id: 'photo-a',
        path: 'file:///data/photos/a.jpg',
        createdAt: DateTime(2026, 8, 1, 10, 0),
      );
      final photoB = _photo(
        id: 'photo-b',
        path: 'file:///data/photos/b.jpg',
        createdAt: DateTime(2026, 8, 1, 11, 0),
      );
      final itemA = _item(
        id: 'item-a',
        photoId: 'photo-a',
        label: 'Salmon',
        target: _target(kcal: 400, proteinG: 35, carbsG: 25, fatG: 12),
      );
      final itemB = _item(
        id: 'item-b',
        photoId: 'photo-b',
        label: 'Tofu',
        target: _target(kcal: 300, proteinG: 25, carbsG: 20, fatG: 10),
      );

      await source.savePhoto(photoA);
      await source.savePhoto(photoB);
      await source.saveItem(itemA);
      await source.saveItem(itemB);

      final result = await source.listItems('photo-a');
      final items =
          (result as Ok<List<MenuItem>, NutritionFailure>).value;
      expect(items, [itemA]);
    });

    test('deleteItem removes the item', () async {
      final photo = _photo(
        id: 'photo-1',
        path: 'file:///data/photos/menu_1.jpg',
        createdAt: DateTime(2026, 8, 1, 12, 30),
      );
      final item = _item(
        id: 'item-1',
        photoId: 'photo-1',
        label: 'Grilled Salmon',
        target: _target(kcal: 450, proteinG: 40, carbsG: 30, fatG: 15),
      );

      final savePhotoResult = await source.savePhoto(photo);
      expect(savePhotoResult, isA<Ok<MenuPhoto, NutritionFailure>>());
      expect(
        (savePhotoResult as Ok<MenuPhoto, NutritionFailure>).value,
        photo,
      );

      final saveItemResult = await source.saveItem(item);
      expect(saveItemResult, isA<Ok<MenuItem, NutritionFailure>>());
      expect((saveItemResult as Ok<MenuItem, NutritionFailure>).value, item);

      final listBefore = await source.listItems('photo-1');
      expect(
        (listBefore as Ok<List<MenuItem>, NutritionFailure>).value,
        [item],
      );

      final deleteResult = await source.deleteItem('item-1');
      final listAfter = await source.listItems('photo-1');

      expect(deleteResult, isA<Ok<void, NutritionFailure>>());
      expect(
        (listAfter as Ok<List<MenuItem>, NutritionFailure>).value,
        isEmpty,
      );
    });

    test('listPhotos returns an empty list when no photos exist', () async {
      final result = await source.listPhotos();
      final photos =
          (result as Ok<List<MenuPhoto>, NutritionFailure>).value;
      expect(photos, isEmpty);
    });

    test('listItems returns an empty list when no items exist for a photo',
        () async {
      final result = await source.listItems('photo-a');
      final items =
          (result as Ok<List<MenuItem>, NutritionFailure>).value;
      expect(items, isEmpty);
    });

    test('data persists across separate SqlMenuSource instances '
        'sharing the same database', () async {
      final photo = _photo(
        id: 'photo-1',
        path: 'file:///data/photos/menu_1.jpg',
        createdAt: DateTime(2026, 8, 1, 12, 30),
      );
      await source.savePhoto(photo);

      final reopenedSource = SqlMenuSource(database);
      final listResult = await reopenedSource.listPhotos();
      final photos =
          (listResult as Ok<List<MenuPhoto>, NutritionFailure>).value;
      expect(photos, [photo]);
    });
  });
}
