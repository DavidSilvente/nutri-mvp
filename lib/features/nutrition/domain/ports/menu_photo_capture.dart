import '../../domain/entities/menu_photo.dart';

/// Origin for a menu photo capture request.
enum ImageOrigin { camera, gallery }

/// Domain port for capturing or selecting a menu photo and returning a durable
/// reference to the copied image file.
///
/// A cancellation by the user is represented by `null`, not by a failure.
abstract interface class MenuPhotoCapture {
  /// Returns a [MenuPhoto] with a durable local URI, or `null` if the user
  /// cancels the capture/selection flow.
  Future<MenuPhoto?> pick(ImageOrigin origin);
}
