import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/menu_photo.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/energy.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/macros.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_target.dart';

void main() {
  group('MenuPhoto', () {
    final createdAt = DateTime(2026, 8, 1, 12, 30);

    test('builds a photo reference with an id, uri and timestamp', () {
      final photo = MenuPhoto(
        id: 'photo-1',
        localUri: Uri.parse('file:///data/photos/menu_1.jpg'),
        createdAt: createdAt,
      );

      expect(photo.id, 'photo-1');
      expect(photo.localUri, Uri.parse('file:///data/photos/menu_1.jpg'));
      expect(photo.createdAt, createdAt);
    });

    test('two photos with the same fields are equal', () {
      final a = MenuPhoto(
        id: 'photo-1',
        localUri: Uri.parse('file:///data/photos/menu_1.jpg'),
        createdAt: createdAt,
      );
      final b = MenuPhoto(
        id: 'photo-1',
        localUri: Uri.parse('file:///data/photos/menu_1.jpg'),
        createdAt: createdAt,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

  });

  group('MenuItem', () {
    final target = NutritionTarget(
      energy: Energy(kcal: 500),
      macros: Macros(proteinG: 35, carbsG: 40, fatG: 20),
    );

    test('builds a menu item scoped to a photo with full macros', () {
      final item = MenuItem(
        id: 'item-1',
        photoId: 'photo-1',
        label: 'Grilled Salmon (300g)',
        target: target,
      );

      expect(item.id, 'item-1');
      expect(item.photoId, 'photo-1');
      expect(item.label, 'Grilled Salmon (300g)');
      expect(item.target, target);
    });

    test('rejects an empty label', () {
      expect(
        () => MenuItem(
          id: 'item-1',
          photoId: 'photo-1',
          label: '',
          target: target,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('two items with the same fields are equal', () {
      final a = MenuItem(
        id: 'item-1',
        photoId: 'photo-1',
        label: 'Grilled Salmon (300g)',
        target: target,
      );
      final b = MenuItem(
        id: 'item-1',
        photoId: 'photo-1',
        label: 'Grilled Salmon (300g)',
        target: target,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

  });
}
