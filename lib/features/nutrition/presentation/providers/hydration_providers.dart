import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_hydration_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/hydration_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_daily_hydration.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/record_hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/hydration_controller.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/nutrition_providers.dart'
    show nutritionDatabaseProvider;

/// Resolves the [HydrationSource] port. In production this is
/// [SqlHydrationSource] over the SAME on-disk [nutritionDatabaseProvider]
/// used by nutrition (one physical database file, two independent tables —
/// see `hydration-log` design). Tests override this provider with
/// `FakeHydrationSource` to avoid touching drift entirely.
final hydrationSourceProvider = Provider<HydrationSource>((ref) {
  return SqlHydrationSource(ref.watch(nutritionDatabaseProvider));
});

final recordHydrationProvider = Provider<RecordHydrationEntry>((ref) {
  return RecordHydrationEntry(ref.watch(hydrationSourceProvider));
});

final getDailyHydrationProvider = Provider<GetDailyHydration>((ref) {
  return GetDailyHydration(ref.watch(hydrationSourceProvider));
});

/// Orchestrates today's hydration entries and lets the UI record new ones.
final hydrationControllerProvider =
    AsyncNotifierProvider<HydrationController, List<HydrationEntry>>(
      HydrationController.new,
    );
