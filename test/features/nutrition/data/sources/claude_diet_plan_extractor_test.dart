import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mvp/core/result.dart';
import 'package:nutri_mvp/features/nutrition/data/sources/claude_diet_plan_extractor.dart';
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

/// A reply in the shape the Messages API returns.
String reply(String text, {String stopReason = 'end_turn'}) {
  return jsonEncode({
    'id': 'msg_1',
    'type': 'message',
    'role': 'assistant',
    'model': 'claude-opus-5',
    'stop_reason': stopReason,
    'content': [
      {'type': 'text', 'text': text},
    ],
  });
}

const document = '{"schemaVersion":1,"diet":{"name":"Plan"}}';

void main() {
  late http.Request? sent;

  ClaudeDietPlanExtractor extractorReturning(
    http.Response Function(http.Request request) respond, {
    String apiKey = 'test-key',
  }) {
    return ClaudeDietPlanExtractor(
      apiKey: apiKey,
      client: MockClient((request) async {
        sent = request;
        return respond(request);
      }),
    );
  }

  ClaudeDietPlanExtractor extractorSaying(
    String text, {
    String stopReason = 'end_turn',
  }) {
    return extractorReturning(
      (_) => http.Response(reply(text, stopReason: stopReason), 200),
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

  group('asking the model to read the pages', () {
    test('sends every page as an image, in order', () async {
      await extractorSaying(document).extract(pages(3));

      final body = jsonDecode(sent!.body) as Map<String, dynamic>;
      final content =
          ((body['messages'] as List).single as Map)['content'] as List;
      final images = content
          .where((block) => block['type'] == 'image')
          .toList();

      expect(images, hasLength(3));
      expect(images.first['source']['media_type'], 'image/png');
      expect(
        images.first['source']['data'],
        base64Encode(Uint8List.fromList([1, 1, 1])),
      );
      // The instruction comes last, after the pages it refers to.
      expect(content.last['type'], 'text');
    });

    test('authenticates with the key it was given', () async {
      await extractorSaying(document).extract(pages());

      expect(sent!.headers['x-api-key'], 'test-key');
      expect(sent!.headers['anthropic-version'], '2023-06-01');
    });

    test(
      'tells the model to describe foods, never to name table ids',
      () async {
        // The whole reason the extractor exists as a transcriber: matching is a
        // local, deterministic job, and a model guessing at ids would break it.
        await extractorSaying(document).extract(pages());

        final system = (jsonDecode(sent!.body) as Map)['system'] as String;
        expect(system, contains('extractedFoods'));
        expect(system, contains('NEVER'));
        expect(system, contains('TOTAL'));
      },
    );

    test('returns the document the model produced', () async {
      final result = await extractorSaying(document).extract(pages());

      expect(documentOf(result), document);
    });

    test('tolerates a Markdown fence around the JSON', () async {
      // Instructed against, but a stray fence should not waste an extraction.
      final result = await extractorSaying(
        '```json\n$document\n```',
      ).extract(pages());

      expect(documentOf(result), document);
    });
  });

  group('refusing to pretend a failed read worked', () {
    test('does not call the service without a key', () async {
      final result = await extractorSaying(
        document,
        stopReason: 'end_turn',
      ).extract(pages());
      expect(result, isA<Ok<String, NutritionFailure>>());

      final unconfigured = extractorReturning(
        (_) => http.Response(reply(document), 200),
        apiKey: '',
      );
      sent = null;
      final failure = failureOf(await unconfigured.extract(pages()));

      expect(failure, isA<StorageFailure>());
      expect((failure as StorageFailure).reason, contains('API key'));
      expect(sent, isNull, reason: 'must not send an unauthenticated request');
    });

    test('reports an empty page list as a malformed plan', () async {
      final failure = failureOf(await extractorSaying(document).extract([]));

      expect(failure, isA<MalformedPlanFailure>());
    });

    test('reports a refusal as its own failure, not a bad plan file', () async {
      final failure = failureOf(
        await extractorSaying('', stopReason: 'refusal').extract(pages()),
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
          stopReason: 'max_tokens',
        ).extract(pages()),
      );

      expect(failure, isA<MalformedPlanFailure>());
      expect((failure as MalformedPlanFailure).reason, contains('did not fit'));
    });

    test('reports an HTTP error as a storage failure', () async {
      final failure = failureOf(
        await extractorReturning(
          (_) => http.Response('nope', 401),
        ).extract(pages()),
      );

      expect(failure, isA<StorageFailure>());
      expect((failure as StorageFailure).reason, contains('401'));
    });

    test('reports a network error rather than throwing', () async {
      final extractor = ClaudeDietPlanExtractor(
        apiKey: 'test-key',
        client: MockClient((_) => throw const SocketFailure()),
      );

      final failure = failureOf(await extractor.extract(pages()));

      expect(failure, isA<StorageFailure>());
      expect((failure as StorageFailure).reason, contains('could not reach'));
    });

    test('reports a reply that is not a message', () async {
      final failure = failureOf(
        await extractorReturning(
          (_) => http.Response('not json', 200),
        ).extract(pages()),
      );

      expect(failure, isA<StorageFailure>());
    });

    test('reports a reply carrying no text', () async {
      final failure = failureOf(
        await extractorReturning(
          (_) => http.Response(
            jsonEncode({'stop_reason': 'end_turn', 'content': []}),
            200,
          ),
        ).extract(pages()),
      );

      expect(failure, isA<MalformedPlanFailure>());
    });
  });
}

/// Stands in for a transport-level error, which arrives as an arbitrary throw.
class SocketFailure implements Exception {
  const SocketFailure();

  @override
  String toString() => 'SocketFailure: connection refused';
}
