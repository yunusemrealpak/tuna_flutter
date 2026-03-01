import 'package:flutter_test/flutter_test.dart';
import 'package:chat_flutter/chat_flutter.dart';

void main() {
  test('ChatConfig holds provided values', () {
    const config = ChatConfig(
      apiBaseUrl: 'http://localhost:8080/api/v1',
      wsUrl: 'ws://localhost:8080/api/v1/ws',
    );
    expect(config.apiBaseUrl, 'http://localhost:8080/api/v1');
    expect(config.wsUrl, 'ws://localhost:8080/api/v1/ws');
    expect(config.enableOfflineMode, isTrue);
  });
}
