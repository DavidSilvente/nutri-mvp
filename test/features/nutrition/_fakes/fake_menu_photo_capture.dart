import 'package:nutri_mvp/features/nutrition/domain/entities/menu_photo.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/menu_photo_capture.dart';

/// In-memory [MenuPhotoCapture] test double.
///
/// Simulates the contract the real image-picker adapter MUST honor: a
/// successful camera/gallery pick returns a [MenuPhoto] with a durable local
/// URI, and a user cancellation returns `null`. No failure variants are used.
class FakeMenuPhotoCapture implements MenuPhotoCapture {
  int _callCount = 0;

  @override
  Future<MenuPhoto?> pick(ImageOrigin origin) async {
    if (origin == ImageOrigin.gallery) return null;
    _callCount++;
    return MenuPhoto(
      id: 'photo-$_callCount',
      localUri: Uri.parse('file:///data/photos/camera_$_callCount.jpg'),
      createdAt: DateTime(2026, 8, 1),
    );
  }
}
