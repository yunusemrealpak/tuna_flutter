import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/channels_table.dart';
import '../tables/memberships_table.dart';

part 'channel_dao.g.dart';

@DriftAccessor(tables: [ChannelsTable, MembershipsTable])
class ChannelDao extends DatabaseAccessor<AppDatabase> with _$ChannelDaoMixin {
  ChannelDao(super.db);

  /// Returns all channels the current user is a member of, ordered by
  /// the most recent activity (last message timestamp descending).
  Future<List<ChannelRow>> findAll() => (select(channelsTable)
        ..orderBy([
          (t) => OrderingTerm.desc(t.lastMessageCreatedAt),
          (t) => OrderingTerm.desc(t.updatedAt),
        ]))
      .get();

  Stream<List<ChannelRow>> watchAll() => (select(channelsTable)
        ..orderBy([
          (t) => OrderingTerm.desc(t.lastMessageCreatedAt),
          (t) => OrderingTerm.desc(t.updatedAt),
        ]))
      .watch();

  Future<ChannelRow?> findById(String id) =>
      (select(channelsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<ChannelRow?> watchById(String id) =>
      (select(channelsTable)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  Future<void> upsert(ChannelsTableCompanion companion) =>
      into(channelsTable).insertOnConflictUpdate(companion);

  Future<void> upsertAll(List<ChannelsTableCompanion> companions) =>
      batch((b) => b.insertAllOnConflictUpdate(channelsTable, companions));

  Future<void> deleteById(String id) =>
      (delete(channelsTable)..where((t) => t.id.equals(id))).go();

  /// Update the denormalised last-message snapshot on a channel row.
  Future<void> updateLastMessage({
    required String channelId,
    required String messageId,
    required String messageText,
    required String senderId,
    required DateTime createdAt,
  }) =>
      (update(channelsTable)..where((t) => t.id.equals(channelId))).write(
        ChannelsTableCompanion(
          lastMessageId: Value(messageId),
          lastMessageText: Value(messageText),
          lastMessageSenderId: Value(senderId),
          lastMessageCreatedAt: Value(createdAt),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> incrementUnread(String channelId) => customUpdate(
        'UPDATE channels SET unread_count = unread_count + 1 WHERE id = ?',
        variables: [Variable.withString(channelId)],
        updates: {channelsTable},
      );

  Future<void> clearUnread(String channelId) =>
      (update(channelsTable)..where((t) => t.id.equals(channelId))).write(
        const ChannelsTableCompanion(unreadCount: Value(0)),
      );
}
