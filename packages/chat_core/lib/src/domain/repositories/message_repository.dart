import '../../core/type_defs.dart';
import '../entities/message.dart';

abstract class MessageRepository {
  FutureEither<Message> sendMessage(
    String channelId, {
    required String text,
    String? parentId,
    String? idempotencyKey,
  });

  FutureEither<({List<Message> messages, String? nextCursor})> getMessages(
    String channelId, {
    String? cursor,
    int limit = 50,
    String direction = 'before',
  });

  FutureEither<Message> updateMessage(
    String channelId,
    String messageId, {
    required String text,
  });

  FutureEither<void> deleteMessage(String channelId, String messageId);

  FutureEither<({List<Message> messages, String? nextCursor})> getThreadMessages(
    String channelId,
    String parentId, {
    String? cursor,
    int limit = 50,
  });
}
