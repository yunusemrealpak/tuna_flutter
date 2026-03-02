import 'package:tuna_chat/src/core/exceptions.dart';
import 'package:tuna_chat/src/core/failures.dart';
import 'package:tuna_chat/src/data/datasources/remote/channel_remote_data_source.dart';
import 'package:tuna_chat/src/data/repositories/channel_repository_impl.dart';
import 'package:tuna_chat/src/domain/entities/channel.dart';
import 'package:tuna_chat/src/domain/entities/membership.dart';
import 'package:drift/native.dart';
import 'package:tuna_chat/src/data/datasources/local/app_database.dart';
import 'package:test/test.dart';

// ── Fake remote data source ───────────────────────────────────────────────

class _FakeRemote implements ChannelRemoteDataSource {
  Map<String, dynamic>? createResult;
  Map<String, dynamic>? getResult;
  Exception? throwOnCreate;
  Exception? throwOnGet;
  Exception? throwOnList;
  bool deleteCalled = false;
  String? deletedChannelId;

  @override
  Future<Map<String, dynamic>> createChannel({
    required String type,
    String? name,
    String? description,
    required List<String> memberIds,
  }) async {
    if (throwOnCreate != null) throw throwOnCreate!;
    return createResult!;
  }

  @override
  Future<Map<String, dynamic>> getChannel(String channelId) async {
    if (throwOnGet != null) throw throwOnGet!;
    return getResult!;
  }

  @override
  Future<({List<Map<String, dynamic>> channels, String? nextCursor})>
      listChannels({
    String? cursor,
    int limit = 20,
  }) async {
    if (throwOnList != null) throw throwOnList!;
    return (channels: <Map<String, dynamic>>[], nextCursor: null);
  }

  @override
  Future<Map<String, dynamic>> updateChannel(
    String channelId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    return _channelJson(id: channelId, name: name ?? 'updated');
  }

  @override
  Future<void> deleteChannel(String channelId) async {
    deleteCalled = true;
    deletedChannelId = channelId;
  }

  @override
  Future<Map<String, dynamic>> addMember(
    String channelId, {
    required String userId,
    required String role,
  }) async {
    return _membershipJson(userId: userId, channelId: channelId, role: role);
  }

  @override
  Future<void> removeMember(String channelId, String userId) async {}

  @override
  Future<List<Map<String, dynamic>>> getMembers(String channelId) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> markAsRead(
    String channelId,
    String messageId,
  ) async {
    return {
      'channel_id': channelId,
      'user_id': 'u1',
      'last_read_message_id': messageId,
      'last_read_at': '2024-01-01T00:00:00.000Z',
    };
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

Map<String, dynamic> _channelJson({
  String id = 'c1',
  String type = 'group',
  String name = 'Test Channel',
}) =>
    {
      'id': id,
      'type': type,
      'name': name,
      'description': null,
      'avatar_url': null,
      'created_by': 'u1',
      'member_count': 2,
      'last_message': null,
      'unread_count': 0,
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _membershipJson({
  String userId = 'u1',
  String channelId = 'c1',
  String role = 'member',
}) =>
    {
      'user_id': userId,
      'channel_id': channelId,
      'role': role,
      'last_read_message_id': null,
      'last_read_at': null,
      'joined_at': '2024-01-01T00:00:00.000Z',
    };

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late _FakeRemote remote;
  late AppDatabase db;
  late ChannelRepositoryImpl repo;

  setUp(() {
    remote = _FakeRemote();
    db = AppDatabase(NativeDatabase.memory());
    repo = ChannelRepositoryImpl(remoteDataSource: remote, database: db);
  });

  tearDown(() async => await db.close());

  group('createChannel', () {
    test('returns Channel on success and caches locally', () async {
      remote.createResult = _channelJson(id: 'c1', name: 'Alpha');
      final result = await repo.createChannel(
        type: ChannelType.group,
        name: 'Alpha',
        memberIds: ['u1', 'u2'],
      );
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) {
          expect(r.id, 'c1');
          expect(r.name, 'Alpha');
        },
      );
      // Verify local cache
      final row = await db.channelDao.findById('c1');
      expect(row, isNotNull);
    });

    test('maps NetworkException to NetworkFailure', () async {
      remote.throwOnCreate = const NetworkException(message: 'offline');
      final result = await repo.createChannel(
        type: ChannelType.group,
        memberIds: [],
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps ServerException to ServerFailure', () async {
      remote.throwOnCreate = const ServerException(
        message: 'bad',
        statusCode: 500,
        errorCode: 'ERR',
      );
      final result = await repo.createChannel(
        type: ChannelType.group,
        memberIds: [],
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('getChannel', () {
    test('fetches from remote when not in cache', () async {
      remote.getResult = _channelJson(id: 'c2', name: 'Remote Channel');
      final result = await repo.getChannel('c2');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r.name, 'Remote Channel'),
      );
    });

    test('returns cached channel when available', () async {
      // Pre-seed local cache
      remote.createResult = _channelJson(id: 'c3', name: 'Cached');
      await repo.createChannel(type: ChannelType.group, memberIds: []);

      remote.getResult = _channelJson(id: 'c3', name: 'Remote Updated');
      final result = await repo.getChannel('c3');
      expect(result.isRight(), isTrue);
      // Should return local (stale) data
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r.name, 'Cached'),
      );
    });

    test('maps NetworkException to NetworkFailure when no cache', () async {
      remote.throwOnGet = const NetworkException(message: 'offline');
      final result = await repo.getChannel('missing');
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('deleteChannel', () {
    test('calls remote delete and removes from local', () async {
      // Seed local
      remote.createResult = _channelJson(id: 'c4');
      await repo.createChannel(type: ChannelType.group, memberIds: []);

      final result = await repo.deleteChannel('c4');
      expect(result.isRight(), isTrue);
      expect(remote.deletedChannelId, 'c4');
      final row = await db.channelDao.findById('c4');
      expect(row, isNull);
    });
  });

  group('addMember', () {
    test('returns Membership on success', () async {
      final result = await repo.addMember(
        'c1',
        userId: 'u2',
        role: MemberRole.member,
      );
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) {
          expect(r.userId, 'u2');
          expect(r.channelId, 'c1');
        },
      );
    });
  });

  group('listChannels', () {
    test('returns empty list when remote returns empty', () async {
      final result = await repo.listChannels();
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r.channels, isEmpty),
      );
    });

    test('falls back to local on NetworkException with cached data', () async {
      // Seed local first
      remote.createResult = _channelJson(id: 'c5');
      await repo.createChannel(type: ChannelType.group, memberIds: []);

      // Now make list remote throw
      remote.throwOnList = const NetworkException(message: 'offline');
      final result = await repo.listChannels();
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r.channels.length, greaterThanOrEqualTo(1)),
      );
    });
  });
}
