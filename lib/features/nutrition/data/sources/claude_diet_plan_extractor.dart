import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nutri_mvp/core/result.dart';

import '../../domain/failures/nutrition_failure.dart';
import '../../domain/ports/diet_pdf_importer.dart';
import 'diet_extraction_prompt.dart';

/// Reads a diet plan off rendered pages with a multimodal model.
///
/// The model's only job is to TRANSCRIBE: what the page says, structured. It
/// never states a macro figure and never names a food-table id — it has no way
/// to know what `usda_167512` is, and listing the table for it would mean
/// shipping ~470 KB on every import to do a matching job [FoodMatcher] already
/// does locally and deterministically. Every food it reads comes back as a
/// description under a draft-local ref, which the app resolves afterwards.
class ClaudeDietPlanExtractor implements DietPlanExtractor {
  ClaudeDietPlanExtractor({
    required String apiKey,
    http.Client? client,
    this.model = defaultModel,
    this.maxTokens = 32000,
    this.timeout = const Duration(minutes: 5),
  }) : _apiKey = apiKey,
       _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;
  final String model;
  final int maxTokens;

  /// Reading a 14-page plan is minutes of work, not seconds.
  ///
  /// The default HTTP timeout would abort a perfectly healthy request; the cost
  /// of waiting is a spinner, the cost of aborting is a wasted extraction.
  final Duration timeout;

  static const String defaultModel = 'claude-opus-5';

  static final Uri _endpoint = Uri.parse(
    'https://api.anthropic.com/v1/messages',
  );

  /// Where the key comes from in a real build.
  ///
  /// Passed at build time (`--dart-define=ANTHROPIC_API_KEY=...`) so it never
  /// reaches the repository. Empty when unset, which the caller must treat as
  /// "import is not configured" rather than sending an unauthenticated request.
  static const String apiKeyFromEnvironment = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
  );

  static bool get isConfigured => apiKeyFromEnvironment.isNotEmpty;

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
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
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
      'model': model,
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': [
            for (final page in pages)
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': page.mimeType,
                  'data': base64Encode(page.bytes),
                },
              },
            {
              'type': 'text',
              'text':
                  'These are pages 1 to ${pages.length} of one diet plan. '
                  'Return the plan as a single JSON document.',
            },
          ],
        },
      ],
    };
  }

  /// Pulls the document out of the model's reply.
  ///
  /// A refusal or a truncated answer is reported as such rather than handed on
  /// as a "malformed plan", because the fix differs: one means rephrase or use
  /// another file, the other means the plan did not fit in one reply.
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

    if (decoded['stop_reason'] == 'refusal') {
      return const Err(
        MalformedPlanFailure('the model declined to read this document'),
      );
    }
    if (decoded['stop_reason'] == 'max_tokens') {
      return const Err(
        MalformedPlanFailure(
          'the plan did not fit in one reply; try importing fewer pages',
        ),
      );
    }

    final content = decoded['content'];
    if (content is! List) {
      return const Err(
        StorageFailure('the extraction service returned no content'),
      );
    }

    final text = StringBuffer();
    for (final block in content) {
      if (block is Map && block['type'] == 'text' && block['text'] is String) {
        text.write(block['text']);
      }
    }
    if (text.isEmpty) {
      return const Err(
        MalformedPlanFailure('the model answered without a plan document'),
      );
    }

    return Ok(_unwrapJson(text.toString()));
  }

  /// Strips a Markdown code fence, if the model wrapped the JSON in one.
  ///
  /// Instructed not to, but a stray fence should not fail an otherwise good
  /// extraction — the document itself is validated downstream either way.
  static String _unwrapJson(String raw) {
    final text = raw.trim();
    if (!text.startsWith('```')) return text;
    final firstBreak = text.indexOf('\n');
    if (firstBreak == -1) return text;
    final withoutOpening = text.substring(firstBreak + 1);
    final closing = withoutOpening.lastIndexOf('```');
    return (closing == -1
            ? withoutOpening
            : withoutOpening.substring(0, closing))
        .trim();
  }

  /// The brief every extractor shares — see [dietExtractionPrompt].
  static const String systemPrompt = dietExtractionPrompt;
}
