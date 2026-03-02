import '../../../core/exceptions.dart';
import 'api_client.dart';

abstract class UserRemoteDataSource {
  Future<Map<String, dynamic>> getMe();

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? avatarUrl,
  });

  Future<Map<String, dynamic>> getUser(String userId);

  Future<List<Map<String, dynamic>>> searchUsers(String query);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get('/users/me');
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from getMe.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{
      'display_name': displayName,
      'avatar_url': avatarUrl,
    }..removeWhere((_, v) => v == null);
    final response = await _client.patch('/users/me', body: body);
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from updateProfile.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> getUser(String userId) async {
    final response = await _client.get('/users/$userId');
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from getUser.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await _client.get(
      '/users',
      queryParams: {'search': query},
    );
    final data = response.data;
    if (data == null) return [];
    final users = data['users'] as List?;
    return users?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }
}
