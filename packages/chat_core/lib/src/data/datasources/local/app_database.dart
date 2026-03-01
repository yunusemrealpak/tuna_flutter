import 'package:drift/drift.dart';

import 'daos/channel_dao.dart';
import 'daos/membership_dao.dart';
import 'daos/message_dao.dart';
import 'daos/pending_event_dao.dart';
import 'daos/user_dao.dart';
import 'tables/channels_table.dart';
import 'tables/memberships_table.dart';
import 'tables/messages_table.dart';
import 'tables/pending_events_table.dart';
import 'tables/users_table.dart';

part 'app_database.g.dart';

/// The local SQLite database for the Chat SDK.
///
/// Takes a [QueryExecutor] so the concrete SQLite backend (NativeDatabase with
/// a file path from path_provider) is provided by `chat_flutter`, keeping this
/// pure-Dart package free of Flutter-specific dependencies.
///
/// For unit tests use:
/// ```dart
/// AppDatabase(NativeDatabase.memory())
/// ```
@DriftDatabase(
  tables: [
    UsersTable,
    ChannelsTable,
    MessagesTable,
    MembershipsTable,
    PendingEventsTable,
  ],
  daos: [
    UserDao,
    ChannelDao,
    MessageDao,
    MembershipDao,
    PendingEventDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations will be added here.
        },
        beforeOpen: (details) async {
          // Enable foreign key enforcement.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
