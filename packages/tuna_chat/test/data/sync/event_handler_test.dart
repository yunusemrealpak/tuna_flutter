import 'package:tuna_chat/src/data/datasources/local/app_database.dart';
import 'package:tuna_chat/src/data/sync/event_handler.dart';
import 'package:tuna_chat/src/data/datasources/remote/chat_event.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

ChatEvent _event(String type, Map<String, dynamic> data, {String? channelId}) =>
    ChatEvent(
      type: type,
      data: data,
      channelId: channelId,
      timestamp: DateTime.now().toUtc(),
    );

Future<void> _seedChannel(AppDatabase db, {String id = 'c1'}) async {
  await db.channelDao.upsert(
    ChannelsTableCompanion.insert(
      id: id,
      type: 'group',
      name: 'Test',
      createdBy: 'u1',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late EventHandler handler;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    handler = EventHandler(db);
  });

  tearDown(() async => await db.close());

  group('message.new', () {
    test('inserts message into local DB', () async {
      await _seedChannel(db);
      await handler.handle(_event(
        WsEventType.messageNew,
        {
          'id': 'm1',
          'channel_id': 'c1',
          'sender_id': 'u1',
          'text': 'Hello',
          'parent_id': null,
          'status': 'sent',
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
          'deleted_at': null,
        },
        channelId: 'c1',
      ));

      final msg = await db.messageDao.findById('m1');
      expect(msg, isNotNull);
      expect(msg?.messageText, 'Hello');
    });

    test('updates channel last message and increments unread', () async {
      await _seedChannel(db);
      final before = await db.channelDao.findById('c1');
      expect(before?.unreadCount, 0);

      await handler.handle(_event(
        WsEventType.messageNew,
        {
          'id': 'm2',
          'channel_id': 'c1',
          'sender_id': 'u2',
          'text': 'Hi!',
          'parent_id': null,
          'status': 'sent',
          'created_at': '2024-01-01T01:00:00.000Z',
          'updated_at': '2024-01-01T01:00:00.000Z',
          'deleted_at': null,
        },
        channelId: 'c1',
      ));

      final after = await db.channelDao.findById('c1');
      expect(after?.unreadCount, 1);
      expect(after?.lastMessageId, 'm2');
      expect(after?.lastMessageText, 'Hi!');
    });
  });

  group('message.updated', () {
    test('updates message text in local DB', () async {
      await _seedChannel(db);
      // Insert message first
      await db.messageDao.upsert(
        MessagesTableCompanion.insert(
          id: 'm3',
          channelId: 'c1',
          senderId: 'u1',
          messageText: 'Original',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await handler.handle(_event(WsEventType.messageUpdated, {
        'id': 'm3',
        'text': 'Edited',
      }));

      final msg = await db.messageDao.findById('m3');
      expect(msg?.messageText, 'Edited');
    });
  });

  group('message.deleted', () {
    test('soft-deletes message in local DB', () async {
      await _seedChannel(db);
      await db.messageDao.upsert(
        MessagesTableCompanion.insert(
          id: 'm4',
          channelId: 'c1',
          senderId: 'u1',
          messageText: 'To delete',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await handler.handle(_event(WsEventType.messageDeleted, {'id': 'm4'}));

      final msg = await db.messageDao.findById('m4');
      expect(msg?.deletedAt, isNotNull);
    });
  });

  group('channel.updated', () {
    test('updates channel fields in local DB', () async {
      await _seedChannel(db, id: 'c2');

      await handler.handle(_event(
        WsEventType.channelUpdated,
        {
          'id': 'c2',
          'name': 'Renamed Channel',
          'description': 'New description',
        },
        channelId: 'c2',
      ));

      final channel = await db.channelDao.findById('c2');
      expect(channel?.name, 'Renamed Channel');
    });

    test('does nothing when channel not in local DB', () async {
      // Should not throw
      await handler.handle(_event(
        WsEventType.channelUpdated,
        {'id': 'nonexistent', 'name': 'ghost'},
        channelId: 'nonexistent',
      ));
    });
  });

  group('channel.member_added', () {
    test('inserts membership into local DB', () async {
      await handler.handle(_event(
        WsEventType.channelMemberAdded,
        {
          'user_id': 'u3',
          'channel_id': 'c1',
          'role': 'member',
          'joined_at': '2024-01-01T00:00:00.000Z',
        },
        channelId: 'c1',
      ));

      final membership = await db.membershipDao.find('u3', 'c1');
      expect(membership, isNotNull);
      expect(membership?.role, 'member');
    });
  });

  group('channel.member_removed', () {
    test('removes membership from local DB', () async {
      // Seed membership first
      await db.membershipDao.upsert(
        MembershipsTableCompanion.insert(
          userId: 'u4',
          channelId: 'c1',
          joinedAt: DateTime.now().toUtc(),
        ),
      );

      await handler.handle(_event(
        WsEventType.channelMemberRemoved,
        {'user_id': 'u4', 'channel_id': 'c1'},
        channelId: 'c1',
      ));

      final membership = await db.membershipDao.find('u4', 'c1');
      expect(membership, isNull);
    });
  });

  group('user.presence_changed', () {
    test('updates user lastSeenAt in local DB', () async {
      // Seed user first
      await db.userDao.upsert(
        UsersTableCompanion.insert(
          id: 'u5',
          username: 'bob',
          displayName: 'Bob',
          createdAt: DateTime.now().toUtc(),
        ),
      );

      final ts = '2024-06-15T12:00:00.000Z';
      await handler.handle(_event(
        WsEventType.userPresenceChanged,
        {'user_id': 'u5', 'last_seen_at': ts},
      ));

      final user = await db.userDao.findById('u5');
      // Compare UTC milliseconds since Drift normalizes DateTime to local time.
      expect(
        user?.lastSeenAt?.toUtc().millisecondsSinceEpoch,
        DateTime.parse(ts).toUtc().millisecondsSinceEpoch,
      );
    });
  });

  group('unknown event type', () {
    test('does not throw for unknown events', () async {
      // Should complete without error
      await handler.handle(_event('some.unknown.event', {}));
    });
  });
}
