import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/menu_photo.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

import 'fake_menu_source.dart';

NutritionTarget _target() {
  return NutritionTarget(
    energy: Energy(kcal: 500),
    macros: Macros(proteinG: 35, carbsG: 40, fatG: 20),
  );
}

void main() {
  group('FakeMenuSource', () {
    test('savePhoto persists a photo so it is returned by listPhotos', () async {
      final source = FakeMenuSource();
      final photo = MenuPhoto(
        id: 'photo-1',
        localUri: Uri.parse('file:///data/photos/menu_1.jpg'),
        createdAt: DateTime(2026, 8, 1, 12, 30),
      );

      final saveResult = await source.savePhoto(photo);
      final listResult = await source.listPhotos();

      expect(saveResult, isA<Ok<MenuPhoto, NutritionFailure>>());
      final photos =
          (listResult as Ok<List<MenuPhoto>, NutritionFailure>).value;
      expect(photos, [photo]);
    });

    test('listPhotos orders photos by recency, newest first', () async {
      final source = FakeMenuSource();
      final older = MenuPhoto(
        id: 'older',
        localUri: Uri.parse('file:///data/photos/older.jpg'),
        createdAt: DateTime(2026, 8, 1, 10, 0),
      );
      final newer = MenuPhoto(
        id: 'newer',
        localUri: Uri.parse('file:///data/photos/newer.jpg'),
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
      final source = FakeMenuSource();
      final photo = MenuPhoto(
        id: 'photo-1',
        localUri: Uri.parse('file:///data/photos/menu_1.jpg'),
        createdAt: DateTime(2026, 8, 1, 12, 30),
      );
      final item = MenuItem(
        id: 'item-1',
        photoId: 'photo-1',
        label: 'Grilled Salmon',
        target: _target(),
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
      final source = FakeMenuSource();
      final item = MenuItem(
        id: 'item-1',
        photoId: 'photo-1',
        label: 'Grilled Salmon',
        target: _target(),
      );

      final saveResult = await source.saveItem(item);
      final listResult = await source.listItems('photo-1');

      expect(saveResult, isA<Ok<MenuItem, NutritionFailure>>());
      final items =
          (listResult as Ok<List<MenuItem>, NutritionFailure>).value;
      expect(items, [item]);
    });

    test('listItems does not leak items across photos', () async {
      final source = FakeMenuSource();
      final itemA = MenuItem(
        id: 'item-a',
        photoId: 'photo-a',
        label: 'Salmon',
        target: _target(),
      );
      final itemB = MenuItem(
        id: 'item-b',
        photoId: 'photo-b',
        label: 'Tofu',
        target: _target(),
      );

      await source.saveItem(itemA);
      await source.saveItem(itemB);

      final result = await source.listItems('photo-a');
      final items =
          (result as Ok<List<MenuItem>, NutritionFailure>).value;
      expect(items, [itemA]);
    });

    test('deleteItem removes the item', () async {
      final source = FakeMenuSource();
      final item = MenuItem(
        id: 'item-1',
        photoId: 'photo-1',
        label: 'Grilled Salmon',
        target: _target(),
      );

      await source.saveItem(item);
      final deleteResult = await source.deleteItem('item-1');
      final listResult = await source.listItems('photo-1');

      expect(deleteResult, isA<Ok<void, NutritionFailure>>());
      expect(
        (listResult as Ok<List<MenuItem>, NutritionFailure>).value,
        isEmpty,
      );
    });
  });
}
