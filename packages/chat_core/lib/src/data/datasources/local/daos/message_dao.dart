import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/messages_table.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [MessagesTable])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  Future<MessageRow?> findById(String id) =>
      (select(messagesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns messages for a channel, ordered oldest-first.
  /// Pass [cursor] (a message id) with [before] to page backwards in history.
  Future<List<MessageRow>> findByChannel(
    String channelId, {
    int limit = 50,
    String? cursor,
    bool before = true,
  }) async {
    final query = select(messagesTable)
      ..where(
          (t) => t.channelId.equals(channelId) & t.deletedAt.isNull());

    if (cursor != null) {
      // ULIDs are lexicographically sortable, so string comparison works.
      if (before) {
        query.where((t) => t.id.isSmallerThanValue(cursor));
      } else {
        query.where((t) => t.id.isBiggerThanValue(cursor));
      }
    }

    query
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(limit);

    return query.get();
  }

  Stream<List<MessageRow>> watchByChannel(String channelId) =>
      (select(messagesTable)
            ..where(
                (t) => t.channelId.equals(channelId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<MessageRow?> findLastByChannel(String channelId) =>
      (select(messagesTable)
            ..where(
                (t) => t.channelId.equals(channelId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Thread messages (replies to [parentId]).
  Future<List<MessageRow>> findThread(String parentId) =>
      (select(messagesTable)
            ..where(
                (t) => t.parentId.equals(parentId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<void> upsert(MessagesTableCompanion companion) =>
      into(messagesTable).insertOnConflictUpdate(companion);

  Future<void> upsertAll(List<MessagesTableCompanion> companions) =>
      batch((b) => b.insertAllOnConflictUpdate(messagesTable, companions));

  /// Soft-delete: sets deleted_at; the row stays in the DB.
  Future<void> softDelete(String id) =>
      (update(messagesTable)..where((t) => t.id.equals(id))).write(
        MessagesTableCompanion(deletedAt: Value(DateTime.now().toUtc())),
      );

  Future<void> updateStatus(String id, String status) =>
      (update(messagesTable)..where((t) => t.id.equals(id))).write(
        MessagesTableCompanion(status: Value(status)),
      );

  Future<void> updateSyncStatus(String id, SyncStatus syncStatus) =>
      (update(messagesTable)..where((t) => t.id.equals(id))).write(
        MessagesTableCompanion(syncStatus: Value(syncStatus.name)),
      );

  /// Update the message body after a server-side edit.
  Future<void> updateText(String id, String newText) =>
      (update(messagesTable)..where((t) => t.id.equals(id))).write(
        MessagesTableCompanion(
          messageText: Value(newText),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  /// All messages still waiting to be sent to the server.
  Future<List<MessageRow>> findPending() =>
      (select(messagesTable)
            ..where((t) => t.syncStatus.equals(SyncStatus.pending.name)))
          .get();

  Future<void> deleteById(String id) =>
      (delete(messagesTable)..where((t) => t.id.equals(id))).go();
}
