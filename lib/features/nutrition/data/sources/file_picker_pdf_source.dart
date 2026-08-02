import 'package:file_picker/file_picker.dart';
import 'package:nutri_mvp/core/result.dart';

import '../../domain/failures/nutrition_failure.dart';
import '../../domain/ports/pdf_file_picker.dart';

/// Picks a diet PDF with the `file_picker` plugin.
class FilePickerPdfSource implements PdfFilePicker {
  const FilePickerPdfSource();

  @override
  Future<Result<PickedPdf?, NutritionFailure>> pickPdf() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        // The importer works on bytes, so the plugin reads the file for us
        // rather than handing back a path the app may not be allowed to open.
        withData: true,
      );
    } on Object catch (error) {
      return Err(StorageFailure('could not open the file picker: $error'));
    }

    if (result == null || result.files.isEmpty) return const Ok(null);

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return const Err(StorageFailure('could not read the chosen file'));
    }
    return Ok(PickedPdf(name: file.name, bytes: bytes));
  }
}
