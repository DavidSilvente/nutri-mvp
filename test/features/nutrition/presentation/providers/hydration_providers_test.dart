import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_hydration_source.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/hydration_providers.dart';

/// Verifies the default (non-overridden) [hydrationSourceProvider] wiring:
/// it MUST resolve `SqlHydrationSource` exclusively (no platform branching
/// in v1). Reading the provider does NOT trigger the underlying
/// [LazyDatabase] to open (it only opens lazily on the first query against
/// it), so this is safe to assert without a device or a `path_provider`
/// plugin mock.
void main() {
  group('hydrationSourceProvider', () {
    test('resolves to SqlHydrationSource by default (no overrides)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(hydrationSourceProvider),
        isA<SqlHydrationSource>(),
      );
    });
  });
}
