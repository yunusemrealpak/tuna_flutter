import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  final t1 = DateTime.utc(2026, 1, 2, 8);

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------
  Message makeMsg({
    String id = 'msg1',
    String channelId = 'ch1',
    String senderId = 'u1',
    String text = 'Hello',
    String? parentId,
    MessageStatus status = MessageStatus.sent,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      Message(
        id: id,
        channelId: channelId,
        senderId: senderId,
        text: text,
        parentId: parentId,
        status: status,
        createdAt: createdAt ?? t0,
        updatedAt: updatedAt ?? t0,
        deletedAt: deletedAt,
      );

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------
  group('Message — equality', () {
    test('same fields → equal', () {
      expect(makeMsg(), equals(makeMsg()));
    });

    test('different id → not equal', () {
      expect(makeMsg(id: 'msg1'), isNot(equals(makeMsg(id: 'msg2'))));
    });

    test('different channelId → not equal', () {
      expect(makeMsg(channelId: 'ch1'), isNot(equals(makeMsg(channelId: 'ch2'))));
    });

    test('different senderId → not equal', () {
      expect(makeMsg(senderId: 'u1'), isNot(equals(makeMsg(senderId: 'u2'))));
    });

    test('different text → not equal', () {
      expect(makeMsg(text: 'Hello'), isNot(equals(makeMsg(text: 'Hi'))));
    });

    test('different status → not equal', () {
      expect(
        makeMsg(status: MessageStatus.sent),
        isNot(equals(makeMsg(status: MessageStatus.read))),
      );
    });

    test('thread vs non-thread → not equal', () {
      expect(makeMsg(), isNot(equals(makeMsg(parentId: 'parent1'))));
    });

    test('deleted vs non-deleted → not equal', () {
      expect(makeMsg(), isNot(equals(makeMsg(deletedAt: t1))));
    });
  });

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------
  group('Message — computed properties', () {
    test('isDeleted false when deletedAt is null', () {
      expect(makeMsg().isDeleted, isFalse);
    });

    test('isDeleted true when deletedAt is set', () {
      expect(makeMsg(deletedAt: t1).isDeleted, isTrue);
    });

    test('isThread false when parentId is null', () {
      expect(makeMsg().isThread, isFalse);
    });

    test('isThread true when parentId is set', () {
      expect(makeMsg(parentId: 'parent1').isThread, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------
  group('Message — copyWith', () {
    test('no args → identical value', () {
      expect(makeMsg().copyWith(), equals(makeMsg()));
    });

    test('text updated', () {
      final copy = makeMsg().copyWith(text: 'Updated');
      expect(copy.text, 'Updated');
      expect(copy.id, 'msg1');
    });

    test('status updated', () {
      final copy = makeMsg().copyWith(status: MessageStatus.delivered);
      expect(copy.status, MessageStatus.delivered);
    });

    test('parentId updated', () {
      final copy = makeMsg().copyWith(parentId: 'parent99');
      expect(copy.parentId, 'parent99');
      expect(copy.isThread, isTrue);
    });

    test('updatedAt updated', () {
      final copy = makeMsg().copyWith(updatedAt: t1);
      expect(copy.updatedAt, t1);
    });

    test('deletedAt updated', () {
      final copy = makeMsg().copyWith(deletedAt: t1);
      expect(copy.deletedAt, t1);
      expect(copy.isDeleted, isTrue);
    });

    test('original not mutated', () {
      final original = makeMsg();
      original.copyWith(text: 'Changed');
      expect(original.text, 'Hello');
    });
  });

  // ---------------------------------------------------------------------------
  // MessageStatus enum
  // ---------------------------------------------------------------------------
  group('MessageStatus', () {
    test('all values exist', () {
      expect(
        MessageStatus.values,
        containsAll([
          MessageStatus.sending,
          MessageStatus.sent,
          MessageStatus.delivered,
          MessageStatus.read,
          MessageStatus.failed,
        ]),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------
  group('Message — fromJson', () {
    Map<String, dynamic> baseJson({
      String status = 'sent',
      String? parentId,
      String? deletedAt,
    }) =>
        {
          'id': 'msg1',
          'channel_id': 'ch1',
          'sender_id': 'u1',
          'text': 'Hello',
          'parent_id': parentId,
          'status': status,
          'created_at': t0.toIso8601String(),
          'updated_at': t0.toIso8601String(),
          'deleted_at': deletedAt,
        };

    test('basic message parsed', () {
      final m = Message.fromJson(baseJson());
      expect(m.id, 'msg1');
      expect(m.channelId, 'ch1');
      expect(m.senderId, 'u1');
      expect(m.text, 'Hello');
      expect(m.parentId, isNull);
      expect(m.status, MessageStatus.sent);
      expect(m.deletedAt, isNull);
    });

    for (final entry in {
      'sending': MessageStatus.sending,
      'sent': MessageStatus.sent,
      'delivered': MessageStatus.delivered,
      'read': MessageStatus.read,
      'failed': MessageStatus.failed,
    }.entries) {
      test('status "${entry.key}" parsed', () {
        final m = Message.fromJson(baseJson(status: entry.key));
        expect(m.status, entry.value);
      });
    }

    test('unknown status defaults to sent', () {
      final m = Message.fromJson(baseJson(status: 'unknown_value'));
      expect(m.status, MessageStatus.sent);
    });

    test('thread message with parentId', () {
      final m = Message.fromJson(baseJson(parentId: 'parent1'));
      expect(m.parentId, 'parent1');
      expect(m.isThread, isTrue);
    });

    test('deleted message with deletedAt', () {
      final m = Message.fromJson(baseJson(deletedAt: t1.toIso8601String()));
      expect(m.isDeleted, isTrue);
      expect(m.deletedAt, t1);
    });
  });

  group('Message — toJson', () {
    test('status serialized as string', () {
      expect(makeMsg(status: MessageStatus.sending).toJson()['status'], 'sending');
      expect(makeMsg(status: MessageStatus.read).toJson()['status'], 'read');
      expect(makeMsg(status: MessageStatus.failed).toJson()['status'], 'failed');
    });

    test('null fields serialize as null', () {
      final json = makeMsg().toJson();
      expect(json['parent_id'], isNull);
      expect(json['deleted_at'], isNull);
    });

    test('deletedAt serialized as ISO-8601', () {
      final json = makeMsg(deletedAt: t1).toJson();
      expect(json['deleted_at'], t1.toIso8601String());
    });
  });

  group('Message — round-trip', () {
    test('basic message', () {
      final original = makeMsg();
      expect(Message.fromJson(original.toJson()), equals(original));
    });

    test('thread message', () {
      final original = makeMsg(parentId: 'parent1', status: MessageStatus.delivered);
      expect(Message.fromJson(original.toJson()), equals(original));
    });

    test('deleted message', () {
      final original = makeMsg(deletedAt: t1);
      expect(Message.fromJson(original.toJson()), equals(original));
    });
  });
}
