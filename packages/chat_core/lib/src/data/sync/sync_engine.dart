import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../datasources/local/app_database.dart';
import '../datasources/local/tables/pending_events_table.dart';
import '../datasources/remote/api_client.dart';

/// Maximum number of retry attempts before a pending event is discarded.
const int _kMaxRetries = 5;

/// Initial delay for the first retry (exponential backoff base).
const Duration _kInitialDelay = Duration(seconds: 2);

/// Maximum backoff delay.
const Duration _kMaxDelay = Duration(minutes: 2);

/// The SyncEngine processes the [PendingEventsTable] and retries failed
/// operations (e.g. messages sent while offline) once the network is available.
///
/// Retry strategy: exponential backoff — delay = initial * 2^retryCount,
/// capped at [_kMaxDelay].
class SyncEngine {
  SyncEngine({
    required AppDatabase database,
    required ApiClient apiClient,
  })  : _db = database,
        _api = apiClient;

  final AppDatabase _db;
  final ApiClient _api;

  bool _running = false;
  Timer? _retryTimer;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Start processing pending events. Safe to call multiple times.
  void start() {
    if (_running) return;
    _running = true;
    unawaited(_processAll());
  }

  /// Stop the engine and cancel any pending timers.
  void stop() {
    _running = false;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Enqueue a new pending event to be synced later.
  Future<void> enqueue({
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    await _db.pendingEventDao.insert(
      PendingEventsTableCompanion.insert(
        eventType: eventType,
        payload: jsonEncode(payload),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _processAll() async {
    if (!_running) return;

    final events = await _db.pendingEventDao.findAll();
    for (final event in events) {
      if (!_running) return;
      await _processEvent(event);
    }
  }

  Future<void> _processEvent(PendingEventRow event) async {
    if (event.retryCount >= _kMaxRetries) {
      // Give up — remove the event to avoid blocking the queue indefinitely.
      await _db.pendingEventDao.deleteById(event.id);
      return;
    }

    try {
      final payload = jsonDecode(event.payload) as Map<String, dynamic>;
      await _dispatchEvent(event.eventType, payload);
      await _db.pendingEventDao.deleteById(event.id);
    } catch (_) {
      // Increment retry count and schedule next attempt with backoff.
      await _db.pendingEventDao.incrementRetry(event.id);
      _scheduleRetry(event.retryCount + 1);
    }
  }

  Future<void> _dispatchEvent(
    String eventType,
    Map<String, dynamic> payload,
  ) async {
    switch (eventType) {
      case 'message.send':
        final channelId = payload['channel_id'] as String;
        final body = <String, dynamic>{
          'text': payload['text'] as String,
          if (payload['parent_id'] != null) 'parent_id': payload['parent_id'],
        };
        final headers = payload['idempotency_key'] != null
            ? {'X-Idempotency-Key': payload['idempotency_key'] as String}
            : null;
        await _api.post(
          '/channels/$channelId/messages',
          body: body,
          headers: headers,
        );
        break;

      case 'message.edit':
        final channelId = payload['channel_id'] as String;
        final messageId = payload['message_id'] as String;
        await _api.patch(
          '/channels/$channelId/messages/$messageId',
          body: {'text': payload['text'] as String},
        );
        break;

      case 'message.delete':
        final channelId = payload['channel_id'] as String;
        final messageId = payload['message_id'] as String;
        await _api.delete('/channels/$channelId/messages/$messageId');
        break;

      default:
        // Unknown event type — discard to prevent queue clogging.
        break;
    }
  }

  void _scheduleRetry(int retryCount) {
    if (!_running) return;
    final exponent = min(retryCount, 6);
    final delaySeconds = (_kInitialDelay.inSeconds * pow(2, exponent).toInt())
        .clamp(
          _kInitialDelay.inSeconds,
          _kMaxDelay.inSeconds,
        );
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), _processAll);
  }
}
