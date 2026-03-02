import '../../../core/exceptions.dart';
import 'api_client.dart';

abstract class ReactionRemoteDataSource {
  Future<Map<String, dynamic>> addReaction(
    String channelId,
    String messageId, {
    required String type,
  });

  Future<List<Map<String, dynamic>>> getReactions(
    String channelId,
    String messageId,
  );

  Future<void> removeReaction(
    String channelId,
    String messageId,
    String type,
  );
}

class ReactionRemoteDataSourceImpl implements ReactionRemoteDataSource {
  ReactionRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> addReaction(
    String channelId,
    String messageId, {
    required String type,
  }) async {
    final response = await _client.post(
      '/channels/$channelId/messages/$messageId/reactions',
      body: {'type': type},
    );
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from addReaction.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<List<Map<String, dynamic>>> getReactions(
    String channelId,
    String messageId,
  ) async {
    final response = await _client.get(
      '/channels/$channelId/messages/$messageId/reactions',
    );
    final items = (response.data?['reactions'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    return items;
  }

  @override
  Future<void> removeReaction(
    String channelId,
    String messageId,
    String type,
  ) async {
    await _client.delete(
      '/channels/$channelId/messages/$messageId/reactions/$type',
    );
  }
}
