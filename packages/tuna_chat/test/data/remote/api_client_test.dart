import 'dart:convert';

import 'package:tuna_chat/tuna_chat.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

http.Response _jsonResponse(
  Map<String, dynamic> body, {
  int status = 200,
}) =>
    http.Response(jsonEncode(body), status, headers: {
      'content-type': 'application/json',
    });

ApiClient _client(
  MockClient mock, {
  String? token,
  Future<String?> Function()? tokenProvider,
  void Function()? onAuthFailure,
}) {
  final client = ApiClient(
    baseUrl: 'http://test.local/api/v1',
    apiKey: 'tuna_key_test',
    tokenProvider: tokenProvider,
    httpClient: mock,
    onAuthFailure: onAuthFailure,
  );
  if (token != null) client.setToken(token);
  return client;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ApiClient', () {
    group('GET', () {
      test('returns parsed data on 200', () async {
        final mock = MockClient((_) async => _jsonResponse({'data': {'id': '1'}}));
        final client = _client(mock, token: 'tok');

        final resp = await client.get('/users/me');

        expect(resp.data, {'id': '1'});
        expect(resp.meta, isNull);
      });

      test('attaches X-API-Key header', () async {
        String? capturedApiKey;
        final mock = MockClient((req) async {
          capturedApiKey = req.headers['X-API-Key'];
          return _jsonResponse({'data': null});
        });
        final client = _client(mock, token: 'tok');

        await client.get('/test');

        expect(capturedApiKey, 'tuna_key_test');
      });

      test('attaches Authorization header when token is set', () async {
        String? capturedAuth;
        final mock = MockClient((req) async {
          capturedAuth = req.headers['Authorization'];
          return _jsonResponse({'data': null});
        });
        final client = _client(mock, token: 'mytoken');

        await client.get('/test');

        expect(capturedAuth, 'Bearer mytoken');
      });

      test('omits Authorization header when no token', () async {
        String? capturedAuth;
        final mock = MockClient((req) async {
          capturedAuth = req.headers['Authorization'];
          return _jsonResponse({'data': null});
        });
        final client = _client(mock);

        await client.get('/test');

        expect(capturedAuth, isNull);
      });

      test('appends query params to URI', () async {
        Uri? capturedUri;
        final mock = MockClient((req) async {
          capturedUri = req.url;
          return _jsonResponse({'data': null});
        });
        final client = _client(mock);

        await client.get('/users', queryParams: {'search': 'alice'});

        expect(capturedUri?.queryParameters['search'], 'alice');
      });

      test('includes meta when present', () async {
        final mock = MockClient((_) async => _jsonResponse({
              'data': {'channels': []},
              'meta': {'next_cursor': 'abc'},
            }));
        final client = _client(mock);

        final resp = await client.get('/channels');

        expect(resp.meta?['next_cursor'], 'abc');
      });
    });

    group('POST', () {
      test('sends JSON body', () async {
        String? capturedBody;
        final mock = MockClient((req) async {
          capturedBody = req.body;
          return _jsonResponse({'data': {'id': 'msg1'}}, status: 201);
        });
        final client = _client(mock, token: 'tok');

        await client.post('/messages', body: {'text': 'hello'});

        final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(decoded['text'], 'hello');
      });

      test('handles 201 status', () async {
        final mock = MockClient((_) async =>
            _jsonResponse({'data': {'id': 'u1'}}, status: 201));
        final client = _client(mock);

        final resp = await client.post('/channels', body: {});
        expect(resp.data, {'id': 'u1'});
      });
    });

    group('204 No Content', () {
      test('returns null data and meta', () async {
        final mock = MockClient((_) async => http.Response('', 204));
        final client = _client(mock, token: 'tok');

        final resp = await client.delete('/channels/ch1');

        expect(resp.data, isNull);
        expect(resp.meta, isNull);
      });
    });

    group('Error handling', () {
      test('throws ServerException on 404', () async {
        final mock = MockClient((_) async => _jsonResponse({
              'error': {
                'code': 'NOT_FOUND',
                'message': 'Channel not found',
              }
            }, status: 404));
        final client = _client(mock);

        expect(
          () => client.get('/channels/nonexistent'),
          throwsA(
            isA<ServerException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.errorCode, 'errorCode', 'NOT_FOUND'),
          ),
        );
      });

      test('throws ServerException on 500', () async {
        final mock = MockClient((_) async => _jsonResponse({
              'error': {'code': 'INTERNAL_ERROR', 'message': 'Server error'}
            }, status: 500));
        final client = _client(mock);

        expect(
          () => client.get('/broken'),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on client exception', () async {
        final mock = MockClient((_) async => throw http.ClientException('Connection refused'));
        final client = _client(mock);

        expect(
          () => client.get('/test'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('setToken / clearToken', () {
      test('setToken updates Authorization header', () async {
        String? capturedAuth;
        final mock = MockClient((req) async {
          capturedAuth = req.headers['Authorization'];
          return _jsonResponse({'data': null});
        });
        final client = _client(mock);

        client.setToken('my-jwt');
        await client.get('/test');

        expect(capturedAuth, 'Bearer my-jwt');
      });

      test('clearToken removes Authorization header', () async {
        String? capturedAuth = 'sentinel';
        final mock = MockClient((req) async {
          capturedAuth = req.headers['Authorization'];
          return _jsonResponse({'data': null});
        });
        final client = _client(mock, token: 'some-token');

        client.clearToken();
        await client.get('/test');

        expect(capturedAuth, isNull);
      });
    });

    group('tokenProvider on 401', () {
      test('calls tokenProvider and retries on 401', () async {
        int callCount = 0;
        bool providerCalled = false;

        final mock = MockClient((req) async {
          callCount++;
          if (callCount == 1) {
            return _jsonResponse(
                {'error': {'code': 'UNAUTHORIZED', 'message': 'Expired'}},
                status: 401);
          }
          return _jsonResponse({'data': {'id': 'me'}});
        });

        final client = _client(
          mock,
          token: 'old_token',
          tokenProvider: () async {
            providerCalled = true;
            return 'new_token';
          },
        );

        final resp = await client.get('/users/me');

        expect(resp.data, {'id': 'me'});
        expect(providerCalled, isTrue);
        expect(client.token, 'new_token');
        expect(callCount, 2);
      });

      test('calls onAuthFailure when tokenProvider returns null', () async {
        bool authFailureCalled = false;

        final mock = MockClient((_) async => _jsonResponse(
            {'error': {'code': 'UNAUTHORIZED', 'message': 'Expired'}},
            status: 401));

        final client = _client(
          mock,
          token: 'tok',
          tokenProvider: () async => null,
          onAuthFailure: () => authFailureCalled = true,
        );

        await expectLater(
          () => client.get('/users/me'),
          throwsA(isA<AuthException>()),
        );

        expect(authFailureCalled, isTrue);
      });

      test('calls onAuthFailure when no tokenProvider', () async {
        bool authFailureCalled = false;

        final mock = MockClient((_) async => _jsonResponse(
            {'error': {'code': 'UNAUTHORIZED', 'message': 'Expired'}},
            status: 401));

        final client = _client(
          mock,
          token: 'tok',
          onAuthFailure: () => authFailureCalled = true,
        );

        await expectLater(
          () => client.get('/users/me'),
          throwsA(isA<AuthException>()),
        );

        expect(authFailureCalled, isTrue);
      });
    });
  });
}
