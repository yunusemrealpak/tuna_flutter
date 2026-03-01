import '../../../core/exceptions.dart';
import 'api_client.dart';

abstract class MessageRemoteDataSource {
  Future<Map<String, dynamic>> sendMessage(
    String channelId, {
    required String text,
    String? parentId,
    String? idempotencyKey,
  });

  Future<({List<Map<String, dynamic>> messages, String? nextCursor})> getMessages(
    String channelId, {
    String? cursor,
    int limit = 50,
    String direction = 'before',
  });

  Future<Map<String, dynamic>> updateMessage(
    String channelId,
    String messageId, {
    required String text,
  });

  Future<void> deleteMessage(String channelId, String messageId);

  Future<({List<Map<String, dynamic>> messages, String? nextCursor})> getThreadMessages(
    String channelId,
    String parentId, {
    String? cursor,
    int limit = 50,
  });
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  MessageRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> sendMessage(
    String channelId, {
    required String text,
    String? parentId,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'text': text,
      'parent_id': parentId,
    }..removeWhere((k, v) => v == null);
    final headers = <String, String>{
      'Idempotency-Key': idempotencyKey ?? '',
    }..removeWhere((k, v) => v.isEmpty);
    final response = await _client.post(
      '/channels/$channelId/messages',
      body: body,
      headers: headers.isEmpty ? null : headers,
    );
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from sendMessage.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<({List<Map<String, dynamic>> messages, String? nextCursor})> getMessages(
    String channelId, {
    String? cursor,
    int limit = 50,
    String direction = 'before',
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'direction': direction,
      'cursor': cursor ?? '',
    }..removeWhere((k, v) => v.isEmpty);
    final response = await _client.get(
      '/channels/$channelId/messages',
      queryParams: params,
    );
    final items = (response.data?['messages'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final nextCursor = response.meta?['next_cursor'] as String?;
    return (messages: items, nextCursor: nextCursor);
  }

  @override
  Future<Map<String, dynamic>> updateMessage(
    String channelId,
    String messageId, {
    required String text,
  }) async {
    final response = await _client.patch(
      '/channels/$channelId/messages/$messageId',
      body: {'text': text},
    );
    final data = response.data;
    if (data == null) {
      throw const ServerException(
        message: 'Empty response from updateMessage.',
        statusCode: 200,
        errorCode: 'EMPTY_RESPONSE',
      );
    }
    return data;
  }

  @override
  Future<void> deleteMessage(String channelId, String messageId) async {
    await _client.delete('/channels/$channelId/messages/$messageId');
  }

  @override
  Future<({List<Map<String, dynamic>> messages, String? nextCursor})> getThreadMessages(
    String channelId,
    String parentId, {
    String? cursor,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'cursor': cursor ?? '',
    }..removeWhere((k, v) => v.isEmpty);
    final response = await _client.get(
      '/channels/$channelId/messages/$parentId/thread',
      queryParams: params,
    );
    final items = (response.data?['messages'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final nextCursor = response.meta?['next_cursor'] as String?;
    return (messages: items, nextCursor: nextCursor);
  }
}
