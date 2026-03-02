import 'dart:convert';

import 'package:tuna_chat/src/data/datasources/local/app_database.dart';
import 'package:tuna_chat/src/data/sync/sync_engine.dart';
import 'package:tuna_chat/src/data/datasources/remote/api_client.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

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
      apiKey: 'tuna_key_test',
      token: 'access-token',
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
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final events = await db.pendingEventDao.findAll();
      expect(events, isEmpty);
      expect(httpClient.requests, isNotEmpty);
      expect(httpClient.requests.first.url.path,
          contains('/channels/c1/messages'));
    });

    test('sends X-Idempotency-Key header', () async {
      httpClient.handler = (_) => http.Response(
            jsonEncode({'data': {'id': 'm1'}}),
            200,
          );

      await engine.enqueue(
        eventType: 'message.send',
        payload: {
          'channel_id': 'c1',
          'text': 'Hello',
          'idempotency_key': 'idem-key-42',
        },
      );

      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(httpClient.requests, isNotEmpty);
      final headers = httpClient.requests.first.headers;
      expect(headers['X-Idempotency-Key'], 'idem-key-42');
      expect(headers.containsKey('Idempotency-Key'), isFalse);
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
      expect(events.length, 1);
      expect(events.first.retryCount, greaterThan(0));
    });

    test('discards events that exceed max retries', () async {
      await db.pendingEventDao.insert(
        PendingEventsTableCompanion.insert(
          eventType: 'message.send',
          payload: jsonEncode({'channel_id': 'c1', 'text': 'X'}),
          createdAt: DateTime.now().toUtc(),
          retryCount: const Value(5),
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
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final events = await db.pendingEventDao.findAll();
      expect(events.length, 1);
    });
  });
}
