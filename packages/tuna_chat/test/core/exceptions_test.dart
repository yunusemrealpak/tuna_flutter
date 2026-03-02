import 'package:tuna_chat/tuna_chat.dart';
import 'package:test/test.dart';

void main() {
  group('ServerException', () {
    test('toString includes code and message', () {
      const e = ServerException(message: 'Not found', statusCode: 404, errorCode: 'NOT_FOUND');
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('NOT_FOUND'));
      expect(e.toString(), contains('Not found'));
    });

    test('is an Exception', () {
      const e = ServerException(message: 'err', statusCode: 500, errorCode: 'INTERNAL_ERROR');
      expect(e, isA<Exception>());
    });
  });

  group('CacheException', () {
    test('toString includes message', () {
      const e = CacheException(message: 'Cache miss');
      expect(e.toString(), contains('Cache miss'));
    });
  });

  group('NetworkException', () {
    test('toString includes message', () {
      const e = NetworkException(message: 'Connection timeout');
      expect(e.toString(), contains('Connection timeout'));
    });
  });

  group('AuthException', () {
    test('toString includes errorCode and message', () {
      const e = AuthException(message: 'Invalid credentials', errorCode: 'UNAUTHORIZED');
      expect(e.toString(), contains('UNAUTHORIZED'));
      expect(e.toString(), contains('Invalid credentials'));
    });
  });
}
