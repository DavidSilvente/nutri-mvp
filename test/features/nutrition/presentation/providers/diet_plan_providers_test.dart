import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_diet_plan_source.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/diet_plan_providers.dart';

/// Verifies the default (non-overridden) [dietPlanSourceProvider] wiring:
/// it MUST resolve [SqlDietPlanSource] exclusively. Reading the provider does
/// NOT trigger the underlying [LazyDatabase] to open, so this is safe to
/// assert without a device or a `path_provider` plugin mock.
void main() {
  group('dietPlanSourceProvider', () {
    test('resolves to SqlDietPlanSource by default (no overrides)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(dietPlanSourceProvider), isA<SqlDietPlanSource>());
    });
  });
}
