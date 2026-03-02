// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_event_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingEventDaoMixin on DatabaseAccessor<AppDatabase> {
  $PendingEventsTableTable get pendingEventsTable =>
      attachedDatabase.pendingEventsTable;
  PendingEventDaoManager get managers => PendingEventDaoManager(this);
}

class PendingEventDaoManager {
  final _$PendingEventDaoMixin _db;
  PendingEventDaoManager(this._db);
  $$PendingEventsTableTableTableManager get pendingEventsTable =>
      $$PendingEventsTableTableTableManager(
        _db.attachedDatabase,
        _db.pendingEventsTable,
      );
}
