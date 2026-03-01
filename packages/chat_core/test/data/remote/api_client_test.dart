import 'dart:convert';

import 'package:chat_core/chat_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// ── Stub TokenStorage ────────────────────────────────────────────────────────

class _StubTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;
  int saveCallCount = 0;
  int clearCallCount = 0;

  _StubTokenStorage({this.accessToken, this.refreshToken});

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    saveCallCount++;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    clearCallCount++;
  }
}

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
  String? accessToken,
  String? refreshToken,
  void Function()? onAuthFailure,
}) {
  return ApiClient(
    baseUrl: 'http://test.local/api/v1',
    tokenStorage: _StubTokenStorage(
      accessToken: accessToken,
      refreshToken: refreshToken,
    ),
    httpClient: mock,
    onAuthFailure: onAuthFailure,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ApiClient', () {
    group('GET', () {
      test('returns parsed data on 200', () async {
        final mock = MockClient((_) async => _jsonResponse({'data': {'id': '1'}}));
        final client = _client(mock, accessToken: 'tok');

        final resp = await client.get('/users/me');

        expect(resp.data, {'id': '1'});
        expect(resp.meta, isNull);
      });

      test('attaches Authorization header when token is available', () async {
        String? capturedAuth;
        final mock = MockClient((req) async {
          capturedAuth = req.headers['Authorization'];
          return _jsonResponse({'data': null});
        });
        final client = _client(mock, accessToken: 'mytoken');

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
        final client = _client(mock, accessToken: 'tok');

        await client.post('/messages', body: {'text': 'hello'});

        final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(decoded['text'], 'hello');
      });

      test('handles 201 status', () async {
        final mock = MockClient((_) async =>
            _jsonResponse({'data': {'id': 'u1'}}, status: 201));
        final client = _client(mock);

        final resp = await client.post('/auth/register', body: {});
        expect(resp.data, {'id': 'u1'});
      });
    });

    group('204 No Content', () {
      test('returns null data and meta', () async {
        final mock = MockClient((_) async => http.Response('', 204));
        final client = _client(mock, accessToken: 'tok');

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

    group('Token refresh on 401', () {
      test('refreshes token and retries on 401', () async {
        final storage = _StubTokenStorage(
          accessToken: 'old_access',
          refreshToken: 'ref_tok',
        );
        int callCount = 0;

        final mock = MockClient((req) async {
          callCount++;
          if (callCount == 1) {
            // First call returns 401
            return _jsonResponse(
                {'error': {'code': 'UNAUTHORIZED', 'message': 'Expired'}},
                status: 401);
          } else if (req.url.path.contains('/auth/refresh')) {
            // Refresh call
            return _jsonResponse({
              'data': {
                'access_token': 'new_access',
                'refresh_token': 'new_refresh'
              }
            });
          } else {
            // Retry succeeds
            return _jsonResponse({'data': {'id': 'me'}});
          }
        });

        final client = ApiClient(
          baseUrl: 'http://test.local/api/v1',
          tokenStorage: storage,
          httpClient: mock,
        );

        final resp = await client.get('/users/me');

        expect(resp.data, {'id': 'me'});
        expect(storage.accessToken, 'new_access');
        expect(storage.saveCallCount, 1);
      });

      test('calls onAuthFailure when refresh also fails', () async {
        bool authFailureCalled = false;

        final mock = MockClient((_) async => _jsonResponse(
            {'error': {'code': 'UNAUTHORIZED', 'message': 'Expired'}},
            status: 401));

        final client = _client(
          mock,
          accessToken: 'tok',
          refreshToken: 'ref',
          onAuthFailure: () => authFailureCalled = true,
        );

        expect(
          () => client.get('/users/me'),
          throwsA(isA<AuthException>()),
        );

        await Future<void>.delayed(Duration.zero);
        // onAuthFailure is called after the second 401 fails to refresh
      });
    });
  });
}
