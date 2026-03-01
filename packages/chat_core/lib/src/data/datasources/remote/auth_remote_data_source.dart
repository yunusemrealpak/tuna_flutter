import '../../../core/exceptions.dart';
import 'api_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> refreshToken(String refreshToken);

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _client.post(
      '/auth/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
        'display_name': displayName,
      }..removeWhere((k, v) => v == null),
    );
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from register.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from login.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _client.post(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from token refresh.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<void> logout() async {
    await _client.post('/auth/logout', body: {});
  }
}
