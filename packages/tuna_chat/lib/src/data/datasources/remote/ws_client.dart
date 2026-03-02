import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants.dart';
import 'chat_event.dart';

/// WebSocket connection state.
enum WsConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
}

/// WebSocket client for TunaChat SDK.
///
/// Features:
/// - Connects with host-signed JWT + API key.
/// - URL format: `wsUrl?token=<jwt>&api_key=<key>`
/// - Broadcasts incoming [ChatEvent]s as a stream.
/// - Exposes a [connectionState] stream.
/// - Auto-reconnects with exponential backoff on unexpected disconnect.
/// - Sends a periodic heartbeat ping to keep the connection alive.
/// - On reconnect, sends `connection.resume` with the last received event
///   timestamp so the server can deliver missed events.
class WsClient {
  WsClient({
    required this.wsUrl,
    Duration? heartbeatInterval,
    Duration? reconnectInitialDelay,
    Duration? reconnectMaxDelay,
    int? maxReconnectAttempts,
  })  : heartbeatInterval =
            heartbeatInterval ?? ApiConstants.wsHeartbeatInterval,
        reconnectInitialDelay =
            reconnectInitialDelay ?? ApiConstants.wsReconnectInitialDelay,
        reconnectMaxDelay =
            reconnectMaxDelay ?? ApiConstants.wsReconnectMaxDelay,
        maxReconnectAttempts =
            maxReconnectAttempts ?? ApiConstants.wsReconnectMaxAttempts;

  final String wsUrl;
  final Duration heartbeatInterval;
  final Duration reconnectInitialDelay;
  final Duration reconnectMaxDelay;
  final int maxReconnectAttempts;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  final _eventController = StreamController<ChatEvent>.broadcast();
  final _stateController = StreamController<WsConnectionState>.broadcast();

  Stream<ChatEvent> get events => _eventController.stream;
  Stream<WsConnectionState> get connectionState => _stateController.stream;

  String? _token;
  String? _apiKey;
  DateTime? _lastEventAt;
  int _reconnectAttempts = 0;
  bool _disposed = false;
  WsConnectionState _currentState = WsConnectionState.disconnected;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Establish the WebSocket connection using [token] and optional [apiKey].
  ///
  /// The resulting URL is: `wsUrl?token=<token>&api_key=<apiKey>`
  Future<void> connect(String token, {String? apiKey}) async {
    if (_disposed) return;
    _token = token;
    if (apiKey != null) _apiKey = apiKey;
    _reconnectAttempts = 0;
    await _connect();
  }

  /// Send a raw event to the server.
  void send(Map<String, dynamic> event) => _sendRaw(jsonEncode(event));

  /// Update the access token (called after a token refresh).
  void updateToken(String token) => _token = token;

  /// Disconnect and clean up all resources.
  Future<void> dispose() async {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    if (!_eventController.isClosed) await _eventController.close();
    if (!_stateController.isClosed) await _stateController.close();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    if (_disposed) return;
    _setState(WsConnectionState.connecting);

    try {
      var urlStr = '$wsUrl?token=$_token';
      if (_apiKey != null) urlStr += '&api_key=$_apiKey';
      final uri = Uri.parse(urlStr);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _reconnectAttempts = 0;
      _setState(WsConnectionState.connected);

      // Resume: inform server of last received event so it can replay missed ones.
      if (_lastEventAt != null) {
        _sendRaw(jsonEncode({
          'type': WsEventType.connectionResume,
          'data': {'last_event_at': _lastEventAt!.toIso8601String()},
        }));
      }

      _startHeartbeat();

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (_) {
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final event = ChatEvent.fromJson(json);
      _lastEventAt = event.timestamp;
      _eventController.add(event);
    } catch (_) {
      // Ignore unparseable frames.
    }
  }

  void _onError(Object error) {
    _setState(WsConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _onDone() {
    if (_disposed) return;
    _setState(WsConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectAttempts >= maxReconnectAttempts) return;

    _heartbeatTimer?.cancel();
    _subscription?.cancel();

    _setState(WsConnectionState.reconnecting);

    final delay = _nextDelay();
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, _connect);
  }

  Duration _nextDelay() {
    final exponent = min(_reconnectAttempts, 5); // cap exponent to avoid overflow
    final seconds =
        reconnectInitialDelay.inSeconds * pow(2, exponent).toInt();
    return Duration(
      seconds: seconds.clamp(
        reconnectInitialDelay.inSeconds,
        reconnectMaxDelay.inSeconds,
      ),
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (_currentState == WsConnectionState.connected) {
        // Send a lightweight ping event; the server echoes nothing but keeps
        // the connection alive. nhooyr.io/websocket handles WS-level ping/pong
        // separately on the server side.
        _sendRaw(jsonEncode({
          'type': 'ping',
          'data': {'ts': DateTime.now().toUtc().toIso8601String()},
        }));
      }
    });
  }

  void _sendRaw(String encoded) {
    try {
      _channel?.sink.add(encoded);
    } catch (_) {
      // Ignore send failures — reconnect logic will handle reconnection.
    }
  }

  void _setState(WsConnectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
