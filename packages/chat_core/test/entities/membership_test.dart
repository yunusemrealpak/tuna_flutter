import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  final t1 = DateTime.utc(2026, 1, 2, 8);

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------
  Membership makeMembership({
    String userId = 'u1',
    String channelId = 'ch1',
    MemberRole role = MemberRole.member,
    String? lastReadMessageId,
    DateTime? lastReadAt,
    DateTime? joinedAt,
  }) =>
      Membership(
        userId: userId,
        channelId: channelId,
        role: role,
        lastReadMessageId: lastReadMessageId,
        lastReadAt: lastReadAt,
        joinedAt: joinedAt ?? t0,
      );

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------
  group('Membership — equality', () {
    test('same fields → equal', () {
      expect(makeMembership(), equals(makeMembership()));
    });

    test('different userId → not equal', () {
      expect(makeMembership(userId: 'u1'), isNot(equals(makeMembership(userId: 'u2'))));
    });

    test('different channelId → not equal', () {
      expect(makeMembership(channelId: 'ch1'), isNot(equals(makeMembership(channelId: 'ch2'))));
    });

    test('different role → not equal', () {
      expect(
        makeMembership(role: MemberRole.member),
        isNot(equals(makeMembership(role: MemberRole.admin))),
      );
    });

    test('different lastReadMessageId → not equal', () {
      expect(
        makeMembership(lastReadMessageId: 'msg1'),
        isNot(equals(makeMembership(lastReadMessageId: 'msg2'))),
      );
    });

    test('null vs non-null lastReadAt → not equal', () {
      expect(
        makeMembership(),
        isNot(equals(makeMembership(lastReadAt: t1))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------
  group('Membership — copyWith', () {
    test('no args → identical value', () {
      expect(makeMembership().copyWith(), equals(makeMembership()));
    });

    test('role updated', () {
      final copy = makeMembership().copyWith(role: MemberRole.admin);
      expect(copy.role, MemberRole.admin);
      expect(copy.userId, 'u1');
    });

    test('lastReadMessageId updated', () {
      final copy = makeMembership().copyWith(lastReadMessageId: 'msg42');
      expect(copy.lastReadMessageId, 'msg42');
    });

    test('lastReadAt updated', () {
      final copy = makeMembership().copyWith(lastReadAt: t1);
      expect(copy.lastReadAt, t1);
    });

    test('channelId updated', () {
      final copy = makeMembership().copyWith(channelId: 'ch99');
      expect(copy.channelId, 'ch99');
    });

    test('original not mutated', () {
      final original = makeMembership();
      original.copyWith(role: MemberRole.owner);
      expect(original.role, MemberRole.member);
    });
  });

  // ---------------------------------------------------------------------------
  // MemberRole enum
  // ---------------------------------------------------------------------------
  group('MemberRole', () {
    test('all values exist', () {
      expect(MemberRole.values, containsAll([MemberRole.owner, MemberRole.admin, MemberRole.member]));
    });
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------
  group('Membership — fromJson', () {
    Map<String, dynamic> baseJson({
      String role = 'member',
      String? lastReadMessageId,
      String? lastReadAt,
    }) =>
        {
          'user_id': 'u1',
          'channel_id': 'ch1',
          'role': role,
          'last_read_message_id': lastReadMessageId,
          'last_read_at': lastReadAt,
          'joined_at': t0.toIso8601String(),
        };

    test('basic membership parsed', () {
      final m = Membership.fromJson(baseJson());
      expect(m.userId, 'u1');
      expect(m.channelId, 'ch1');
      expect(m.role, MemberRole.member);
      expect(m.lastReadMessageId, isNull);
      expect(m.lastReadAt, isNull);
      expect(m.joinedAt, t0);
    });

    for (final entry in {
      'owner': MemberRole.owner,
      'admin': MemberRole.admin,
      'member': MemberRole.member,
    }.entries) {
      test('role "${entry.key}" parsed', () {
        final m = Membership.fromJson(baseJson(role: entry.key));
        expect(m.role, entry.value);
      });
    }

    test('unknown role defaults to member', () {
      final m = Membership.fromJson(baseJson(role: 'superadmin'));
      expect(m.role, MemberRole.member);
    });

    test('with lastReadMessageId and lastReadAt', () {
      final m = Membership.fromJson(
        baseJson(lastReadMessageId: 'msg10', lastReadAt: t1.toIso8601String()),
      );
      expect(m.lastReadMessageId, 'msg10');
      expect(m.lastReadAt, t1);
    });
  });

  group('Membership — toJson', () {
    test('role serialized as string', () {
      expect(makeMembership(role: MemberRole.owner).toJson()['role'], 'owner');
      expect(makeMembership(role: MemberRole.admin).toJson()['role'], 'admin');
      expect(makeMembership(role: MemberRole.member).toJson()['role'], 'member');
    });

    test('null fields serialize as null', () {
      final json = makeMembership().toJson();
      expect(json['last_read_message_id'], isNull);
      expect(json['last_read_at'], isNull);
    });

    test('lastReadAt serialized as ISO-8601', () {
      final json = makeMembership(lastReadAt: t1).toJson();
      expect(json['last_read_at'], t1.toIso8601String());
    });
  });

  group('Membership — round-trip', () {
    test('basic membership', () {
      final original = makeMembership();
      expect(Membership.fromJson(original.toJson()), equals(original));
    });

    test('owner with read state', () {
      final original = makeMembership(
        role: MemberRole.owner,
        lastReadMessageId: 'msg42',
        lastReadAt: t1,
      );
      expect(Membership.fromJson(original.toJson()), equals(original));
    });
  });
}
