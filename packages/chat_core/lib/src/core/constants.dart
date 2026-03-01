/// SDK-wide constants.
/// Override via ChatConfig when initializing the SDK.
abstract class ApiConstants {
  static const String defaultBaseUrl = 'http://localhost:8080/api/v1';
  static const String defaultWsUrl = 'ws://localhost:8080/api/v1/ws';

  // HTTP timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageLimit = 20;
  static const int messagePageLimit = 50;

  // WebSocket
  static const Duration wsHeartbeatInterval = Duration(seconds: 30);
  static const Duration wsReconnectInitialDelay = Duration(seconds: 1);
  static const Duration wsReconnectMaxDelay = Duration(seconds: 30);
  static const int wsReconnectMaxAttempts = 10;

  // Sync engine
  static const int syncMaxRetries = 5;
}
