import 'dart:async';

import 'package:tuna_chat/tuna_chat.dart';

import 'di/injection.dart';

/// TunaChat SDK configuration.
class TunaChatConfig {
  const TunaChatConfig({
    required this.apiKey,
    this.baseUrl,
    this.wsUrl,
    this.tokenProvider,
  });

  final String apiKey;

  /// Override the REST base URL (e.g. `http://your-tunachat-host/api/v1`).
  /// Defaults to `http://localhost:8080/api/v1`.
  final String? baseUrl;

  /// Override the WebSocket URL (e.g. `ws://your-tunachat-host/api/v1/ws`).
  /// Defaults to `ws://localhost:8080/api/v1/ws`.
  final String? wsUrl;

  /// Optional callback that returns a fresh JWT when the current one expires.
  ///
  /// Used by [ApiClient] on HTTP 401 and by [WsClient] before each reconnect
  /// attempt. Should return a new token or null to trigger disconnection.
  ///
  /// Example (Stream Chat pattern):
  /// ```dart
  /// TunaChatConfig(
  ///   apiKey: 'tuna_key_xxx',
  ///   tokenProvider: () async => await myServer.fetchChatToken(userId),
  /// )
  /// ```
  final Future<String?> Function()? tokenProvider;

  String get resolvedBaseUrl =>
      baseUrl ?? 'http://localhost:8080/api/v1';

  String get resolvedWsUrl =>
      wsUrl ?? 'ws://localhost:8080/api/v1/ws';
}

/// Public entry point for the TunaChat SDK.
///
/// Usage:
/// ```dart
/// // 1. Initialize once at app startup:
/// await TunaChatSDK.init(
///   config: TunaChatConfig(apiKey: 'tuna_key_xxxxx'),
/// );
///
/// // 2. After host app authenticates the user and obtains a JWT:
/// final user = await TunaChatSDK.instance.connectUser(
///   userId: 'host-user-123',
///   token: hostSignedJwt,
/// );
/// ```
class TunaChatSDK {
  TunaChatSDK._();

  static TunaChatSDK? _instance;
  static TunaChatConfig? _config;
  StreamSubscription<ChatEvent>? _eventSubscription;

  static TunaChatSDK get instance {
    assert(_instance != null, 'Call TunaChatSDK.init() first.');
    return _instance!;
  }

  static TunaChatConfig get config {
    assert(_config != null, 'Call TunaChatSDK.init() first.');
    return _config!;
  }

  static Future<void> init({required TunaChatConfig config}) async {
    _config = config;
    await registerDependencies(config);
    _instance = TunaChatSDK._();
  }

  /// Connect a user to TunaChat with a host-signed JWT.
  ///
  /// Sets the token in [ApiClient], fetches the user profile to verify the
  /// token, and establishes the WebSocket connection.
  ///
  /// Throws an [Exception] if the connection fails.
  Future<User> connectUser({
    required String userId,
    required String token,
  }) async {
    final repo = sl<ConnectionRepository>();
    final result = await repo.connectUser(userId: userId, token: token);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (user) {
        _wireEventHandler();
        return user;
      },
    );
  }

  /// Disconnect the current user and close the WebSocket.
  Future<void> disconnectUser() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    final repo = sl<ConnectionRepository>();
    await repo.disconnectUser();
  }

  /// The currently connected user, or null if not connected.
  User? get currentUser => sl<ConnectionRepository>().currentUser;

  void _wireEventHandler() {
    final ws = sl<WsClient>();
    final eventHandler = sl<EventHandler>();
    _eventSubscription?.cancel();
    _eventSubscription = ws.events.listen(
      (event) => eventHandler.handle(event),
      onError: (_) {},
    );
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await tearDownDependencies();
    _instance = null;
    _config = null;
  }
}
