import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/nutrition_health_source.dart';
import 'package:nutri_mvp/features/nutrition/domain/value_objects/nutrition_day.dart';

/// Queries all [NutritionEntry] instances recorded for a given
/// [NutritionDay] through a [NutritionHealthSource].
///
/// A thin pass-through over the port: it does not re-order or filter the
/// result — that responsibility belongs to the source implementation.
class GetDailyNutrition {
  GetDailyNutrition(this._source);

  final NutritionHealthSource _source;

  Future<Result<List<NutritionEntry>, NutritionFailure>> call(
    NutritionDay day,
  ) {
    return _source.entriesOn(day);
  }
}
