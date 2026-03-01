import 'package:dartz/dartz.dart';
import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('FutureEither', () {
    test('resolves to Right on success', () async {
      FutureEither<int> success() async => const Right(42);
      final result = await success();
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (value) => expect(value, 42),
      );
    });

    test('resolves to Left on failure', () async {
      FutureEither<int> failing() async =>
          const Left(ServerFailure(message: 'Not found', errorCode: 'NOT_FOUND'));
      final result = await failing();
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('type parameter is preserved', () async {
      FutureEither<String> strOp() async => const Right('hello');
      final result = await strOp();
      result.fold(
        (_) => fail('expected Right'),
        (s) => expect(s, 'hello'),
      );
    });
  });
}
