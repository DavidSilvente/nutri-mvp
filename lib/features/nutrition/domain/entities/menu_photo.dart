import '../value_objects/nutrition_target.dart';

/// A reference to a menu photo stored in app-owned local storage.
///
/// The entity deliberately does not hold OCR text or extracted items; those
/// are modelled separately so the MVP can defer automatic extraction.
class MenuPhoto {
  MenuPhoto({
    required this.id,
    required this.localUri,
    required this.createdAt,
  });

  final String id;
  final Uri localUri;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuPhoto &&
          other.id == id &&
          other.localUri == localUri &&
          other.createdAt == createdAt);

  @override
  int get hashCode => Object.hash(id, localUri, createdAt);

  @override
  String toString() =>
      'MenuPhoto(id: $id, localUri: $localUri, createdAt: $createdAt)';
}

/// A manually-entered menu item, scoped to a [MenuPhoto] and carrying full
/// macros so it can be ranked against a planned meal target.
class MenuItem {
  MenuItem({
    required this.id,
    required this.photoId,
    required this.label,
    required this.target,
  }) {
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
  }

  final String id;
  final String photoId;
  final String label;
  final NutritionTarget target;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuItem &&
          other.id == id &&
          other.photoId == photoId &&
          other.label == label &&
          other.target == target);

  @override
  int get hashCode => Object.hash(id, photoId, label, target);

  @override
  String toString() =>
      'MenuItem(id: $id, photoId: $photoId, label: $label, target: $target)';
}
