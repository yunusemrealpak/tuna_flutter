import 'package:dartz/dartz.dart';

import '../../core/exceptions.dart';
import '../../core/failures.dart';
import '../../core/type_defs.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/connection_repository.dart';
import '../datasources/remote/api_client.dart';
import '../datasources/remote/user_remote_data_source.dart';
import '../datasources/remote/ws_client.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  ConnectionRepositoryImpl({
    required ApiClient apiClient,
    required WsClient wsClient,
    required UserRemoteDataSource userRemoteDataSource,
  })  : _apiClient = apiClient,
        _wsClient = wsClient,
        _userRemoteDataSource = userRemoteDataSource;

  final ApiClient _apiClient;
  final WsClient _wsClient;
  final UserRemoteDataSource _userRemoteDataSource;

  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  FutureEither<User> connectUser({
    required String userId,
    required String token,
  }) async {
    try {
      // Set token so all subsequent API requests carry Authorization header.
      _apiClient.setToken(token);

      // Fetch current user profile to verify the token is valid.
      final data = await _userRemoteDataSource.getMe();
      final user = User.fromJson(data['user'] as Map<String, dynamic>? ?? data);
      _currentUser = user;

      // Establish WebSocket connection.
      await _wsClient.connect(token, apiKey: _apiClient.apiKey);

      return Right(user);
    } on AuthException catch (e) {
      _apiClient.clearToken();
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } on ServerException catch (e) {
      _apiClient.clearToken();
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      _apiClient.clearToken();
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      _apiClient.clearToken();
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<void> disconnectUser() async {
    try {
      _apiClient.clearToken();
      _currentUser = null;
      await _wsClient.dispose();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }
}
