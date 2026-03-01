import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  final t1 = DateTime.utc(2026, 1, 2, 8);

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------
  User makeUser({
    String id = 'u1',
    String username = 'alice',
    String displayName = 'Alice',
    String? avatarUrl,
    DateTime? lastSeenAt,
    DateTime? createdAt,
  }) =>
      User(
        id: id,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        lastSeenAt: lastSeenAt,
        createdAt: createdAt ?? t0,
      );

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------
  group('User — equality', () {
    test('same fields → equal', () {
      expect(makeUser(), equals(makeUser()));
    });

    test('different id → not equal', () {
      expect(makeUser(id: 'u1'), isNot(equals(makeUser(id: 'u2'))));
    });

    test('different username → not equal', () {
      expect(makeUser(username: 'alice'), isNot(equals(makeUser(username: 'bob'))));
    });

    test('different displayName → not equal', () {
      expect(makeUser(displayName: 'Alice'), isNot(equals(makeUser(displayName: 'Alicia'))));
    });

    test('different avatarUrl → not equal', () {
      expect(
        makeUser(avatarUrl: 'https://a.com/1.png'),
        isNot(equals(makeUser(avatarUrl: 'https://a.com/2.png'))),
      );
    });

    test('null vs non-null avatarUrl → not equal', () {
      expect(makeUser(), isNot(equals(makeUser(avatarUrl: 'https://a.com/1.png'))));
    });

    test('different lastSeenAt → not equal', () {
      expect(makeUser(lastSeenAt: t0), isNot(equals(makeUser(lastSeenAt: t1))));
    });

    test('different createdAt → not equal', () {
      expect(makeUser(createdAt: t0), isNot(equals(makeUser(createdAt: t1))));
    });

    test('props list includes all fields', () {
      final u = makeUser(avatarUrl: 'url', lastSeenAt: t1);
      expect(u.props, [u.id, u.username, u.displayName, u.avatarUrl, u.lastSeenAt, u.createdAt]);
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------
  group('User — copyWith', () {
    test('no args → identical value', () {
      final u = makeUser();
      expect(u.copyWith(), equals(u));
    });

    test('id updated, rest unchanged', () {
      final u = makeUser();
      final copy = u.copyWith(id: 'u99');
      expect(copy.id, 'u99');
      expect(copy.username, u.username);
      expect(copy.displayName, u.displayName);
      expect(copy.createdAt, u.createdAt);
    });

    test('username updated', () {
      final copy = makeUser().copyWith(username: 'bob');
      expect(copy.username, 'bob');
    });

    test('displayName updated', () {
      final copy = makeUser().copyWith(displayName: 'Alicia');
      expect(copy.displayName, 'Alicia');
    });

    test('avatarUrl updated', () {
      final copy = makeUser().copyWith(avatarUrl: 'https://new.url/a.png');
      expect(copy.avatarUrl, 'https://new.url/a.png');
    });

    test('lastSeenAt updated', () {
      final copy = makeUser().copyWith(lastSeenAt: t1);
      expect(copy.lastSeenAt, t1);
    });

    test('original is not mutated', () {
      final original = makeUser();
      original.copyWith(username: 'bob');
      expect(original.username, 'alice');
    });
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------
  group('User — fromJson', () {
    test('full JSON with all fields', () {
      final json = {
        'id': 'u1',
        'username': 'alice',
        'display_name': 'Alice',
        'avatar_url': 'https://a.com/1.png',
        'last_seen_at': t1.toIso8601String(),
        'created_at': t0.toIso8601String(),
      };
      final u = User.fromJson(json);
      expect(u.id, 'u1');
      expect(u.username, 'alice');
      expect(u.displayName, 'Alice');
      expect(u.avatarUrl, 'https://a.com/1.png');
      expect(u.lastSeenAt, t1);
      expect(u.createdAt, t0);
    });

    test('null optional fields', () {
      final json = {
        'id': 'u1',
        'username': 'alice',
        'display_name': 'Alice',
        'avatar_url': null,
        'last_seen_at': null,
        'created_at': t0.toIso8601String(),
      };
      final u = User.fromJson(json);
      expect(u.avatarUrl, isNull);
      expect(u.lastSeenAt, isNull);
    });

    test('missing display_name falls back to username', () {
      final json = {
        'id': 'u1',
        'username': 'alice',
        'created_at': t0.toIso8601String(),
      };
      final u = User.fromJson(json);
      expect(u.displayName, 'alice');
    });
  });

  group('User — toJson', () {
    test('produces correct keys', () {
      final u = makeUser(avatarUrl: 'url', lastSeenAt: t1);
      final json = u.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('username'), isTrue);
      expect(json.containsKey('display_name'), isTrue);
      expect(json.containsKey('avatar_url'), isTrue);
      expect(json.containsKey('last_seen_at'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
    });

    test('values match entity fields', () {
      final u = makeUser(avatarUrl: 'url', lastSeenAt: t1);
      final json = u.toJson();
      expect(json['id'], u.id);
      expect(json['username'], u.username);
      expect(json['display_name'], u.displayName);
      expect(json['avatar_url'], u.avatarUrl);
      expect(json['last_seen_at'], t1.toIso8601String());
      expect(json['created_at'], t0.toIso8601String());
    });

    test('null fields serialize as null', () {
      final u = makeUser();
      final json = u.toJson();
      expect(json['avatar_url'], isNull);
      expect(json['last_seen_at'], isNull);
    });
  });

  group('User — fromJson/toJson round-trip', () {
    test('round-trip preserves all fields', () {
      final original = makeUser(avatarUrl: 'https://a.com/1.png', lastSeenAt: t1);
      final restored = User.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });
}
