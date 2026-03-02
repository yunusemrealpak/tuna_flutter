import 'package:tuna_chat/tuna_chat.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:test/test.dart';

/// Creates a fresh in-memory [AppDatabase] for each test.
AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  // ── UserDao ────────────────────────────────────────────────────────────────

  group('UserDao', () {
    final user1 = UsersTableCompanion.insert(
      id: 'u1',
      username: 'alice',
      displayName: 'Alice',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    test('upsert and findById', () async {
      await db.userDao.upsert(user1);
      final row = await db.userDao.findById('u1');
      expect(row?.username, 'alice');
    });

    test('findById returns null for unknown id', () async {
      final row = await db.userDao.findById('nonexistent');
      expect(row, isNull);
    });

    test('upsert updates existing row', () async {
      await db.userDao.upsert(user1);
      await db.userDao.upsert(
        user1.copyWith(displayName: const Value('Alice Updated')),
      );
      final row = await db.userDao.findById('u1');
      expect(row?.displayName, 'Alice Updated');
    });

    test('deleteById removes row', () async {
      await db.userDao.upsert(user1);
      await db.userDao.deleteById('u1');
      final row = await db.userDao.findById('u1');
      expect(row, isNull);
    });

    test('upsertAll inserts multiple rows', () async {
      final user2 = UsersTableCompanion.insert(
        id: 'u2',
        username: 'bob',
        displayName: 'Bob',
        createdAt: DateTime.utc(2026, 1, 2),
      );
      await db.userDao.upsertAll([user1, user2]);
      final all = await db.userDao.findAll();
      expect(all.length, 2);
    });

    test('updateLastSeen updates timestamp', () async {
      await db.userDao.upsert(user1);
      final ts = DateTime.utc(2026, 3, 1, 12, 0, 0);
      await db.userDao.updateLastSeen('u1', ts);
      final row = await db.userDao.findById('u1');
      expect(row?.lastSeenAt?.isAtSameMomentAs(ts), isTrue);
    });
  });

  // ── ChannelDao ─────────────────────────────────────────────────────────────

  group('ChannelDao', () {
    final channel1 = ChannelsTableCompanion.insert(
      id: 'ch1',
      type: 'group',
      name: 'General',
      createdBy: 'u1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    test('upsert and findById', () async {
      await db.channelDao.upsert(channel1);
      final row = await db.channelDao.findById('ch1');
      expect(row?.name, 'General');
    });

    test('findAll returns all channels', () async {
      final ch2 = channel1.copyWith(id: const Value('ch2'), name: const Value('Random'));
      await db.channelDao.upsertAll([channel1, ch2]);
      final all = await db.channelDao.findAll();
      expect(all.length, 2);
    });

    test('deleteById removes channel', () async {
      await db.channelDao.upsert(channel1);
      await db.channelDao.deleteById('ch1');
      expect(await db.channelDao.findById('ch1'), isNull);
    });

    test('clearUnread sets unreadCount to 0', () async {
      final ch = channel1.copyWith(unreadCount: const Value(5));
      await db.channelDao.upsert(ch);
      await db.channelDao.clearUnread('ch1');
      final row = await db.channelDao.findById('ch1');
      expect(row?.unreadCount, 0);
    });

    test('incrementUnread increments by 1', () async {
      await db.channelDao.upsert(channel1);
      await db.channelDao.incrementUnread('ch1');
      await db.channelDao.incrementUnread('ch1');
      final row = await db.channelDao.findById('ch1');
      expect(row?.unreadCount, 2);
    });
  });

  // ── MessageDao ─────────────────────────────────────────────────────────────

  group('MessageDao', () {
    final now = DateTime.utc(2026, 3, 1, 10, 0, 0);

    MessagesTableCompanion buildMessage(String id, {int secondsOffset = 0}) =>
        MessagesTableCompanion.insert(
          id: id,
          channelId: 'ch1',
          senderId: 'u1',
          messageText: 'Message $id',
          createdAt: now.add(Duration(seconds: secondsOffset)),
          updatedAt: now.add(Duration(seconds: secondsOffset)),
        );

    test('upsert and findById', () async {
      await db.messageDao.upsert(buildMessage('m1'));
      final row = await db.messageDao.findById('m1');
      expect(row?.messageText, 'Message m1');
    });

    test('findByChannel returns messages for correct channel', () async {
      await db.messageDao.upsertAll([
        buildMessage('m1'),
        buildMessage('m2', secondsOffset: 1),
        buildMessage('m3', secondsOffset: 2)
            .copyWith(channelId: const Value('ch2')),
      ]);
      final msgs = await db.messageDao.findByChannel('ch1');
      expect(msgs.length, 2);
      expect(msgs.map((m) => m.id), containsAll(['m1', 'm2']));
    });

    test('findByChannel respects limit', () async {
      await db.messageDao.upsertAll([
        buildMessage('m1'),
        buildMessage('m2', secondsOffset: 1),
        buildMessage('m3', secondsOffset: 2),
      ]);
      final msgs = await db.messageDao.findByChannel('ch1', limit: 2);
      expect(msgs.length, 2);
    });

    test('softDelete hides message from findByChannel', () async {
      await db.messageDao.upsert(buildMessage('m1'));
      await db.messageDao.softDelete('m1');
      final msgs = await db.messageDao.findByChannel('ch1');
      expect(msgs, isEmpty);
    });

    test('updateText changes messageText', () async {
      await db.messageDao.upsert(buildMessage('m1'));
      await db.messageDao.updateText('m1', 'Edited text');
      final row = await db.messageDao.findById('m1');
      expect(row?.messageText, 'Edited text');
    });

    test('updateSyncStatus to pending and findPending', () async {
      await db.messageDao.upsert(buildMessage('m1'));
      await db.messageDao.updateSyncStatus('m1', SyncStatus.pending);
      final pending = await db.messageDao.findPending();
      expect(pending.map((m) => m.id), contains('m1'));
    });

    test('findLastByChannel returns most recent message', () async {
      await db.messageDao.upsertAll([
        buildMessage('m1'),
        buildMessage('m2', secondsOffset: 10),
      ]);
      final last = await db.messageDao.findLastByChannel('ch1');
      expect(last?.id, 'm2');
    });
  });

  // ── MembershipDao ──────────────────────────────────────────────────────────

  group('MembershipDao', () {
    final membership = MembershipsTableCompanion.insert(
      userId: 'u1',
      channelId: 'ch1',
      joinedAt: DateTime.utc(2026, 1, 1),
    );

    test('upsert and find', () async {
      await db.membershipDao.upsert(membership);
      final row = await db.membershipDao.find('u1', 'ch1');
      expect(row?.role, 'member');
    });

    test('find returns null for unknown pair', () async {
      final row = await db.membershipDao.find('u1', 'ch99');
      expect(row, isNull);
    });

    test('removeMember removes the row', () async {
      await db.membershipDao.upsert(membership);
      await db.membershipDao.removeMember('u1', 'ch1');
      expect(await db.membershipDao.find('u1', 'ch1'), isNull);
    });

    test('findByChannel returns all members', () async {
      final m2 = membership.copyWith(userId: const Value('u2'));
      await db.membershipDao.upsertAll([membership, m2]);
      final members = await db.membershipDao.findByChannel('ch1');
      expect(members.length, 2);
    });

    test('updateLastRead saves messageId and timestamp', () async {
      await db.membershipDao.upsert(membership);
      final ts = DateTime.utc(2026, 3, 1);
      await db.membershipDao.updateLastRead('u1', 'ch1', 'msg99', ts);
      final row = await db.membershipDao.find('u1', 'ch1');
      expect(row?.lastReadMessageId, 'msg99');
      expect(row?.lastReadAt?.isAtSameMomentAs(ts), isTrue);
    });
  });

  // ── PendingEventDao ────────────────────────────────────────────────────────

  group('PendingEventDao', () {
    final event = PendingEventsTableCompanion.insert(
      eventType: 'message.send',
      payload: '{"text":"hello"}',
      createdAt: DateTime.utc(2026, 3, 1),
    );

    test('insert and findAll', () async {
      await db.pendingEventDao.insert(event);
      final all = await db.pendingEventDao.findAll();
      expect(all.length, 1);
      expect(all.first.eventType, 'message.send');
    });

    test('deleteById removes the event', () async {
      final id = await db.pendingEventDao.insert(event);
      await db.pendingEventDao.deleteById(id);
      final all = await db.pendingEventDao.findAll();
      expect(all, isEmpty);
    });

    test('incrementRetry increases retryCount', () async {
      final id = await db.pendingEventDao.insert(event);
      await db.pendingEventDao.incrementRetry(id);
      await db.pendingEventDao.incrementRetry(id);
      final all = await db.pendingEventDao.findAll();
      expect(all.first.retryCount, 2);
    });

    test('deleteAll clears all events', () async {
      await db.pendingEventDao.insert(event);
      await db.pendingEventDao.insert(event.copyWith(eventType: const Value('message.delete')));
      await db.pendingEventDao.deleteAll();
      expect(await db.pendingEventDao.findAll(), isEmpty);
    });
  });
}
