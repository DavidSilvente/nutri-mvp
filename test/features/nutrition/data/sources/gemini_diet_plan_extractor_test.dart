import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/gemini_diet_plan_extractor.dart';
import 'package:nutri_mvp/features/nutrition/domain/failures/nutrition_failure.dart';
import 'package:nutri_mvp/features/nutrition/domain/ports/diet_pdf_importer.dart';

List<PdfPageImage> pages([int count = 2]) => [
  for (var page = 1; page <= count; page++)
    PdfPageImage(
      pageNumber: page,
      bytes: Uint8List.fromList([page, page, page]),
      mimeType: 'image/png',
    ),
];

/// A reply in the shape generateContent returns.
String reply(String text, {String finishReason = 'STOP'}) {
  return jsonEncode({
    'candidates': [
      {
        'content': {
          'role': 'model',
          'parts': [
            {'text': text},
          ],
        },
        'finishReason': finishReason,
      },
    ],
  });
}

const document = '{"schemaVersion":1,"diet":{"name":"Plan"}}';

void main() {
  late http.Request? sent;

  GeminiDietPlanExtractor extractorReturning(
    http.Response Function(http.Request request) respond, {
    String apiKey = 'test-key',
  }) {
    return GeminiDietPlanExtractor(
      apiKey: apiKey,
      client: MockClient((request) async {
        sent = request;
        return respond(request);
      }),
    );
  }

  GeminiDietPlanExtractor extractorSaying(
    String text, {
    String finishReason = 'STOP',
  }) {
    return extractorReturning(
      (_) => http.Response(reply(text, finishReason: finishReason), 200),
    );
  }

  String documentOf(Result<String, NutritionFailure> result) {
    return switch (result) {
      Ok(value: final value) => value,
      Err(failure: final failure) => fail('$failure'),
    };
  }

  NutritionFailure failureOf(Result<String, NutritionFailure> result) {
    return switch (result) {
      Ok(value: final value) => fail('expected a failure, got $value'),
      Err(failure: final failure) => failure,
    };
  }

  setUp(() => sent = null);

  group('asking Gemini to read the pages', () {
    test('sends every page as inline image data, in order', () async {
      await extractorSaying(document).extract(pages(3));

      final body = jsonDecode(sent!.body) as Map<String, dynamic>;
      final parts =
          ((body['contents'] as List).single as Map)['parts'] as List;
      final images =
          parts.where((part) => part['inline_data'] != null).toList();

      expect(images, hasLength(3));
      expect(images.first['inline_data']['mime_type'], 'image/png');
      expect(
        images.first['inline_data']['data'],
        base64Encode(Uint8List.fromList([1, 1, 1])),
      );
      // The instruction comes last, after the pages it refers to.
      expect(parts.last['text'], contains('pages 1 to 3'));
    });

    test('keeps the key out of the URL', () async {
      // A key in the query string ends up in every proxy and server log.
      await extractorSaying(document).extract(pages());

      expect(sent!.headers['x-goog-api-key'], 'test-key');
      expect(sent!.url.query, isEmpty);
      expect(sent!.url.toString(), contains('gemini-3.6-flash:generateContent'));
    });

    test('constrains the reply to JSON', () async {
      await extractorSaying(document).extract(pages());

      final body = jsonDecode(sent!.body) as Map<String, dynamic>;
      expect(
        body['generationConfig']['responseMimeType'],
        'application/json',
      );
    });

    test('reads the plan with the same brief as the other adapter', () async {
      // Swapping providers must change who reads the plan, not what a correct
      // reading is — the quantity rule especially.
      await extractorSaying(document).extract(pages());

      final body = jsonDecode(sent!.body) as Map<String, dynamic>;
      final system =
          (body['systemInstruction']['parts'] as List).single['text'] as String;
      expect(system, contains('extractedFoods'));
      expect(system, contains('ONE REF PER PRINTED LINE'));
      expect(system, contains('TOTAL'));
    });

    test('calls the model it was configured with', () async {
      final extractor = GeminiDietPlanExtractor(
        apiKey: 'test-key',
        model: 'gemini-something-else',
        client: MockClient((request) async {
          sent = request;
          return http.Response(reply(document), 200);
        }),
      );

      await extractor.extract(pages());

      expect(
        sent!.url.toString(),
        contains('gemini-something-else:generateContent'),
      );
    });

    test('returns the document the model produced', () async {
      expect(
        documentOf(await extractorSaying(document).extract(pages())),
        document,
      );
    });
  });

  group('refusing to pretend a failed read worked', () {
    test('does not call the service without a key', () async {
      final unconfigured = extractorReturning(
        (_) => http.Response(reply(document), 200),
        apiKey: '',
      );

      final failure = failureOf(await unconfigured.extract(pages()));

      expect(failure, isA<StorageFailure>());
      expect((failure as StorageFailure).reason, contains('API key'));
      expect(sent, isNull, reason: 'must not send an unauthenticated request');
    });

    test('reports an empty page list as a malformed plan', () async {
      expect(
        failureOf(await extractorSaying(document).extract([])),
        isA<MalformedPlanFailure>(),
      );
    });

    test('reports a safety block before generation', () async {
      final failure = failureOf(
        await extractorReturning(
          (_) => http.Response(
            jsonEncode({
              'promptFeedback': {'blockReason': 'SAFETY'},
            }),
            200,
          ),
        ).extract(pages()),
      );

      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('declined'));
    });

    test('reports a safety block during generation', () async {
      final failure = failureOf(
        await extractorSaying('', finishReason: 'SAFETY').extract(pages()),
      );

      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('declined'));
    });

    test('reports a truncated reply so the user can act on it', () async {
      // A plan cut off mid-JSON would otherwise surface as "invalid JSON",
      // which points the user at the wrong problem.
      final failure = failureOf(
        await extractorSaying(
          '{"schemaVersion":1,"diet":{"na',
          finishReason: 'MAX_TOKENS',
        ).extract(pages()),
      );

      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('did not fit'));
    });

    test('reports an HTTP error as a storage failure', () async {
      final failure = failureOf(
        await extractorReturning((_) => http.Response('nope', 429))
            .extract(pages()),
      );

      expect(failure, isA<StorageFailure>());
      expect((failure as StorageFailure).reason, contains('429'));
    });

    test('reports a network error rather than throwing', () async {
      final extractor = GeminiDietPlanExtractor(
        apiKey: 'test-key',
        client: MockClient((_) => throw const SocketFailure()),
      );

      final failure = failureOf(await extractor.extract(pages()));

      expect(failure, isA<StorageFailure>());
      expect((failure as StorageFailure).reason, contains('could not reach'));
    });

    test('reports a reply that is not a message', () async {
      expect(
        failureOf(
          await extractorReturning((_) => http.Response('not json', 200))
              .extract(pages()),
        ),
        isA<StorageFailure>(),
      );
    });

    test('reports a reply carrying no candidates', () async {
      expect(
        failureOf(
          await extractorReturning(
            (_) => http.Response(jsonEncode({'candidates': []}), 200),
          ).extract(pages()),
        ),
        isA<StorageFailure>(),
      );
    });
  });
}

/// Stands in for a transport-level error, which arrives as an arbitrary throw.
class SocketFailure implements Exception {
  const SocketFailure();

  @override
  String toString() => 'SocketFailure: connection refused';
}
