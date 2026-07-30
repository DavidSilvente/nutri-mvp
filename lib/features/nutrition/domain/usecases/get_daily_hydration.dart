import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/hydration_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// Queries all [HydrationEntry] instances recorded for a given
/// [NutritionDay] through a [HydrationSource].
///
/// A thin pass-through over the port: it does not re-order or filter the
/// result — that responsibility belongs to the source implementation.
class GetDailyHydration {
  GetDailyHydration(this._source);

  final HydrationSource _source;

  Future<Result<List<HydrationEntry>, NutritionFailure>> call(
    NutritionDay day,
  ) {
    return _source.entriesOn(day);
  }
}
