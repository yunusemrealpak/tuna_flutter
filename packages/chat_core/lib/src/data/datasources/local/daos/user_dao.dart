import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/users_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<UserRow?> findById(String id) =>
      (select(usersTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<UserRow?> watchById(String id) =>
      (select(usersTable)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<List<UserRow>> findAll() => select(usersTable).get();

  Future<void> upsert(UsersTableCompanion companion) =>
      into(usersTable).insertOnConflictUpdate(companion);

  Future<void> upsertAll(List<UsersTableCompanion> companions) =>
      batch((b) => b.insertAllOnConflictUpdate(usersTable, companions));

  Future<void> deleteById(String id) =>
      (delete(usersTable)..where((t) => t.id.equals(id))).go();

  /// Update the `last_seen_at` timestamp for a user (e.g. from presence events).
  Future<void> updateLastSeen(String userId, DateTime lastSeenAt) =>
      (update(usersTable)..where((t) => t.id.equals(userId))).write(
        UsersTableCompanion(lastSeenAt: Value(lastSeenAt)),
      );
}
