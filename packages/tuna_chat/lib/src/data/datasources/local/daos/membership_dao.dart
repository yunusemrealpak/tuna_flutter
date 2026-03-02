import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/memberships_table.dart';

part 'membership_dao.g.dart';

@DriftAccessor(tables: [MembershipsTable])
class MembershipDao extends DatabaseAccessor<AppDatabase>
    with _$MembershipDaoMixin {
  MembershipDao(super.db);

  Future<MembershipRow?> find(String userId, String channelId) =>
      (select(membershipsTable)
            ..where(
              (t) =>
                  t.userId.equals(userId) & t.channelId.equals(channelId),
            ))
          .getSingleOrNull();

  Future<List<MembershipRow>> findByChannel(String channelId) =>
      (select(membershipsTable)
            ..where((t) => t.channelId.equals(channelId)))
          .get();

  Future<List<MembershipRow>> findByUser(String userId) =>
      (select(membershipsTable)..where((t) => t.userId.equals(userId))).get();

  Stream<List<MembershipRow>> watchByChannel(String channelId) =>
      (select(membershipsTable)
            ..where((t) => t.channelId.equals(channelId)))
          .watch();

  Future<void> upsert(MembershipsTableCompanion companion) =>
      into(membershipsTable).insertOnConflictUpdate(companion);

  Future<void> upsertAll(List<MembershipsTableCompanion> companions) =>
      batch((b) => b.insertAllOnConflictUpdate(membershipsTable, companions));

  Future<void> removeMember(String userId, String channelId) =>
      (delete(membershipsTable)
            ..where(
              (t) =>
                  t.userId.equals(userId) & t.channelId.equals(channelId),
            ))
          .go();

  Future<void> removeByChannel(String channelId) =>
      (delete(membershipsTable)
            ..where((t) => t.channelId.equals(channelId)))
          .go();

  Future<void> updateLastRead(
    String userId,
    String channelId,
    String messageId,
    DateTime readAt,
  ) =>
      (update(membershipsTable)
            ..where(
              (t) =>
                  t.userId.equals(userId) & t.channelId.equals(channelId),
            ))
          .write(
        MembershipsTableCompanion(
          lastReadMessageId: Value(messageId),
          lastReadAt: Value(readAt),
        ),
      );
}
