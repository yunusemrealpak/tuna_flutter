import 'package:drift/drift.dart';

/// Local cache of user profiles.
@DataClassName('UserRow')
class UsersTable extends Table {
  @override
  String get tableName => 'users';

  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get displayName => text().named('display_name')();
  TextColumn get avatarUrl => text().nullable().named('avatar_url')();
  DateTimeColumn get lastSeenAt =>
      dateTime().nullable().named('last_seen_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
