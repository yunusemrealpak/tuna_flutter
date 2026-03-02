import 'package:drift/drift.dart';

/// Queue of operations that have not yet been synced to the server.
///
/// Populated when the user acts offline (e.g. sends a message with no network).
/// The SyncEngine processes this table on reconnect.
@DataClassName('PendingEventRow')
class PendingEventsTable extends Table {
  @override
  String get tableName => 'pending_events';

  IntColumn get id => integer().autoIncrement()();

  /// e.g. 'message.send', 'message.edit', 'message.delete'
  TextColumn get eventType => text().named('event_type')();

  /// JSON-encoded payload for the event.
  TextColumn get payload => text()();

  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}
