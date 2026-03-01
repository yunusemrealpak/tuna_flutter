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
/// ```
class ChatSDK {
  ChatSDK._();

  static ChatSDK? _instance;
  static ChatConfig? _config;

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

  Future<void> dispose() async {
    await tearDownDependencies();
    _instance = null;
    _config = null;
  }
}
