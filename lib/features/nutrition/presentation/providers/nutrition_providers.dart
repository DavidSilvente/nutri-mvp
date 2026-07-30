import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/features/nutrition/data/database/nutrition_database.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/sql_nutrition_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/nutrition_health_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/get_daily_nutrition.dart';
import 'package:nutri_mvp/features/nutrition/domain/usecases/record_nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/presentation/controllers/nutrition_controller.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Production drift database, backed by a file on disk under the app's
/// documents directory, so entries survive app restarts. Tests NEVER read
/// this provider directly — they override [nutritionSourceProvider] with
/// `FakeNutritionSource` instead.
final nutritionDatabaseProvider = Provider<NutritionDatabase>((ref) {
  final db = NutritionDatabase(_openConnection());
  ref.onDispose(db.close);
  return db;
});

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'nutrition.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Resolves the [NutritionHealthSource] port. In production this is
/// [SqlNutritionSource] over the on-disk [nutritionDatabaseProvider]. Tests
/// override this provider with `FakeNutritionSource` to avoid touching
/// drift entirely.
final nutritionSourceProvider = Provider<NutritionHealthSource>((ref) {
  return SqlNutritionSource(ref.watch(nutritionDatabaseProvider));
});

final recordEntryProvider = Provider<RecordNutritionEntry>((ref) {
  return RecordNutritionEntry(ref.watch(nutritionSourceProvider));
});

final getDailyProvider = Provider<GetDailyNutrition>((ref) {
  return GetDailyNutrition(ref.watch(nutritionSourceProvider));
});

/// Orchestrates today's nutrition entries and lets the UI record new ones.
final nutritionControllerProvider =
    AsyncNotifierProvider<NutritionController, List<NutritionEntry>>(
      NutritionController.new,
    );
