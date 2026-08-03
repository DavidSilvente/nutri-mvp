import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutri_mvp/core/health_failure_exception.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/presentation/providers/saved_meal_providers.dart';

/// Shared save-and-close behaviour for every dialog that writes to the
/// saved-meal catalogue through `savedMealControllerProvider`.
///
/// Both `_SavedMealDialog` (create/edit) and `SaveEntryAsMealDialog`
/// (promote-from-logged-entry) need the exact same dance: await the write,
/// close only if it succeeded, otherwise keep the dialog open with the
/// failure rendered inline so the user's typed input is never lost. That
/// dance — plus rendering a `ConflictFailure` as its `reason` — was
/// implemented twice, line for line. This mixin is the single place that
/// dance lives now; each dialog supplies only its own form fields and its
/// own write call.
///
/// A mixin rather than a shared base `State` class because both hosts
/// already extend `ConsumerState<T>` with a different widget type, and Dart
/// has no multiple inheritance — a mixin is the tool for adding shared
/// behaviour on top of that.
mixin SavedMealWriteMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool saving = false;
  String? error;

  /// Runs [write], then closes the dialog on success or surfaces the
  /// failure inline and re-enables the form on error.
  ///
  /// Guards every `setState`/`Navigator` call made after the `await` with
  /// `mounted`, since the write is asynchronous and the dialog can be
  /// dismissed (or the whole screen popped) while it is in flight.
  Future<void> submitSavedMealWrite(Future<void> Function() write) async {
    setState(() {
      error = null;
      saving = true;
    });

    await write();

    final state = ref.read(savedMealControllerProvider);
    if (!state.hasError) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    if (!mounted) return;
    setState(() {
      saving = false;
      error = _formatSaveError(state.error);
    });
  }
}

String _formatSaveError(Object? error) {
  if (error is HealthFailureException) {
    return switch (error.failure) {
      ConflictFailure(reason: final reason) => reason,
      _ => 'Could not save this meal',
    };
  }
  return 'Could not save this meal';
}
