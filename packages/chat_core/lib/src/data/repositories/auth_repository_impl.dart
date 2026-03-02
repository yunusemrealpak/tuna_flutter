import 'package:dartz/dartz.dart';

import '../../core/exceptions.dart';
import '../../core/failures.dart';
import '../../core/type_defs.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_data_source.dart';
import '../datasources/remote/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  FutureEither<({User user, String accessToken, String refreshToken})> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final data = await _remote.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      await _local.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _local.saveUserId(user.id);
      await _local.cacheUser(user);
      return Right((user: user, accessToken: accessToken, refreshToken: refreshToken));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<({User user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _remote.login(email: email, password: password);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      await _local.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _local.saveUserId(user.id);
      await _local.cacheUser(user);
      return Right((user: user, accessToken: accessToken, refreshToken: refreshToken));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<({String accessToken, String refreshToken})> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final data = await _remote.refreshToken(refreshToken);
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;
      await _local.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return Right((accessToken: newAccessToken, refreshToken: newRefreshToken));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<void> logout() async {
    // Fetch tokens before clearing so we can send refresh_token for revocation.
    final refreshToken = await _local.getRefreshToken() ?? '';
    final userId = await _local.getSavedUserId();
    try {
      await _remote.logout(refreshToken);
      await _local.clearTokens();
      await _local.clearUser(userId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      // Clear local state even if network fails — best-effort logout.
      await _local.clearTokens();
      await _local.clearUser(userId);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<User?> getCurrentUser() async {
    try {
      final userId = await _local.getSavedUserId();
      final user = await _local.getCachedUser(userId);
      return Right(user);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
