import 'package:dartz/dartz.dart';

import '../../core/exceptions.dart';
import '../../core/failures.dart';
import '../../core/type_defs.dart';
import '../../domain/repositories/presence_repository.dart';
import '../datasources/remote/presence_remote_data_source.dart';
import '../datasources/remote/ws_client.dart';

class PresenceRepositoryImpl implements PresenceRepository {
  PresenceRepositoryImpl({
    required PresenceRemoteDataSource remoteDataSource,
    required WsClient wsClient,
  })  : _remote = remoteDataSource,
        _ws = wsClient;

  final PresenceRemoteDataSource _remote;
  final WsClient _ws;

  @override
  FutureEither<List<UserPresence>> getPresence(List<String> userIds) async {
    try {
      final data = await _remote.getPresence(userIds);
      return Right(data.map(UserPresence.fromJson).toList());
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
  FutureEither<void> updatePresence(PresenceStatus status) async {
    try {
      _ws.send({
        'type': 'presence.update',
        'data': {'status': status.name},
      });
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }
}
