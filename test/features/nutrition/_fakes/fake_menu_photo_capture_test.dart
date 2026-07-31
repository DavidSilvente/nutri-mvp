import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/menu_photo_capture.dart';

import 'fake_menu_photo_capture.dart';

void main() {
  group('FakeMenuPhotoCapture', () {
    test('pick returns a durable photo reference for camera', () async {
      final capture = FakeMenuPhotoCapture();

      final photo = await capture.pick(ImageOrigin.camera);

      expect(photo, isNotNull);
      expect(photo!.localUri.scheme, 'file');
      expect(photo.localUri.path, contains('camera'));
    });

    test('pick returns null for gallery, simulating cancellation', () async {
      final capture = FakeMenuPhotoCapture();

      final photo = await capture.pick(ImageOrigin.gallery);

      expect(photo, isNull);
    });

    test('pick returns distinct references for distinct calls', () async {
      final capture = FakeMenuPhotoCapture();

      final first = await capture.pick(ImageOrigin.camera);
      final second = await capture.pick(ImageOrigin.camera);

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.id, isNot(second!.id));
    });
  });
}
