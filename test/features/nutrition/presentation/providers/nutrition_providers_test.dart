import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_nutrition_source.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart';

/// Verifies the default (non-overridden) [nutritionSourceProvider] wiring:
/// both iOS and Android must resolve the manual `SqlNutritionSource`
/// adapter exclusively, since v1 has no platform branching. Reading the
/// provider does NOT trigger the underlying [LazyDatabase] to open (it only
/// opens lazily on the first query against it), so this is safe to assert
/// without a device or a `path_provider` plugin mock.
void main() {
  group('nutritionSourceProvider', () {
    test('resolves to SqlNutritionSource by default (no overrides)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(nutritionSourceProvider),
        isA<SqlNutritionSource>(),
      );
    });
  });
}
