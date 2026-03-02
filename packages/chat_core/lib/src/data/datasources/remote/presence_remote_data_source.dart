import 'api_client.dart';

abstract class PresenceRemoteDataSource {
  Future<List<Map<String, dynamic>>> getPresence(List<String> userIds);
}

class PresenceRemoteDataSourceImpl implements PresenceRemoteDataSource {
  PresenceRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> getPresence(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final response = await _client.get(
      '/users/presence',
      queryParams: {'user_ids': userIds.join(',')},
    );
    final data = response.data;
    if (data == null) return [];
    final presences = data['presences'] as List?;
    return presences?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }
}
