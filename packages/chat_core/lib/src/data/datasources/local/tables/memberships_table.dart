import 'package:drift/drift.dart';

/// Tracks which user belongs to which channel and their role.
///
/// FK integrity is enforced at runtime via `PRAGMA foreign_keys = ON`
/// (set in [AppDatabase.migration]).
@DataClassName('MembershipRow')
class MembershipsTable extends Table {
  @override
  String get tableName => 'memberships';

  TextColumn get userId => text().named('user_id')();
  TextColumn get channelId => text().named('channel_id')();

  /// 'owner' | 'admin' | 'member'
  TextColumn get role => text().withDefault(const Constant('member'))();

  TextColumn get lastReadMessageId =>
      text().nullable().named('last_read_message_id')();
  DateTimeColumn get lastReadAt =>
      dateTime().nullable().named('last_read_at')();
  DateTimeColumn get joinedAt => dateTime().named('joined_at')();

  @override
  Set<Column> get primaryKey => {userId, channelId};
}
