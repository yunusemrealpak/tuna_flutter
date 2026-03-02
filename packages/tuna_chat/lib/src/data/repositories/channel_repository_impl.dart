import 'dart:async';

import 'package:drift/drift.dart';
import 'package:dartz/dartz.dart';

import '../../core/exceptions.dart';
import '../../core/failures.dart';
import '../../core/type_defs.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/membership.dart';
import '../../domain/repositories/channel_repository.dart';
import '../datasources/local/app_database.dart';
import '../datasources/remote/channel_remote_data_source.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  ChannelRepositoryImpl({
    required ChannelRemoteDataSource remoteDataSource,
    required AppDatabase database,
  })  : _remote = remoteDataSource,
        _db = database;

  final ChannelRemoteDataSource _remote;
  final AppDatabase _db;

  // ── Private helpers ──────────────────────────────────────────────────────

  Channel _channelFromJson(Map<String, dynamic> json) =>
      Channel.fromJson(json);

  Membership _membershipFromJson(Map<String, dynamic> json) =>
      Membership.fromJson(json);

  ChannelsTableCompanion _channelToCompanion(Channel c) {
    return ChannelsTableCompanion(
      id: Value(c.id),
      type: Value(c.type.name),
      name: Value(c.name),
      description: Value(c.description),
      avatarUrl: Value(c.avatarUrl),
      createdBy: Value(c.createdBy),
      memberCount: Value(c.memberCount),
      lastMessageId: Value(c.lastMessage?.id),
      lastMessageText: Value(c.lastMessage?.text),
      lastMessageSenderId: Value(c.lastMessage?.senderId),
      lastMessageCreatedAt: Value(c.lastMessage?.createdAt),
      unreadCount: Value(c.unreadCount),
      createdAt: Value(c.createdAt),
      updatedAt: Value(c.updatedAt),
    );
  }

  MembershipsTableCompanion _membershipToCompanion(Membership m) {
    return MembershipsTableCompanion(
      userId: Value(m.userId),
      channelId: Value(m.channelId),
      role: Value(m.role.name),
      lastReadMessageId: Value(m.lastReadMessageId),
      lastReadAt: Value(m.lastReadAt),
      joinedAt: Value(m.joinedAt),
    );
  }

  Channel _channelFromRow(ChannelRow row) {
    LastMessage? lastMessage;
    if (row.lastMessageId != null &&
        row.lastMessageText != null &&
        row.lastMessageSenderId != null &&
        row.lastMessageCreatedAt != null) {
      lastMessage = LastMessage(
        id: row.lastMessageId!,
        text: row.lastMessageText!,
        senderId: row.lastMessageSenderId!,
        createdAt: row.lastMessageCreatedAt!,
      );
    }
    return Channel(
      id: row.id,
      type: _channelTypeFromString(row.type),
      name: row.name,
      description: row.description,
      avatarUrl: row.avatarUrl,
      createdBy: row.createdBy,
      memberCount: row.memberCount,
      lastMessage: lastMessage,
      unreadCount: row.unreadCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ChannelType _channelTypeFromString(String raw) {
    switch (raw) {
      case 'direct':
        return ChannelType.direct;
      case 'public':
        return ChannelType.public;
      default:
        return ChannelType.group;
    }
  }

  Membership _membershipFromRow(MembershipRow row) {
    MemberRole role;
    switch (row.role) {
      case 'owner':
        role = MemberRole.owner;
        break;
      case 'admin':
        role = MemberRole.admin;
        break;
      default:
        role = MemberRole.member;
    }
    return Membership(
      userId: row.userId,
      channelId: row.channelId,
      role: role,
      lastReadMessageId: row.lastReadMessageId,
      lastReadAt: row.lastReadAt,
      joinedAt: row.joinedAt,
    );
  }

  // ── ChannelRepository ────────────────────────────────────────────────────

  @override
  FutureEither<Channel> createChannel({
    required ChannelType type,
    String? name,
    String? description,
    required List<String> memberIds,
  }) async {
    try {
      final data = await _remote.createChannel(
        type: type.name,
        name: name,
        description: description,
        memberIds: memberIds,
      );
      final channel = _channelFromJson(data);
      await _db.channelDao.upsert(_channelToCompanion(channel));
      return Right(channel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<Channel> getChannel(String channelId) async {
    try {
      // Return local first (offline-first), sync from remote in background.
      final local = await _db.channelDao.findById(channelId);
      if (local != null) {
        unawaited(_syncChannelFromRemote(channelId));
        return Right(_channelFromRow(local));
      }
      // Not in cache — fetch from remote.
      final data = await _remote.getChannel(channelId);
      final channel = _channelFromJson(data);
      await _db.channelDao.upsert(_channelToCompanion(channel));
      return Right(channel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  Future<void> _syncChannelFromRemote(String channelId) async {
    try {
      final data = await _remote.getChannel(channelId);
      final channel = _channelFromJson(data);
      await _db.channelDao.upsert(_channelToCompanion(channel));
    } catch (_) {
      // Ignore background sync errors — stale local data is acceptable.
    }
  }

  @override
  FutureEither<({List<Channel> channels, String? nextCursor})> listChannels({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      // When paginating (cursor != null) always fetch from remote so that
      // the server's cursor is respected and subsequent pages work correctly
      // (R-M3-006). First-page requests (cursor == null) use offline-first:
      // return local immediately and sync in background.
      if (cursor == null) {
        final localRows = await _db.channelDao.findAll();
        final localChannels = localRows.map(_channelFromRow).toList();
        if (localChannels.isNotEmpty) {
          unawaited(_syncChannelListFromRemote(cursor: null, limit: limit));
          // nextCursor is unknown from local data; return null to signal
          // "use pull-to-refresh for fresh data with cursor".
          return Right((channels: localChannels, nextCursor: null));
        }
      }

      // Cache empty or explicit pagination cursor: fetch from remote.
      final result = await _remote.listChannels(cursor: cursor, limit: limit);
      final channels = result.channels.map(_channelFromJson).toList();
      await _db.channelDao.upsertAll(channels.map(_channelToCompanion).toList());
      return Right((channels: channels, nextCursor: result.nextCursor));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      // Fall back to local data on network error.
      try {
        final localRows = await _db.channelDao.findAll();
        final localChannels = localRows.map(_channelFromRow).toList();
        return Right((channels: localChannels, nextCursor: null));
      } catch (_) {
        return Left(NetworkFailure(message: e.message));
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  Future<void> _syncChannelListFromRemote({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final result = await _remote.listChannels(cursor: cursor, limit: limit);
      final channels = result.channels.map(_channelFromJson).toList();
      await _db.channelDao.upsertAll(channels.map(_channelToCompanion).toList());
    } catch (_) {
      // Ignore background sync errors.
    }
  }

  @override
  FutureEither<Channel> updateChannel(
    String channelId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final data = await _remote.updateChannel(
        channelId,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
      );
      final channel = _channelFromJson(data);
      await _db.channelDao.upsert(_channelToCompanion(channel));
      return Right(channel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<void> deleteChannel(String channelId) async {
    try {
      await _remote.deleteChannel(channelId);
      await _db.channelDao.deleteById(channelId);
      await _db.membershipDao.removeByChannel(channelId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<Membership> addMember(
    String channelId, {
    required String userId,
    required MemberRole role,
  }) async {
    try {
      final data = await _remote.addMember(
        channelId,
        userId: userId,
        role: role.name,
      );
      final membership = _membershipFromJson(data);
      await _db.membershipDao.upsert(_membershipToCompanion(membership));
      return Right(membership);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<void> removeMember(String channelId, String userId) async {
    try {
      await _remote.removeMember(channelId, userId);
      await _db.membershipDao.removeMember(userId, channelId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<void> markAsRead(String channelId, String messageId) async {
    try {
      await _remote.markAsRead(channelId, messageId);
      // Clear local unread count for the channel.
      final local = await _db.channelDao.findById(channelId);
      if (local != null) {
        await _db.channelDao.upsert(
          _channelToCompanion(_channelFromRow(local).copyWith(unreadCount: 0)),
        );
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  @override
  FutureEither<List<Membership>> getMembers(String channelId) async {
    try {
      // Fetch from remote — always fresh to get user display fields.
      // Local-cache rows don't carry username/displayName/avatarUrl (schema
      // limitation), so we prefer remote data here.
      final data = await _remote.getMembers(channelId);
      final memberships = data
          .map((json) => Membership.fromMembersJson(json, channelId: channelId))
          .toList();
      // Persist core membership fields to local cache.
      await _db.membershipDao
          .upsertAll(memberships.map(_membershipToCompanion).toList());
      return Right(memberships);
    } on NetworkException catch (_) {
      // Fall back to local cache on network error (no user display fields).
      try {
        final localRows = await _db.membershipDao.findByChannel(channelId);
        if (localRows.isNotEmpty) {
          return Right(localRows.map(_membershipFromRow).toList());
        }
        rethrow;
      } catch (e) {
        return Left(NetworkFailure(message: e.toString()));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }
}
