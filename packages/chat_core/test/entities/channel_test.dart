import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  final t1 = DateTime.utc(2026, 1, 2, 8);

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------
  LastMessage makeLastMsg({String id = 'msg1'}) => LastMessage(
        id: id,
        text: 'Hello',
        senderId: 'u1',
        createdAt: t0,
      );

  Channel makeChannel({
    String id = 'ch1',
    ChannelType type = ChannelType.group,
    String name = 'general',
    String? description,
    String? avatarUrl,
    String createdBy = 'u1',
    int memberCount = 3,
    LastMessage? lastMessage,
    int unreadCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Channel(
        id: id,
        type: type,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        createdBy: createdBy,
        memberCount: memberCount,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        createdAt: createdAt ?? t0,
        updatedAt: updatedAt ?? t0,
      );

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------
  group('Channel — equality', () {
    test('same fields → equal', () {
      expect(makeChannel(), equals(makeChannel()));
    });

    test('different id → not equal', () {
      expect(makeChannel(id: 'ch1'), isNot(equals(makeChannel(id: 'ch2'))));
    });

    test('different type → not equal', () {
      expect(
        makeChannel(type: ChannelType.direct),
        isNot(equals(makeChannel(type: ChannelType.public))),
      );
    });

    test('different name → not equal', () {
      expect(makeChannel(name: 'general'), isNot(equals(makeChannel(name: 'random'))));
    });

    test('different memberCount → not equal', () {
      expect(makeChannel(memberCount: 1), isNot(equals(makeChannel(memberCount: 2))));
    });

    test('different unreadCount → not equal', () {
      expect(makeChannel(unreadCount: 0), isNot(equals(makeChannel(unreadCount: 5))));
    });

    test('with lastMessage vs without → not equal', () {
      expect(
        makeChannel(lastMessage: makeLastMsg()),
        isNot(equals(makeChannel())),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------
  group('Channel — copyWith', () {
    test('no args → identical value', () {
      expect(makeChannel().copyWith(), equals(makeChannel()));
    });

    test('name updated', () {
      final copy = makeChannel().copyWith(name: 'random');
      expect(copy.name, 'random');
      expect(copy.id, 'ch1');
    });

    test('type updated', () {
      final copy = makeChannel().copyWith(type: ChannelType.direct);
      expect(copy.type, ChannelType.direct);
    });

    test('memberCount updated', () {
      final copy = makeChannel().copyWith(memberCount: 10);
      expect(copy.memberCount, 10);
    });

    test('unreadCount updated', () {
      final copy = makeChannel().copyWith(unreadCount: 3);
      expect(copy.unreadCount, 3);
    });

    test('lastMessage updated', () {
      final msg = makeLastMsg(id: 'msg99');
      final copy = makeChannel().copyWith(lastMessage: msg);
      expect(copy.lastMessage?.id, 'msg99');
    });

    test('updatedAt updated', () {
      final copy = makeChannel().copyWith(updatedAt: t1);
      expect(copy.updatedAt, t1);
    });

    test('original not mutated', () {
      final original = makeChannel();
      original.copyWith(name: 'new');
      expect(original.name, 'general');
    });
  });

  // ---------------------------------------------------------------------------
  // ChannelType enum
  // ---------------------------------------------------------------------------
  group('ChannelType', () {
    test('all values exist', () {
      expect(ChannelType.values, containsAll([ChannelType.direct, ChannelType.group, ChannelType.public]));
    });
  });

  // ---------------------------------------------------------------------------
  // LastMessage serialization
  // ---------------------------------------------------------------------------
  group('LastMessage — serialization', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'msg1',
        'text': 'Hello',
        'sender_id': 'u1',
        'created_at': t0.toIso8601String(),
      };
      final m = LastMessage.fromJson(json);
      expect(m.id, 'msg1');
      expect(m.text, 'Hello');
      expect(m.senderId, 'u1');
      expect(m.createdAt, t0);
    });

    test('round-trip', () {
      final original = makeLastMsg();
      final restored = LastMessage.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });

  // ---------------------------------------------------------------------------
  // Channel serialization
  // ---------------------------------------------------------------------------
  group('Channel — fromJson', () {
    Map<String, dynamic> baseJson({bool withLastMsg = false}) => {
          'id': 'ch1',
          'type': 'group',
          'name': 'general',
          'description': 'A group channel',
          'avatar_url': null,
          'created_by': 'u1',
          'member_count': 3,
          'last_message': withLastMsg
              ? {
                  'id': 'msg1',
                  'text': 'Hello',
                  'sender_id': 'u1',
                  'created_at': t0.toIso8601String(),
                }
              : null,
          'unread_count': 2,
          'created_at': t0.toIso8601String(),
          'updated_at': t0.toIso8601String(),
        };

    test('group channel parsed', () {
      final ch = Channel.fromJson(baseJson());
      expect(ch.id, 'ch1');
      expect(ch.type, ChannelType.group);
      expect(ch.name, 'general');
      expect(ch.description, 'A group channel');
      expect(ch.memberCount, 3);
      expect(ch.unreadCount, 2);
      expect(ch.lastMessage, isNull);
    });

    test('direct type parsed', () {
      final json = baseJson()..['type'] = 'direct';
      expect(Channel.fromJson(json).type, ChannelType.direct);
    });

    test('public type parsed', () {
      final json = baseJson()..['type'] = 'public';
      expect(Channel.fromJson(json).type, ChannelType.public);
    });

    test('lastMessage parsed when present', () {
      final ch = Channel.fromJson(baseJson(withLastMsg: true));
      expect(ch.lastMessage, isNotNull);
      expect(ch.lastMessage!.id, 'msg1');
    });

    test('null optional fields', () {
      final json = baseJson()
        ..['description'] = null
        ..['avatar_url'] = null;
      final ch = Channel.fromJson(json);
      expect(ch.description, isNull);
      expect(ch.avatarUrl, isNull);
    });
  });

  group('Channel — toJson', () {
    test('type serialized as string', () {
      expect(makeChannel(type: ChannelType.direct).toJson()['type'], 'direct');
      expect(makeChannel(type: ChannelType.group).toJson()['type'], 'group');
      expect(makeChannel(type: ChannelType.public).toJson()['type'], 'public');
    });

    test('lastMessage included when present', () {
      final json = makeChannel(lastMessage: makeLastMsg()).toJson();
      expect(json['last_message'], isNotNull);
    });
  });

  group('Channel — round-trip', () {
    test('channel without lastMessage', () {
      final original = makeChannel(description: 'desc');
      final restored = Channel.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('channel with lastMessage', () {
      final original = makeChannel(lastMessage: makeLastMsg(), unreadCount: 5);
      final restored = Channel.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });
}
