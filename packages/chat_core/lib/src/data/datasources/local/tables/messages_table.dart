import 'package:drift/drift.dart';

/// Offline sync status for a locally-stored message.
enum SyncStatus { pending, synced, failed }

/// Local cache of chat messages.
///
/// The getter [messageText] uses `.named('text')` so the SQL column remains
/// `text` — matching the API contract — while avoiding the name clash with
/// Drift's inherited `text()` column-builder method.
@DataClassName('MessageRow')
class MessagesTable extends Table {
  @override
  String get tableName => 'messages';

  TextColumn get id => text()();
  TextColumn get channelId => text().named('channel_id')();
  TextColumn get senderId => text().named('sender_id')();

  // Named 'text' in SQL; 'messageText' as the Dart accessor to avoid
  // shadowing the inherited text() builder.
  TextColumn get messageText => text().named('text')();

  /// Non-null for thread replies.
  TextColumn get parentId => text().nullable().named('parent_id')();

  /// Message delivery status: 'sending' | 'sent' | 'delivered' | 'read' | 'failed'
  TextColumn get status => text().withDefault(const Constant('sent'))();

  /// Offline sync status: 'pending' | 'synced' | 'failed'
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('synced'))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().nullable().named('deleted_at')();

  @override
  Set<Column> get primaryKey => {id};
}
