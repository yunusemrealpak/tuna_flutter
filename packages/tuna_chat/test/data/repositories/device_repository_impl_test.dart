import 'package:tuna_chat/src/core/exceptions.dart';
import 'package:tuna_chat/src/core/failures.dart';
import 'package:tuna_chat/src/data/datasources/remote/device_remote_data_source.dart';
import 'package:tuna_chat/src/data/repositories/device_repository_impl.dart';
import 'package:test/test.dart';

// ── Fake remote ───────────────────────────────────────────────────────────

class _FakeRemote implements DeviceRemoteDataSource {
  String? lastRegisteredToken;
  String? lastRegisteredPlatform;
  String? lastRegisteredProvider;
  String? lastDeregisteredToken;

  Exception? throwOnRegister;
  Exception? throwOnDeregister;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
    required String pushProvider,
  }) async {
    if (throwOnRegister != null) throw throwOnRegister!;
    lastRegisteredToken = token;
    lastRegisteredPlatform = platform;
    lastRegisteredProvider = pushProvider;
  }

  @override
  Future<void> deregisterToken(String token) async {
    if (throwOnDeregister != null) throw throwOnDeregister!;
    lastDeregisteredToken = token;
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late _FakeRemote remote;
  late DeviceRepositoryImpl repo;

  setUp(() {
    remote = _FakeRemote();
    repo = DeviceRepositoryImpl(remoteDataSource: remote);
  });

  group('registerToken', () {
    test('returns Right(null) on success', () async {
      final result = await repo.registerToken(
        token: 'fcm-abc123',
        platform: 'android',
        pushProvider: 'fcm',
      );
      expect(result.isRight(), isTrue);
    });

    test('passes correct fields to remote', () async {
      await repo.registerToken(
        token: 'tok-xyz',
        platform: 'ios',
        pushProvider: 'apns',
      );
      expect(remote.lastRegisteredToken, 'tok-xyz');
      expect(remote.lastRegisteredPlatform, 'ios');
      expect(remote.lastRegisteredProvider, 'apns');
    });

    test('maps ServerException to ServerFailure', () async {
      remote.throwOnRegister = const ServerException(
        message: 'bad request',
        statusCode: 400,
        errorCode: 'VALIDATION_ERROR',
      );
      final result = await repo.registerToken(
        token: 'tok',
        platform: 'android',
        pushProvider: 'fcm',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      remote.throwOnRegister = const NetworkException(message: 'no network');
      final result = await repo.registerToken(
        token: 'tok',
        platform: 'android',
        pushProvider: 'fcm',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps AuthException to AuthFailure', () async {
      remote.throwOnRegister = const AuthException(
        message: 'unauthorized',
        errorCode: 'UNAUTHORIZED',
      );
      final result = await repo.registerToken(
        token: 'tok',
        platform: 'android',
        pushProvider: 'fcm',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<AuthFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('deregisterToken', () {
    test('returns Right(null) on success', () async {
      final result = await repo.deregisterToken('fcm-abc123');
      expect(result.isRight(), isTrue);
    });

    test('passes correct token to remote', () async {
      await repo.deregisterToken('tok-to-remove');
      expect(remote.lastDeregisteredToken, 'tok-to-remove');
    });

    test('maps ServerException to ServerFailure', () async {
      remote.throwOnDeregister = const ServerException(
        message: 'not found',
        statusCode: 404,
        errorCode: 'NOT_FOUND',
      );
      final result = await repo.deregisterToken('bad-tok');
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      remote.throwOnDeregister = const NetworkException(message: 'offline');
      final result = await repo.deregisterToken('tok');
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });
}
