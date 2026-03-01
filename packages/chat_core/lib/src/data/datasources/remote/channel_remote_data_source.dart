import '../../../core/exceptions.dart';
import 'api_client.dart';

abstract class ChannelRemoteDataSource {
  Future<Map<String, dynamic>> createChannel({
    required String type,
    String? name,
    String? description,
    required List<String> memberIds,
  });

  Future<Map<String, dynamic>> getChannel(String channelId);

  Future<({List<Map<String, dynamic>> channels, String? nextCursor})> listChannels({
    String? cursor,
    int limit = 20,
  });

  Future<Map<String, dynamic>> updateChannel(
    String channelId, {
    String? name,
    String? description,
    String? avatarUrl,
  });

  Future<void> deleteChannel(String channelId);

  Future<Map<String, dynamic>> addMember(
    String channelId, {
    required String userId,
    required String role,
  });

  Future<void> removeMember(String channelId, String userId);

  Future<List<Map<String, dynamic>>> getMembers(String channelId);
}

class ChannelRemoteDataSourceImpl implements ChannelRemoteDataSource {
  ChannelRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> createChannel({
    required String type,
    String? name,
    String? description,
    required List<String> memberIds,
  }) async {
    final response = await _client.post(
      '/channels',
      body: {
        'type': type,
        'name': name,
        'description': description,
        'member_ids': memberIds,
      }..removeWhere((k, v) => v == null),
    );
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from createChannel.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> getChannel(String channelId) async {
    final response = await _client.get('/channels/$channelId');
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from getChannel.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<({List<Map<String, dynamic>> channels, String? nextCursor})> listChannels({
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'cursor': cursor ?? '',
    }..removeWhere((k, v) => v.isEmpty);
    final response = await _client.get('/channels', queryParams: params);
    final items = (response.data?['channels'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final nextCursor = response.meta?['next_cursor'] as String?;
    return (channels: items, nextCursor: nextCursor);
  }

  @override
  Future<Map<String, dynamic>> updateChannel(
    String channelId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
    }..removeWhere((k, v) => v == null);
    final response = await _client.patch('/channels/$channelId', body: body);
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from updateChannel.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<void> deleteChannel(String channelId) async {
    await _client.delete('/channels/$channelId');
  }

  @override
  Future<Map<String, dynamic>> addMember(
    String channelId, {
    required String userId,
    required String role,
  }) async {
    final response = await _client.post(
      '/channels/$channelId/members',
      body: {'user_id': userId, 'role': role},
    );
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from addMember.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<void> removeMember(String channelId, String userId) async {
    await _client.delete('/channels/$channelId/members/$userId');
  }

  @override
  Future<List<Map<String, dynamic>>> getMembers(String channelId) async {
    final response = await _client.get('/channels/$channelId/members');
    final items = (response.data?['members'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    return items;
  }
}
