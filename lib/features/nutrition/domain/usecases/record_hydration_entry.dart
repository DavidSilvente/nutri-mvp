import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/domain/entities/hydration_entry.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/hydration_source.dart';

/// Records a [HydrationEntry] through a [HydrationSource].
///
/// A thin pass-through over the port: it does not re-validate [entry] (that
/// happens at construction time, via the value objects it composes) and it
/// forwards the port's [Result] — including any [Err] — unchanged.
class RecordHydrationEntry {
  RecordHydrationEntry(this._source);

  final HydrationSource _source;

  Future<Result<void, NutritionFailure>> call(HydrationEntry entry) {
    return _source.record(entry);
  }
}
