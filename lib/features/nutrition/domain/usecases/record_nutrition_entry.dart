import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/nutrition_health_source.dart';

/// Records a [NutritionEntry] through a [NutritionHealthSource].
///
/// A thin pass-through over the port: it does not re-validate [entry] (that
/// happens at construction time, via the value objects it composes) and it
/// forwards the port's [Result] — including any [Err] — unchanged.
class RecordNutritionEntry {
  RecordNutritionEntry(this._source);

  final NutritionHealthSource _source;

  Future<Result<void, NutritionFailure>> call(NutritionEntry entry) {
    return _source.record(entry);
  }
}
