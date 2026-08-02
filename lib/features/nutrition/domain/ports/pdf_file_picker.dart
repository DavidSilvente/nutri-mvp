import 'dart:typed_data';

import 'package:nutri_mvp/core/result.dart';

import '../failures/nutrition_failure.dart';

/// A PDF the user chose, with the name to show it under.
class PickedPdf {
  const PickedPdf({required this.name, required this.bytes});

  /// The file name, used as the plan's source label.
  final String name;

  final Uint8List bytes;
}

/// Lets the user choose a diet PDF from their device.
///
/// A port because file selection is platform work behind a native plugin, and
/// the import flow only needs the bytes and a name. Keeping it behind an
/// interface is also what lets the whole flow be tested without a device.
abstract interface class PdfFilePicker {
  /// Returns the chosen file, or null when the user backed out.
  ///
  /// Cancelling is an ordinary outcome, not a failure — the distinction is what
  /// stops the UI from showing an error for a deliberate dismissal.
  Future<Result<PickedPdf?, NutritionFailure>> pickPdf();
}
