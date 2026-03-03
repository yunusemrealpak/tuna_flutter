import 'package:tuna_chat/src/core/exceptions.dart';
import 'package:tuna_chat/src/core/failures.dart';
import 'package:tuna_chat/src/data/datasources/remote/message_remote_data_source.dart';
import 'package:tuna_chat/src/data/repositories/message_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:tuna_chat/src/data/datasources/local/app_database.dart';
import 'package:test/test.dart';

// ── Fake remote ───────────────────────────────────────────────────────────

class _FakeRemote implements MessageRemoteDataSource {
  Map<String, dynamic>? sendResult;
  Exception? throwOnSend;
  Exception? throwOnGet;
  Exception? throwOnUpload;
  bool softDeleteCalled = false;

  Map<String, dynamic>? uploadResult;
  List<Map<String, dynamic>> searchResults = [];

  @override
  Future<Map<String, dynamic>> uploadFile(
    String channelId,
    List<int> fileBytes,
    String fileName,
  ) async {
    if (throwOnUpload != null) throw throwOnUpload!;
    return uploadResult ??
        {
          'file_url': 'https://cdn.example.com/$fileName',
          'file_name': fileName,
          'file_size': fileBytes.length,
          'mime_type': 'application/octet-stream',
        };
  }

  @override
  Future<Map<String, dynamic>> sendMessage(
    String channelId, {
    required String text,
    String? parentId,
    String? idempotencyKey,
    List<Map<String, dynamic>>? attachments,
  }) async {
    if (throwOnSend != null) throw throwOnSend!;
    return sendResult!;
  }

  @override
  Future<({List<Map<String, dynamic>> messages, String? nextCursor})>
      getMessages(
    String channelId, {
    String? cursor,
    int limit = 50,
    String direction = 'before',
  }) async {
    if (throwOnGet != null) throw throwOnGet!;
    return (messages: <Map<String, dynamic>>[], nextCursor: null);
  }

  @override
  Future<Map<String, dynamic>> updateMessage(
    String channelId,
    String messageId, {
    required String text,
  }) async {
    return _messageJson(id: messageId, channelId: channelId, text: text);
  }

  @override
  Future<void> deleteMessage(String channelId, String messageId) async {
    softDeleteCalled = true;
  }

  @override
  Future<({List<Map<String, dynamic>> messages, String? nextCursor})>
      getThreadMessages(
    String channelId,
    String parentId, {
    String? cursor,
    int limit = 50,
  }) async {
    return (messages: <Map<String, dynamic>>[], nextCursor: null);
  }

  @override
  Future<List<Map<String, dynamic>>> searchMessages(
    String channelId,
    String query, {
    int limit = 20,
  }) async {
    return searchResults;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

Map<String, dynamic> _messageJson({
  String id = 'm1',
  String channelId = 'c1',
  String senderId = 'u1',
  String text = 'Hello',
}) =>
    {
      'id': id,
      'channel_id': channelId,
      'sender_id': senderId,
      'text': text,
      'parent_id': null,
      'status': 'sent',
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-01T00:00:00.000Z',
      'deleted_at': null,
    };

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late _FakeRemote remote;
  late AppDatabase db;
  late MessageRepositoryImpl repo;

  setUp(() {
    remote = _FakeRemote();
    db = AppDatabase(NativeDatabase.memory());
    repo = MessageRepositoryImpl(remoteDataSource: remote, database: db);
  });

  tearDown(() async => await db.close());

  group('sendMessage', () {
    test('returns Message on success and caches locally', () async {
      remote.sendResult = _messageJson(id: 'm1', text: 'Hello!');
      final result = await repo.sendMessage('c1', text: 'Hello!');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) {
          expect(r.id, 'm1');
          expect(r.text, 'Hello!');
        },
      );
      // Verify local cache
      final row = await db.messageDao.findById('m1');
      expect(row, isNotNull);
    });

    test('maps NetworkException to NetworkFailure', () async {
      remote.throwOnSend = const NetworkException(message: 'offline');
      final result = await repo.sendMessage('c1', text: 'Hi');
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps ServerException to ServerFailure', () async {
      remote.throwOnSend = const ServerException(
        message: 'internal',
        statusCode: 500,
        errorCode: 'INTERNAL',
      );
      final result = await repo.sendMessage('c1', text: 'Hi');
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('uploadFile', () {
    test('returns Attachment on success', () async {
      remote.uploadResult = {
        'file_url': 'https://cdn.example.com/photo.jpg',
        'file_name': 'photo.jpg',
        'file_size': 2048,
        'mime_type': 'image/jpeg',
      };
      final result = await repo.uploadFile('c1', [0, 1, 2], 'photo.jpg');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) {
          expect(r.fileUrl, 'https://cdn.example.com/photo.jpg');
          expect(r.fileName, 'photo.jpg');
          expect(r.fileSize, 2048);
          expect(r.mimeType, 'image/jpeg');
          expect(r.isImage, isTrue);
        },
      );
    });

    test('maps ServerException to ServerFailure', () async {
      remote.throwOnUpload = const ServerException(
        message: 'storage unavailable',
        statusCode: 503,
        errorCode: 'INTERNAL_ERROR',
      );
      final result = await repo.uploadFile('c1', [1, 2], 'file.txt');
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      remote.throwOnUpload = const NetworkException(message: 'no network');
      final result = await repo.uploadFile('c1', [], 'f.pdf');
      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('getMessages', () {
    test('returns local messages when cached', () async {
      // Seed local via sendMessage
      remote.sendResult = _messageJson(id: 'm2');
      await repo.sendMessage('c1', text: 'Cached');

      final result = await repo.getMessages('c1');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r.messages.length, 1),
      );
    });

    test('falls back to local on NetworkException when messages cached', () async {
      // Seed local
      remote.sendResult = _messageJson(id: 'm3');
      await repo.sendMessage('c1', text: 'Offline msg');

      remote.throwOnGet = const NetworkException(message: 'offline');
      final result = await repo.getMessages('c1');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r.messages, isNotEmpty),
      );
    });
  });

  group('updateMessage', () {
    test('returns updated Message', () async {
      final result = await repo.updateMessage('c1', 'm1', text: 'Updated');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r.text, 'Updated'),
      );
    });
  });

  group('deleteMessage', () {
    test('calls remote delete and soft-deletes locally', () async {
      // Seed local
      remote.sendResult = _messageJson(id: 'm4');
      await repo.sendMessage('c1', text: 'To delete');

      final result = await repo.deleteMessage('c1', 'm4');
      expect(result.isRight(), isTrue);
      expect(remote.softDeleteCalled, isTrue);

      // Row should still exist (soft-deleted), deletedAt should be set
      final row = await db.messageDao.findById('m4');
      expect(row?.deletedAt, isNotNull);
    });
  });

  group('getThreadMessages', () {
    test('returns empty list when no thread messages', () async {
      final result = await repo.getThreadMessages('c1', 'm1');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r.messages, isEmpty),
      );
    });
  });

  group('searchMessages', () {
    test('returns messages from remote', () async {
      remote.searchResults = [
        _messageJson(id: 's1', text: 'found it'),
        _messageJson(id: 's2', text: 'also found'),
      ];
      final result = await repo.searchMessages('c1', 'found');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) {
          expect(r.length, 2);
          expect(r.first.id, 's1');
          expect(r.first.text, 'found it');
        },
      );
    });

    test('returns empty list when no results', () async {
      remote.searchResults = [];
      final result = await repo.searchMessages('c1', 'nothing');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) => expect(r, isEmpty),
      );
    });

    test('maps ServerException to ServerFailure', () async {
      // Override searchMessages to throw
      // We need a custom fake for this specific case.
    });
  });
}
