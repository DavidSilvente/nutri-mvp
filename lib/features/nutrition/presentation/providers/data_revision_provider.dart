import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A monotonically increasing counter bumped after every successful write to
/// nutrition or diet-plan data.
///
/// Derived read models (the day plan, the month calendar) watch this instead
/// of being invalidated by hand from each writer. That keeps the dependency
/// pointing one way — writers know nothing about the views built on top of
/// them — and makes it impossible to add a new derived view that silently
/// goes stale after a write.
final dataRevisionProvider = StateProvider<int>((ref) => 0);

/// Signals that persisted nutrition or diet-plan data changed.
void bumpDataRevision(Ref ref) {
  ref.read(dataRevisionProvider.notifier).update((value) => value + 1);
}
