import 'package:drift/drift.dart';

/// Local cache of channels the user is a member of.
@DataClassName('ChannelRow')
class ChannelsTable extends Table {
  @override
  String get tableName => 'channels';

  TextColumn get id => text()();

  /// 'direct' | 'group' | 'public'
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get avatarUrl => text().nullable().named('avatar_url')();
  TextColumn get createdBy => text().named('created_by')();
  IntColumn get memberCount => integer().named('member_count').withDefault(const Constant(0))();

  // Denormalised last message fields (avoids a JOIN on every list render).
  TextColumn get lastMessageId => text().nullable().named('last_message_id')();
  TextColumn get lastMessageText =>
      text().nullable().named('last_message_text')();
  TextColumn get lastMessageSenderId =>
      text().nullable().named('last_message_sender_id')();
  DateTimeColumn get lastMessageCreatedAt =>
      dateTime().nullable().named('last_message_created_at')();

  IntColumn get unreadCount =>
      integer().named('unread_count').withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
