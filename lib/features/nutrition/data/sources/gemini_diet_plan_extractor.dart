import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nutri_mvp/core/result.dart';

import '../../domain/failures/nutrition_failure.dart';
import '../../domain/ports/diet_pdf_importer.dart';
import 'diet_extraction_prompt.dart';

/// Reads a diet plan off rendered pages with Gemini.
///
/// Exists alongside the Claude adapter because reading a plan is transcription,
/// not reasoning: the work is OCR plus structure, which Gemini's free tier
/// covers at no cost. What it must get right is the same either way — the
/// brief is [dietExtractionPrompt], shared verbatim — so the choice of provider
/// changes who reads the plan, never what a correct reading is.
///
/// The riskiest mistake for a cheaper model is not misreading a word, it is
/// misreading a quantity: that produces a valid document with wrong macros. The
/// review screen lets the user correct amounts precisely because of this.
class GeminiDietPlanExtractor implements DietPlanExtractor {
  GeminiDietPlanExtractor({
    required String apiKey,
    http.Client? client,
    this.model = defaultModel,
    this.maxOutputTokens = 32000,
    this.timeout = const Duration(minutes: 5),
  }) : _apiKey = apiKey,
       _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  /// Which Gemini model to call.
  ///
  /// Configurable because Google retires and renames these faster than the app
  /// ships; if a build starts failing with "model not found", this is the knob.
  final String model;

  final int maxOutputTokens;

  /// Reading a 14-page plan is minutes of work, not seconds.
  final Duration timeout;

  static const String defaultModel = 'gemini-3.6-flash';

  /// Passed at build time (`--dart-define=GEMINI_API_KEY=...`) so it never
  /// reaches the repository.
  static const String apiKeyFromEnvironment = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  static bool get isConfigured => apiKeyFromEnvironment.isNotEmpty;

  Uri get _endpoint => Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/'
    '$model:generateContent',
  );

  @override
  Future<Result<String, NutritionFailure>> extract(
    List<PdfPageImage> pages,
  ) async {
    if (_apiKey.isEmpty) {
      return const Err(
        StorageFailure('no API key configured for reading diet PDFs'),
      );
    }
    if (pages.isEmpty) {
      return const Err(MalformedPlanFailure('there are no pages to read'));
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: {
              'content-type': 'application/json',
              // In the header rather than a `?key=` query parameter, which
              // would put the secret in every proxy and server log.
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode(_requestBody(pages)),
          )
          .timeout(timeout);
    } on Object catch (error) {
      return Err(
        StorageFailure(
          'could not reach the extraction service: '
          '$error',
        ),
      );
    }

    if (response.statusCode != 200) {
      return Err(
        StorageFailure(
          'the extraction service refused the request '
          '(HTTP ${response.statusCode})',
        ),
      );
    }

    return _readDocument(response.body);
  }

  Map<String, Object?> _requestBody(List<PdfPageImage> pages) {
    return {
      'systemInstruction': {
        'parts': [
          {'text': dietExtractionPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            for (final page in pages)
              {
                'inline_data': {
                  'mime_type': page.mimeType,
                  'data': base64Encode(page.bytes),
                },
              },
            {
              'text':
                  'These are pages 1 to ${pages.length} of one diet plan. '
                  'Return the plan as a single JSON document.',
            },
          ],
        },
      ],
      'generationConfig': {
        // Constrains the reply to JSON, so a stray sentence cannot break the
        // document. The shape itself is still validated downstream.
        'responseMimeType': 'application/json',
        'maxOutputTokens': maxOutputTokens,
      },
    };
  }

  /// Pulls the document out of the reply, telling the failure modes apart.
  ///
  /// A safety block, a truncated answer and a broken response need three
  /// different things from the user, so they must not collapse into one
  /// "could not read the plan".
  Result<String, NutritionFailure> _readDocument(String responseBody) {
    final Object? decoded;
    try {
      decoded = jsonDecode(responseBody);
    } on FormatException catch (error) {
      return Err(
        StorageFailure(
          'the extraction service returned a malformed reply: ${error.message}',
        ),
      );
    }
    if (decoded is! Map) {
      return const Err(
        StorageFailure('the extraction service returned an unexpected reply'),
      );
    }

    // Blocked before generating anything.
    final feedback = decoded['promptFeedback'];
    if (feedback is Map && feedback['blockReason'] != null) {
      return Err(
        MalformedPlanFailure(
          'the model declined to read this document '
          '(${feedback['blockReason']})',
        ),
      );
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return const Err(
        StorageFailure('the extraction service returned no content'),
      );
    }
    final candidate = candidates.first;
    if (candidate is! Map) {
      return const Err(
        StorageFailure('the extraction service returned an unexpected reply'),
      );
    }

    switch (candidate['finishReason']) {
      case 'MAX_TOKENS':
        return const Err(
          MalformedPlanFailure(
            'the plan did not fit in one reply; try importing fewer pages',
          ),
        );
      case 'SAFETY':
      case 'RECITATION':
      case 'PROHIBITED_CONTENT':
        return Err(
          MalformedPlanFailure(
            'the model declined to read this document '
            '(${candidate['finishReason']})',
          ),
        );
    }

    final content = candidate['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) {
      return const Err(
        MalformedPlanFailure('the model answered without a plan document'),
      );
    }

    final text = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) text.write(part['text']);
    }
    if (text.isEmpty) {
      return const Err(
        MalformedPlanFailure('the model answered without a plan document'),
      );
    }

    return Ok(text.toString().trim());
  }
}
