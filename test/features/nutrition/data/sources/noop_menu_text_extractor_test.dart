import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/noop_menu_text_extractor.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/menu_photo.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';

void main() {
  group('NoopMenuTextExtractor', () {
    final photo = MenuPhoto(
      id: 'photo-1',
      localUri: Uri.parse('file:///data/photos/menu_1.jpg'),
      createdAt: DateTime(2026, 8, 1),
    );

    test('extract returns an empty success result', () async {
      final extractor = NoopMenuTextExtractor();

      final result = await extractor.extract(photo);

      expect(result, const Ok<List<String>, NutritionFailure>([]));
    });

    test('extract does not depend on photo content', () async {
      final extractor = NoopMenuTextExtractor();
      final otherPhoto = MenuPhoto(
        id: 'photo-2',
        localUri: Uri.parse('file:///data/photos/menu_2.jpg'),
        createdAt: DateTime(2026, 8, 2),
      );

      final first = await extractor.extract(photo);
      final second = await extractor.extract(otherPhoto);

      expect(first, second);
      expect(first, const Ok<List<String>, NutritionFailure>([]));
    });
  });
}
