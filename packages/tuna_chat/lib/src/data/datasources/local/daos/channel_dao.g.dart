// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_dao.dart';

// ignore_for_file: type=lint
mixin _$ChannelDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChannelsTableTable get channelsTable => attachedDatabase.channelsTable;
  $MembershipsTableTable get membershipsTable =>
      attachedDatabase.membershipsTable;
  ChannelDaoManager get managers => ChannelDaoManager(this);
}

class ChannelDaoManager {
  final _$ChannelDaoMixin _db;
  ChannelDaoManager(this._db);
  $$ChannelsTableTableTableManager get channelsTable =>
      $$ChannelsTableTableTableManager(_db.attachedDatabase, _db.channelsTable);
  $$MembershipsTableTableTableManager get membershipsTable =>
      $$MembershipsTableTableTableManager(
        _db.attachedDatabase,
        _db.membershipsTable,
      );
}
