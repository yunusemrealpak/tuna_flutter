import '../../core/type_defs.dart';
import '../entities/attachment.dart';
import '../entities/message.dart';

abstract class MessageRepository {
  /// Uploads a file and returns the resulting [Attachment] metadata.
  FutureEither<Attachment> uploadFile(
    String channelId,
    List<int> fileBytes,
    String fileName,
  );

  FutureEither<Message> sendMessage(
    String channelId, {
    required String text,
    String? parentId,
    String? idempotencyKey,
    List<Attachment>? attachments,
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

  /// Full-text message search within a channel.
  FutureEither<List<Message>> searchMessages(
    String channelId,
    String query, {
    int limit = 20,
  });
}
