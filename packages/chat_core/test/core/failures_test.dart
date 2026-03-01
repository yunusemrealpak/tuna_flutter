import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('ServerFailure', () {
    test('equality — same props → equal', () {
      const f1 = ServerFailure(message: 'Not found', errorCode: 'NOT_FOUND');
      const f2 = ServerFailure(message: 'Not found', errorCode: 'NOT_FOUND');
      expect(f1, equals(f2));
    });

    test('different message → not equal', () {
      const f1 = ServerFailure(message: 'Not found', errorCode: 'NOT_FOUND');
      const f2 = ServerFailure(message: 'Other', errorCode: 'NOT_FOUND');
      expect(f1, isNot(equals(f2)));
    });

    test('different errorCode → not equal', () {
      const f1 = ServerFailure(message: 'err', errorCode: 'NOT_FOUND');
      const f2 = ServerFailure(message: 'err', errorCode: 'FORBIDDEN');
      expect(f1, isNot(equals(f2)));
    });

    test('is a Failure', () {
      expect(const ServerFailure(message: 'e', errorCode: 'E'), isA<Failure>());
    });
  });

  group('CacheFailure', () {
    test('equality', () {
      const f1 = CacheFailure(message: 'Cache miss');
      const f2 = CacheFailure(message: 'Cache miss');
      expect(f1, equals(f2));
    });

    test('different message → not equal', () {
      expect(
        const CacheFailure(message: 'a'),
        isNot(equals(const CacheFailure(message: 'b'))),
      );
    });
  });

  group('NetworkFailure', () {
    test('equality', () {
      const f1 = NetworkFailure(message: 'Timeout');
      const f2 = NetworkFailure(message: 'Timeout');
      expect(f1, equals(f2));
    });
  });

  group('AuthFailure', () {
    test('equality — same props → equal', () {
      const f1 = AuthFailure(message: 'Unauthorized', errorCode: 'UNAUTHORIZED');
      const f2 = AuthFailure(message: 'Unauthorized', errorCode: 'UNAUTHORIZED');
      expect(f1, equals(f2));
    });

    test('different errorCode → not equal', () {
      const f1 = AuthFailure(message: 'err', errorCode: 'UNAUTHORIZED');
      const f2 = AuthFailure(message: 'err', errorCode: 'FORBIDDEN');
      expect(f1, isNot(equals(f2)));
    });

    test('is a Failure', () {
      expect(const AuthFailure(message: 'e', errorCode: 'E'), isA<Failure>());
    });
  });

  group('Different Failure types', () {
    test('ServerFailure != CacheFailure even with same message', () {
      const server = ServerFailure(message: 'err', errorCode: 'E');
      const cache = CacheFailure(message: 'err');
      expect(server, isNot(equals(cache)));
    });
  });
}
