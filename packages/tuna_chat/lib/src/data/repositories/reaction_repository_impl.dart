import 'package:dartz/dartz.dart';

import '../../core/exceptions.dart';
import '../../core/failures.dart';
import '../../core/type_defs.dart';
import '../../domain/entities/reaction.dart';
import '../../domain/repositories/reaction_repository.dart';
import '../datasources/remote/reaction_remote_data_source.dart';

class ReactionRepositoryImpl implements ReactionRepository {
  ReactionRepositoryImpl({required ReactionRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final ReactionRemoteDataSource _remote;

  @override
  FutureEither<Reaction> addReaction(
    String channelId,
    String messageId, {
    required String type,
  }) async {
    try {
      final data =
          await _remote.addReaction(channelId, messageId, type: type);
      return Right(Reaction.fromJson(data));
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
  FutureEither<List<Reaction>> getReactions(
    String channelId,
    String messageId,
  ) async {
    try {
      final data = await _remote.getReactions(channelId, messageId);
      return Right(data.map(Reaction.fromJson).toList());
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
  FutureEither<void> removeReaction(
    String channelId,
    String messageId,
    String type,
  ) async {
    try {
      await _remote.removeReaction(channelId, messageId, type);
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
