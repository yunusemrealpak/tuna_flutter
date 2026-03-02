import 'dart:async';

import 'package:chat_core/chat_core.dart';

import 'di/injection.dart';

/// SDK configuration.
class ChatConfig {
  const ChatConfig({
    required this.apiBaseUrl,
    required this.wsUrl,
    this.enableOfflineMode = true,
  });

  final String apiBaseUrl;
  final String wsUrl;
  final bool enableOfflineMode;
}

/// Public entry point for the Chat SDK.
///
/// Usage:
/// ```dart
/// await ChatSDK.initialize(ChatConfig(
///   apiBaseUrl: 'http://my-server/api/v1',
///   wsUrl: 'ws://my-server/api/v1/ws',
/// ));
/// // After successful login:
/// await ChatSDK.instance.connectWebSocket(accessToken);
/// ```
class ChatSDK {
  ChatSDK._();

  static ChatSDK? _instance;
  static ChatConfig? _config;
  StreamSubscription<ChatEvent>? _eventSubscription;

  static ChatSDK get instance {
    assert(_instance != null, 'Call ChatSDK.initialize() first.');
    return _instance!;
  }

  static ChatConfig get config {
    assert(_config != null, 'Call ChatSDK.initialize() first.');
    return _config!;
  }

  static Future<void> initialize(ChatConfig config) async {
    _config = config;
    await registerDependencies(config);
    _instance = ChatSDK._();
  }

  /// Connect the WebSocket and wire the [EventHandler] to the event stream.
  ///
  /// Call this after a successful login (R-M3-003). The [accessToken] is the
  /// JWT obtained from `AuthRepository.login()` or `AuthRepository.register()`.
  ///
  /// In M4, the Auth BLoC is responsible for calling this method immediately
  /// after authentication succeeds.
  Future<void> connectWebSocket(String accessToken) async {
    final ws = sl<WsClient>();
    final eventHandler = sl<EventHandler>();

    await ws.connect(accessToken);

    // Wire EventHandler to incoming WS events so that local DB is kept in sync.
    await _eventSubscription?.cancel();
    _eventSubscription = ws.events.listen(
      (event) => eventHandler.handle(event),
      onError: (_) {}, // Reconnect logic is handled inside WsClient.
    );
  }

  /// Disconnect the WebSocket and cancel the event subscription.
  Future<void> disconnectWebSocket() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await sl<WsClient>().dispose();
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await tearDownDependencies();
    _instance = null;
    _config = null;
  }
}
