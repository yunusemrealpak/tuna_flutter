import '../../core/type_defs.dart';
import '../entities/attachment.dart';
import '../entities/message.dart';

/// Repository for sending, fetching, and managing chat messages.
///
/// All methods return [FutureEither] — fold on the result to handle
/// [Failure] (network / auth / server errors) and success values.
abstract class MessageRepository {
  /// Uploads a file to the storage backend and returns the resulting [Attachment].
  ///
  /// Call this before [sendMessage] when attaching a file:
  /// ```dart
  /// final attachment = await repo.uploadFile(channelId, bytes, 'photo.jpg');
  /// await repo.sendMessage(channelId, text: '', attachments: [attachment]);
  /// ```
  FutureEither<Attachment> uploadFile(
    String channelId,
    List<int> fileBytes,
    String fileName,
  );

  /// Sends a message to [channelId].
  ///
  /// - [text]: message text (required; pass `' '` when sending attachment-only)
  /// - [parentId]: non-null to create a thread reply
  /// - [idempotencyKey]: optional deduplication key (UUID recommended)
  /// - [attachments]: pre-uploaded file attachments
  FutureEither<Message> sendMessage(
    String channelId, {
    required String text,
    String? parentId,
    String? idempotencyKey,
    List<Attachment>? attachments,
  });

  /// Returns a paginated list of messages for [channelId].
  ///
  /// - [cursor]: message ID to paginate from
  /// - [direction]: `'before'` (default) or `'after'`
  FutureEither<({List<Message> messages, String? nextCursor})> getMessages(
    String channelId, {
    String? cursor,
    int limit = 50,
    String direction = 'before',
  });

  /// Updates the text of an existing message.
  FutureEither<Message> updateMessage(
    String channelId,
    String messageId, {
    required String text,
  });

  /// Soft-deletes a message. The message remains in the list but
  /// [Message.isDeleted] returns `true`.
  FutureEither<void> deleteMessage(String channelId, String messageId);

  /// Returns thread replies for [parentId] in [channelId].
  FutureEither<({List<Message> messages, String? nextCursor})> getThreadMessages(
    String channelId,
    String parentId, {
    String? cursor,
    int limit = 50,
  });

  /// Full-text message search within a channel (powered by Meilisearch).
  ///
  /// Results are not cached locally — each call hits the search index.
  FutureEither<List<Message>> searchMessages(
    String channelId,
    String query, {
    int limit = 20,
  });
}
