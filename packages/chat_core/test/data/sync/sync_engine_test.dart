import 'dart:convert';

import 'package:chat_core/src/data/datasources/local/app_database.dart';
import 'package:chat_core/src/data/sync/sync_engine.dart';
import 'package:chat_core/src/data/datasources/remote/api_client.dart';
import 'package:chat_core/src/data/datasources/remote/token_storage.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

// ── Fake token storage ────────────────────────────────────────────────────

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';
  @override
  Future<String?> getRefreshToken() async => 'refresh-token';
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
  @override
  Future<void> clearTokens() async {}
}

// ── Fake http client ──────────────────────────────────────────────────────

class _TrackingClient extends http.BaseClient {
  final List<http.Request> requests = [];
  http.Response Function(http.Request)? handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final r = request as http.Request;
    requests.add(r);
    final response = handler?.call(r) ??
        http.Response('{"data":{"id":"m1"}}', 200);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late _TrackingClient httpClient;
  late ApiClient apiClient;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    httpClient = _TrackingClient();
    apiClient = ApiClient(
      baseUrl: 'http://localhost:8080',
      tokenStorage: _FakeTokenStorage(),
      httpClient: httpClient,
    );
    engine = SyncEngine(database: db, apiClient: apiClient);
  });

  tearDown(() async {
    engine.stop();
    await db.close();
    apiClient.dispose();
  });

  group('enqueue', () {
    test('inserts event into pending_events table', () async {
      await engine.enqueue(
        eventType: 'message.send',
        payload: {'channel_id': 'c1', 'text': 'Hello'},
      );
      final events = await db.pendingEventDao.findAll();
      expect(events.length, 1);
      expect(events.first.eventType, 'message.send');
      final payload = jsonDecode(events.first.payload) as Map<String, dynamic>;
      expect(payload['text'], 'Hello');
    });
  });

  group('start / processAll', () {
    test('processes message.send and removes from pending_events on success',
        () async {
      httpClient.handler = (_) => http.Response(
            jsonEncode({'data': {'id': 'm1', 'text': 'Hi'}}),
            200,
          );

      await engine.enqueue(
        eventType: 'message.send',
        payload: {
          'channel_id': 'c1',
          'text': 'Hi',
          'idempotency_key': 'key-1',
        },
      );

      engine.start();
      // Allow async processing
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final events = await db.pendingEventDao.findAll();
      expect(events, isEmpty);
      expect(httpClient.requests, isNotEmpty);
      expect(httpClient.requests.first.url.path,
          contains('/channels/c1/messages'));
    });

    test('increments retry count on failure and keeps event', () async {
      httpClient.handler = (_) => http.Response(
            jsonEncode({
              'error': {'code': 'SERVER_ERR', 'message': 'fail'}
            }),
            500,
          );

      await engine.enqueue(
        eventType: 'message.send',
        payload: {'channel_id': 'c1', 'text': 'Hi'},
      );

      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final events = await db.pendingEventDao.findAll();
      // Event should still exist (retry count incremented)
      expect(events.length, 1);
      expect(events.first.retryCount, greaterThan(0));
    });

    test('discards events that exceed max retries', () async {
      // Insert event with retryCount already at max
      await db.pendingEventDao.insert(
        PendingEventsTableCompanion.insert(
          eventType: 'message.send',
          payload: jsonEncode({'channel_id': 'c1', 'text': 'X'}),
          createdAt: DateTime.now().toUtc(),
          retryCount: const Value(5), // _kMaxRetries = 5
        ),
      );

      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final events = await db.pendingEventDao.findAll();
      expect(events, isEmpty);
    });

    test('discards events with unknown event type', () async {
      await engine.enqueue(
        eventType: 'unknown.type',
        payload: {'data': 'x'},
      );

      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Unknown types are dispatched but cause no HTTP call, and since
      // _dispatchEvent does not throw, the event is deleted.
      final events = await db.pendingEventDao.findAll();
      expect(events, isEmpty);
    });
  });

  group('stop', () {
    test('prevents processing after stop is called', () async {
      engine.stop();
      await engine.enqueue(
        eventType: 'message.send',
        payload: {'channel_id': 'c1', 'text': 'Hello'},
      );
      // Engine stopped; event should remain in queue
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final events = await db.pendingEventDao.findAll();
      expect(events.length, 1);
    });
  });
}
