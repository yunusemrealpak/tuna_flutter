import 'package:chat_core/src/core/exceptions.dart';
import 'package:chat_core/src/core/failures.dart';
import 'package:chat_core/src/data/datasources/local/auth_local_data_source.dart';
import 'package:chat_core/src/data/datasources/remote/auth_remote_data_source.dart';
import 'package:chat_core/src/data/repositories/auth_repository_impl.dart';
import 'package:chat_core/src/domain/entities/user.dart';
import 'package:test/test.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────

class _FakeRemote implements AuthRemoteDataSource {
  Map<String, dynamic>? registerResult;
  Map<String, dynamic>? loginResult;
  Map<String, dynamic>? refreshResult;
  Exception? throwOnRegister;
  Exception? throwOnLogin;
  Exception? throwOnLogout;
  bool logoutCalled = false;
  String? lastLogoutRefreshToken;

  @override
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (throwOnRegister != null) throw throwOnRegister!;
    return registerResult!;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (throwOnLogin != null) throw throwOnLogin!;
    return loginResult!;
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    if (refreshResult == null) throw const NetworkException(message: 'no refresh');
    return refreshResult!;
  }

  @override
  Future<void> logout(String refreshToken) async {
    lastLogoutRefreshToken = refreshToken;
    if (throwOnLogout != null) throw throwOnLogout!;
    logoutCalled = true;
  }
}

class _FakeLocal implements AuthLocalDataSource {
  User? _user;
  String? _accessToken;
  String? _refreshToken;
  String? _userId;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
  }

  @override
  Future<void> saveUserId(String userId) async => _userId = userId;

  @override
  Future<String?> getSavedUserId() async => _userId;

  @override
  Future<void> cacheUser(User user) async => _user = user;

  @override
  Future<User?> getCachedUser(String? userId) async =>
      userId == null ? null : _user;

  @override
  Future<void> clearUser(String? userId) async => _user = null;
}

// ── Helpers ───────────────────────────────────────────────────────────────

final _userJson = {
  'id': 'u1',
  'username': 'alice',
  'display_name': 'Alice',
  'avatar_url': null,
  'last_seen_at': null,
  'created_at': '2024-01-01T00:00:00.000Z',
};

Map<String, dynamic> _authResponse({
  String accessToken = 'at',
  String refreshToken = 'rt',
}) => {
      'user': _userJson,
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repo = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
  });

  group('register', () {
    test('returns user and tokens on success', () async {
      remote.registerResult = _authResponse();
      final result = await repo.register(
        username: 'alice',
        email: 'alice@example.com',
        password: 'pass',
      );
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) {
          expect(r.user.id, 'u1');
          expect(r.accessToken, 'at');
          expect(r.refreshToken, 'rt');
        },
      );
    });

    test('caches tokens and user on success', () async {
      remote.registerResult = _authResponse(accessToken: 'acc', refreshToken: 'ref');
      await repo.register(
        username: 'alice',
        email: 'a@b.com',
        password: 'pw',
      );
      expect(await local.getAccessToken(), 'acc');
      expect(await local.getRefreshToken(), 'ref');
      expect(await local.getSavedUserId(), 'u1');
      expect(await local.getCachedUser('u1'), isNotNull);
    });

    test('maps AuthException to AuthFailure', () async {
      remote.throwOnRegister = const AuthException(
        message: 'Unauthorized',
        errorCode: 'UNAUTHORIZED',
      );
      final result = await repo.register(
        username: 'x',
        email: 'x@x.com',
        password: 'pw',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<AuthFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps ServerException to ServerFailure', () async {
      remote.throwOnRegister = const ServerException(
        message: 'Server error',
        statusCode: 500,
        errorCode: 'INTERNAL',
      );
      final result = await repo.register(
        username: 'x',
        email: 'x@x.com',
        password: 'pw',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      remote.throwOnRegister = const NetworkException(message: 'No internet');
      final result = await repo.register(
        username: 'x',
        email: 'x@x.com',
        password: 'pw',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('login', () {
    test('returns user and tokens on success', () async {
      remote.loginResult = _authResponse();
      final result = await repo.login(email: 'alice@example.com', password: 'pass');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r.user.username, 'alice'),
      );
    });

    test('saves userId after login', () async {
      remote.loginResult = _authResponse();
      await repo.login(email: 'alice@example.com', password: 'pass');
      expect(await local.getSavedUserId(), 'u1');
    });

    test('maps AuthException to AuthFailure', () async {
      remote.throwOnLogin = const AuthException(
        message: 'Invalid creds',
        errorCode: 'INVALID_CREDENTIALS',
      );
      final result = await repo.login(email: 'a@b.com', password: 'bad');
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<AuthFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('refreshToken', () {
    test('saves new tokens and returns them', () async {
      remote.refreshResult = {
        'access_token': 'new_at',
        'refresh_token': 'new_rt',
      };
      final result = await repo.refreshToken(refreshToken: 'old_rt');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) {
          expect(r.accessToken, 'new_at');
          expect(r.refreshToken, 'new_rt');
        },
      );
      expect(await local.getAccessToken(), 'new_at');
    });
  });

  group('logout', () {
    test('sends refresh_token to remote and clears local state (R-M3-001)', () async {
      local._userId = 'u1';
      local._user = User(
        id: 'u1',
        username: 'alice',
        displayName: 'Alice',
        createdAt: DateTime.now(),
      );
      local._accessToken = 'at';
      local._refreshToken = 'rt';

      final result = await repo.logout();
      expect(result.isRight(), isTrue);
      expect(remote.logoutCalled, isTrue);
      // Verifies R-M3-001: refresh token is sent in the logout body.
      expect(remote.lastLogoutRefreshToken, 'rt');
      expect(await local.getCachedUser('u1'), isNull);
      expect(await local.getAccessToken(), isNull);
    });

    test('clears local state even on NetworkException', () async {
      remote.throwOnLogout = const NetworkException(message: 'offline');
      local._accessToken = 'at';
      local._refreshToken = 'rt';

      final result = await repo.logout();
      // Returns Left (NetworkFailure) but local state is cleared
      expect(result.isLeft(), isTrue);
      expect(await local.getAccessToken(), isNull);
    });
  });

  group('getCurrentUser', () {
    test('returns cached user when available (survives app restart via userId)', () async {
      local._userId = 'u1';
      final user = User(
        id: 'u1',
        username: 'alice',
        displayName: 'Alice',
        createdAt: DateTime.now(),
      );
      local._user = user;
      final result = await repo.getCurrentUser();
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('expected Right'), (r) => expect(r, user));
    });

    test('returns null when no userId saved', () async {
      final result = await repo.getCurrentUser();
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('expected Right'), (r) => expect(r, isNull));
    });
  });
}
