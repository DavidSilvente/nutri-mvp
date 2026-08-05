import '../entities/food_item.dart';

/// An in-memory lookup of every [FoodItem] the app knows about.
///
/// Kept as a domain service rather than a port because resolving a food id to
/// its composition is a pure lookup with no I/O: the loading of the table is
/// what varies (bundled asset, imported plan recipes), not the lookup itself.
class FoodCatalog {
  FoodCatalog(Iterable<FoodItem> foods)
    : _byId = {for (final food in foods) food.id: food} {
    if (_byId.length != foods.length) {
      final seen = <String>{};
      final duplicates = <String>{};
      for (final food in foods) {
        if (!seen.add(food.id)) duplicates.add(food.id);
      }
      throw ArgumentError.value(
        duplicates.toList()..sort(),
        'foods',
        'food ids must be unique',
      );
    }
  }

  final Map<String, FoodItem> _byId;

  /// The food registered under [id], or null when unknown.
  FoodItem? byId(String id) => _byId[id];

  /// Every known food, ordered by id for stable output.
  List<FoodItem> get all =>
      _byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));

  int get length => _byId.length;

  /// Returns the ids in [ids] that this catalog cannot resolve.
  ///
  /// Exists so an import can report every unresolved food at once instead of
  /// failing on the first one.
  Set<String> missingFrom(Iterable<String> ids) =>
      ids.where((id) => !_byId.containsKey(id)).toSet();

  /// Returns a catalog containing this catalog's foods plus [extra].
  ///
  /// Foods in [extra] override same-id entries, which is what lets a plan's own
  /// recipes take precedence over generic table entries for that plan.
  FoodCatalog withOverrides(Iterable<FoodItem> extra) {
    final merged = Map<String, FoodItem>.from(_byId);
    for (final food in extra) {
      merged[food.id] = food;
    }
    return FoodCatalog(merged.values);
  }
}
