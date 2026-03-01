import 'dart:async';

import 'package:drift/drift.dart';
import 'package:dartz/dartz.dart';

import '../../core/exceptions.dart';
import '../../core/failures.dart';
import '../../core/type_defs.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/local/app_database.dart';
import '../datasources/remote/message_remote_data_source.dart';

class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl({
    required MessageRemoteDataSource remoteDataSource,
    required AppDatabase database,
  })  : _remote = remoteDataSource,
        _db = database;

  final MessageRemoteDataSource _remote;
  final AppDatabase _db;

  // ── Private helpers ──────────────────────────────────────────────────────

  Message _messageFromJson(Map<String, dynamic> json) => Message.fromJson(json);

  MessagesTableCompanion _messageToCompanion(
    Message m, {
    String syncStatus = 'synced',
  }) {
    return MessagesTableCompanion(
      id: Value(m.id),
      channelId: Value(m.channelId),
      senderId: Value(m.senderId),
      messageText: Value(m.text),
      parentId: Value(m.parentId),
      status: Value(m.status.name),
      syncStatus: Value(syncStatus),
      createdAt: Value(m.createdAt),
      updatedAt: Value(m.updatedAt),
      deletedAt: Value(m.deletedAt),
    );
  }

  Message _messageFromRow(MessageRow row) {
    return Message(
      id: row.id,
      channelId: row.channelId,
      senderId: row.senderId,
      text: row.messageText,
      parentId: row.parentId,
      status: _statusFromString(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  MessageStatus _statusFromString(String raw) {
    switch (raw) {
      case 'sending':
        return MessageStatus.sending;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  // ── MessageRepository ────────────────────────────────────────────────────

  @override
  FutureEither<Message> sendMessage(
    String channelId, {
    required String text,
    String? parentId,
    String? idempotencyKey,
  }) async {
    try {
      final data = await _remote.sendMessage(
        channelId,
        text: text,
        parentId: parentId,
        idempotencyKey: idempotencyKey,
      );
      final message = _messageFromJson(data);
      await _db.messageDao.upsert(_messageToCompanion(message));
      return Right(message);
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
  FutureEither<({List<Message> messages, String? nextCursor})> getMessages(
    String channelId, {
    String? cursor,
    int limit = 50,
    String direction = 'before',
  }) async {
    try {
      // Return local messages first (offline-first).
      final localRows = await _db.messageDao.findByChannel(
        channelId,
        limit: limit,
        cursor: cursor,
        before: direction == 'before',
      );
      final localMessages = localRows.map(_messageFromRow).toList();

      if (localMessages.isNotEmpty) {
        unawaited(
          _syncMessagesFromRemote(
            channelId,
            cursor: cursor,
            limit: limit,
            direction: direction,
          ),
        );
        return Right((messages: localMessages, nextCursor: null));
      }

      // Cache empty — fetch from remote.
      final result = await _remote.getMessages(
        channelId,
        cursor: cursor,
        limit: limit,
        direction: direction,
      );
      final messages = result.messages.map(_messageFromJson).toList();
      await _db.messageDao
          .upsertAll(messages.map(_messageToCompanion).toList());
      return Right((messages: messages, nextCursor: result.nextCursor));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      // Fall back to local on network error.
      try {
        final localRows = await _db.messageDao.findByChannel(channelId);
        final localMessages = localRows.map(_messageFromRow).toList();
        return Right((messages: localMessages, nextCursor: null));
      } catch (_) {
        return Left(NetworkFailure(message: e.message));
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), errorCode: 'UNKNOWN'));
    }
  }

  Future<void> _syncMessagesFromRemote(
    String channelId, {
    String? cursor,
    int limit = 50,
    String direction = 'before',
  }) async {
    try {
      final result = await _remote.getMessages(
        channelId,
        cursor: cursor,
        limit: limit,
        direction: direction,
      );
      final messages = result.messages.map(_messageFromJson).toList();
      await _db.messageDao
          .upsertAll(messages.map(_messageToCompanion).toList());
    } catch (_) {
      // Ignore background sync errors.
    }
  }

  @override
  FutureEither<Message> updateMessage(
    String channelId,
    String messageId, {
    required String text,
  }) async {
    try {
      final data = await _remote.updateMessage(channelId, messageId, text: text);
      final message = _messageFromJson(data);
      await _db.messageDao.upsert(_messageToCompanion(message));
      return Right(message);
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
  FutureEither<void> deleteMessage(String channelId, String messageId) async {
    try {
      await _remote.deleteMessage(channelId, messageId);
      await _db.messageDao.softDelete(messageId);
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
  FutureEither<({List<Message> messages, String? nextCursor})> getThreadMessages(
    String channelId,
    String parentId, {
    String? cursor,
    int limit = 50,
  }) async {
    try {
      // Return local thread messages first.
      final localRows = await _db.messageDao.findThread(parentId);
      final localMessages = localRows.map(_messageFromRow).toList();

      if (localMessages.isNotEmpty) {
        unawaited(
          _syncThreadFromRemote(channelId, parentId, cursor: cursor, limit: limit),
        );
        return Right((messages: localMessages, nextCursor: null));
      }

      // Fetch from remote.
      final result = await _remote.getThreadMessages(
        channelId,
        parentId,
        cursor: cursor,
        limit: limit,
      );
      final messages = result.messages.map(_messageFromJson).toList();
      await _db.messageDao
          .upsertAll(messages.map(_messageToCompanion).toList());
      return Right((messages: messages, nextCursor: result.nextCursor));
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

  Future<void> _syncThreadFromRemote(
    String channelId,
    String parentId, {
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final result = await _remote.getThreadMessages(
        channelId,
        parentId,
        cursor: cursor,
        limit: limit,
      );
      final messages = result.messages.map(_messageFromJson).toList();
      await _db.messageDao
          .upsertAll(messages.map(_messageToCompanion).toList());
    } catch (_) {
      // Ignore background sync errors.
    }
  }
}
