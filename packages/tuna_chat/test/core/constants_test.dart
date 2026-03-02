import 'package:tuna_chat/tuna_chat.dart';
import 'package:test/test.dart';

void main() {
  group('ApiConstants', () {
    test('defaultBaseUrl is a valid http URL', () {
      expect(ApiConstants.defaultBaseUrl, startsWith('http'));
    });

    test('defaultWsUrl is a valid ws URL', () {
      expect(ApiConstants.defaultWsUrl, startsWith('ws'));
    });

    test('connectTimeout is positive', () {
      expect(ApiConstants.connectTimeout.inSeconds, greaterThan(0));
    });

    test('receiveTimeout is greater than connectTimeout', () {
      expect(
        ApiConstants.receiveTimeout,
        greaterThan(ApiConstants.connectTimeout),
      );
    });

    test('defaultPageLimit is positive and reasonable', () {
      expect(ApiConstants.defaultPageLimit, greaterThan(0));
      expect(ApiConstants.defaultPageLimit, lessThanOrEqualTo(100));
    });

    test('messagePageLimit is positive and reasonable', () {
      expect(ApiConstants.messagePageLimit, greaterThan(0));
      expect(ApiConstants.messagePageLimit, lessThanOrEqualTo(100));
    });

    test('wsReconnectMaxDelay >= wsReconnectInitialDelay', () {
      expect(
        ApiConstants.wsReconnectMaxDelay,
        greaterThanOrEqualTo(ApiConstants.wsReconnectInitialDelay),
      );
    });

    test('syncMaxRetries is positive', () {
      expect(ApiConstants.syncMaxRetries, greaterThan(0));
    });
  });
}
