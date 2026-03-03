import 'package:dartz/dartz.dart';

import '../../core/exceptions.dart';
import '../../core/failures.dart';
import '../../core/type_defs.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/remote/device_remote_data_source.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({required DeviceRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final DeviceRemoteDataSource _remote;

  @override
  FutureEither<void> registerToken({
    required String token,
    required String platform,
    required String pushProvider,
  }) async {
    try {
      await _remote.registerToken(
        token: token,
        platform: platform,
        pushProvider: pushProvider,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<void> deregisterToken(String token) async {
    try {
      await _remote.deregisterToken(token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }
}
