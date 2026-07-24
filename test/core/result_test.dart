import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mvp/core/result.dart';

void main() {
  group('Result', () {
    test('Ok holds a success value and reports isOk/isErr correctly', () {
      const Result<int, String> result = Ok<int, String>(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result, isA<Ok<int, String>>());
      expect((result as Ok<int, String>).value, 42);
    });

    test('Err holds a failure value and reports isOk/isErr correctly', () {
      const Result<int, String> result = Err<int, String>('boom');

      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
      expect(result, isA<Err<int, String>>());
      expect((result as Err<int, String>).failure, 'boom');
    });

    test('map transforms the success value when Ok', () {
      const result = Ok<int, String>(2);

      final mapped = result.map((value) => value * 10);

      expect(mapped, isA<Ok<int, String>>());
      expect((mapped as Ok<int, String>).value, 20);
    });

    test('map leaves the failure untouched when Err', () {
      const result = Err<int, String>('nope');

      final mapped = result.map((value) => value * 10);

      expect(mapped, isA<Err<int, String>>());
      expect((mapped as Err<int, String>).failure, 'nope');
    });

    test('Ok instances with the same value are equal', () {
      expect(const Ok<int, String>(1), const Ok<int, String>(1));
    });

    test('Err instances with the same failure are equal', () {
      expect(const Err<int, String>('x'), const Err<int, String>('x'));
    });
  });
}
