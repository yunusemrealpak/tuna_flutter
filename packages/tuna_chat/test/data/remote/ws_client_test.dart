import 'package:tuna_chat/tuna_chat.dart';
import 'package:test/test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns a channel factory that records every URI it is called with and
/// throws immediately so that WsClient enters the reconnect path.
WsChannelFactory _recordingFactory(List<Uri> out) {
  return (Uri uri) {
    out.add(uri);
    throw Exception('Test: connection refused');
  };
}

/// A minimal WsClient wired for fast reconnect tests.
/// [maxAttempts] controls how many reconnect cycles fire.
WsClient _fastClient({
  required WsChannelFactory factory,
  Future<String?> Function()? tokenProvider,
  int maxAttempts = 0,
}) {
  return WsClient(
    wsUrl: 'ws://test.local/ws',
    channelFactory: factory,
    tokenProvider: tokenProvider,
    // Using sub-second Duration makes _nextDelay() return Duration.zero
    // (inSeconds == 0), so reconnect fires on the next event-loop turn.
    reconnectInitialDelay: const Duration(milliseconds: 1),
    reconnectMaxDelay: const Duration(milliseconds: 1),
    maxReconnectAttempts: maxAttempts,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('WsClient', () {
    group('URL construction', () {
      test('includes token and api_key in the WebSocket URL', () async {
        final uris = <Uri>[];
        final client = _fastClient(factory: _recordingFactory(uris));

        await client.connect('my-jwt', apiKey: 'tuna_key_test');

        expect(uris, hasLength(1));
        expect(uris.single.queryParameters['token'], 'my-jwt');
        expect(uris.single.queryParameters['api_key'], 'tuna_key_test');

        await client.dispose();
      });

      test('omits api_key from URL when not provided', () async {
        final uris = <Uri>[];
        final client = _fastClient(factory: _recordingFactory(uris));

        await client.connect('my-jwt');

        expect(uris.single.queryParameters.containsKey('api_key'), isFalse);

        await client.dispose();
      });
    });

    group('tokenProvider on reconnect', () {
      test('invokes tokenProvider before reconnect and uses the new token',
          () async {
        final tokens = <String>[];
        bool providerCalled = false;

        final client = _fastClient(
          factory: (uri) {
            tokens.add(uri.queryParameters['token']!);
            throw Exception('refused');
          },
          tokenProvider: () async {
            providerCalled = true;
            return 'refreshed-token';
          },
          maxAttempts: 1,
        );

        await client.connect('initial-token');
        // Allow the reconnect timer (Duration.zero) to fire and complete.
        await Future.delayed(const Duration(milliseconds: 50));

        expect(providerCalled, isTrue);
        expect(tokens.first, 'initial-token');
        expect(tokens.last, 'refreshed-token');

        await client.dispose();
      });

      test('uses cached token on reconnect when tokenProvider is null',
          () async {
        final tokens = <String>[];

        final client = _fastClient(
          factory: (uri) {
            tokens.add(uri.queryParameters['token']!);
            throw Exception('refused');
          },
          maxAttempts: 1,
        );

        await client.connect('stable-token');
        await Future.delayed(const Duration(milliseconds: 50));

        expect(tokens.first, 'stable-token');
        expect(tokens.last, 'stable-token');

        await client.dispose();
      });

      test('falls back to cached token when tokenProvider throws', () async {
        final tokens = <String>[];

        final client = _fastClient(
          factory: (uri) {
            tokens.add(uri.queryParameters['token']!);
            throw Exception('refused');
          },
          tokenProvider: () async => throw Exception('refresh service down'),
          maxAttempts: 1,
        );

        await client.connect('original-token');
        await Future.delayed(const Duration(milliseconds: 50));

        expect(tokens.last, 'original-token');

        await client.dispose();
      });

      test('falls back to cached token when tokenProvider returns null',
          () async {
        final tokens = <String>[];

        final client = _fastClient(
          factory: (uri) {
            tokens.add(uri.queryParameters['token']!);
            throw Exception('refused');
          },
          tokenProvider: () async => null,
          maxAttempts: 1,
        );

        await client.connect('original-token');
        await Future.delayed(const Duration(milliseconds: 50));

        expect(tokens.last, 'original-token');

        await client.dispose();
      });
    });

    group('reconnect limits', () {
      test('stops reconnecting after maxReconnectAttempts', () async {
        int factoryCalls = 0;

        final client = WsClient(
          wsUrl: 'ws://test.local/ws',
          channelFactory: (uri) {
            factoryCalls++;
            throw Exception('refused');
          },
          reconnectInitialDelay: const Duration(milliseconds: 1),
          reconnectMaxDelay: const Duration(milliseconds: 1),
          maxReconnectAttempts: 2,
        );

        await client.connect('token');
        // Allow time for both reconnect cycles.
        await Future.delayed(const Duration(milliseconds: 100));

        // 1 initial attempt + 2 reconnects = 3 total factory calls.
        expect(factoryCalls, 3);

        await client.dispose();
      });

      test('dispose cancels pending reconnect timer', () async {
        int factoryCalls = 0;

        final client = WsClient(
          wsUrl: 'ws://test.local/ws',
          channelFactory: (uri) {
            factoryCalls++;
            throw Exception('refused');
          },
          reconnectInitialDelay: const Duration(milliseconds: 1),
          reconnectMaxDelay: const Duration(milliseconds: 1),
          maxReconnectAttempts: 5,
        );

        await client.connect('token');
        // Dispose before the reconnect timer fires.
        await client.dispose();

        await Future.delayed(const Duration(milliseconds: 100));

        // Only the initial attempt — no reconnects after dispose.
        expect(factoryCalls, 1);
      });
    });

    group('updateToken', () {
      test('connect() overrides any prior updateToken call', () async {
        String? lastToken;

        final client = _fastClient(
          factory: (uri) {
            lastToken = uri.queryParameters['token'];
            throw Exception('refused');
          },
        );

        client.updateToken('update-token');
        await client.connect('connect-token');

        // connect() resets the token with its own argument.
        expect(lastToken, 'connect-token');

        await client.dispose();
      });
    });
  });
}
