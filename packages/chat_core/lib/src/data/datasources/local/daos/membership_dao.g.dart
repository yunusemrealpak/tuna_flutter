// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_dao.dart';

// ignore_for_file: type=lint
mixin _$MembershipDaoMixin on DatabaseAccessor<AppDatabase> {
  $MembershipsTableTable get membershipsTable =>
      attachedDatabase.membershipsTable;
  MembershipDaoManager get managers => MembershipDaoManager(this);
}

class MembershipDaoManager {
  final _$MembershipDaoMixin _db;
  MembershipDaoManager(this._db);
  $$MembershipsTableTableTableManager get membershipsTable =>
      $$MembershipsTableTableTableManager(
        _db.attachedDatabase,
        _db.membershipsTable,
      );
}
