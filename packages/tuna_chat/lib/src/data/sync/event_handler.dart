import 'package:drift/drift.dart';

import '../datasources/local/app_database.dart';
import '../datasources/remote/chat_event.dart';

/// Handles incoming WebSocket [ChatEvent]s and applies them to the local
/// Drift database so that the UI reflects real-time changes immediately.
class EventHandler {
  EventHandler(this._db);

  final AppDatabase _db;

  /// Dispatch [event] to the appropriate handler.
  Future<void> handle(ChatEvent event) async {
    switch (event.type) {
      case WsEventType.messageNew:
        await _onMessageNew(event);
        break;
      case WsEventType.messageUpdated:
        await _onMessageUpdated(event);
        break;
      case WsEventType.messageDeleted:
        await _onMessageDeleted(event);
        break;
      case WsEventType.channelUpdated:
        await _onChannelUpdated(event);
        break;
      case WsEventType.channelMemberAdded:
        await _onMemberAdded(event);
        break;
      case WsEventType.channelMemberRemoved:
        await _onMemberRemoved(event);
        break;
      case WsEventType.userPresenceChanged:
        await _onPresenceChanged(event);
        break;
      // typing events are ephemeral — no local DB persistence needed.
      default:
        break;
    }
  }

  // ── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _onMessageNew(ChatEvent event) async {
    final data = event.data;
    final msg = _messageCompanionFromJson(data);
    await _db.messageDao.upsert(msg);

    // Update channel's last-message snapshot + increment unread count.
    final channelId = event.channelId ?? data['channel_id'] as String?;
    if (channelId != null) {
      final messageId = data['id'] as String?;
      final text = data['text'] as String?;
      final senderId = data['sender_id'] as String?;
      final createdAtRaw = data['created_at'] as String?;
      if (messageId != null && text != null && senderId != null && createdAtRaw != null) {
        await _db.channelDao.updateLastMessage(
          channelId: channelId,
          messageId: messageId,
          messageText: text,
          senderId: senderId,
          createdAt: DateTime.parse(createdAtRaw),
        );
        await _db.channelDao.incrementUnread(channelId);
      }
    }
  }

  Future<void> _onMessageUpdated(ChatEvent event) async {
    final data = event.data;
    final id = data['id'] as String?;
    final text = data['text'] as String?;
    if (id != null && text != null) {
      await _db.messageDao.updateText(id, text);
    }
  }

  Future<void> _onMessageDeleted(ChatEvent event) async {
    final data = event.data;
    final id = data['id'] as String?;
    if (id != null) {
      await _db.messageDao.softDelete(id);
    }
  }

  Future<void> _onChannelUpdated(ChatEvent event) async {
    final data = event.data;
    final channelId = event.channelId ?? data['id'] as String?;
    if (channelId == null) return;

    final existing = await _db.channelDao.findById(channelId);
    if (existing == null) return;

    await _db.channelDao.upsert(
      ChannelsTableCompanion(
        id: Value(channelId),
        type: Value(existing.type),
        name: Value((data['name'] as String?) ?? existing.name),
        description: Value(data['description'] as String? ?? existing.description),
        avatarUrl: Value(data['avatar_url'] as String? ?? existing.avatarUrl),
        createdBy: Value(existing.createdBy),
        memberCount: Value(
          (data['member_count'] as int?) ?? existing.memberCount,
        ),
        lastMessageId: Value(existing.lastMessageId),
        lastMessageText: Value(existing.lastMessageText),
        lastMessageSenderId: Value(existing.lastMessageSenderId),
        lastMessageCreatedAt: Value(existing.lastMessageCreatedAt),
        unreadCount: Value(existing.unreadCount),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> _onMemberAdded(ChatEvent event) async {
    final data = event.data;
    final userId = data['user_id'] as String?;
    final channelId = event.channelId ?? data['channel_id'] as String?;
    final roleStr = (data['role'] as String?) ?? 'member';
    final joinedAtRaw = data['joined_at'] as String?;

    if (userId == null || channelId == null) return;

    await _db.membershipDao.upsert(
      MembershipsTableCompanion(
        userId: Value(userId),
        channelId: Value(channelId),
        role: Value(roleStr),
        joinedAt: Value(
          joinedAtRaw != null
              ? DateTime.parse(joinedAtRaw)
              : DateTime.now().toUtc(),
        ),
      ),
    );
  }

  Future<void> _onMemberRemoved(ChatEvent event) async {
    final data = event.data;
    final userId = data['user_id'] as String?;
    final channelId = event.channelId ?? data['channel_id'] as String?;
    if (userId == null || channelId == null) return;

    await _db.membershipDao.removeMember(userId, channelId);
  }

  Future<void> _onPresenceChanged(ChatEvent event) async {
    final data = event.data;
    final userId = data['user_id'] as String?;
    final lastSeenAtRaw = data['last_seen_at'] as String?;
    if (userId == null || lastSeenAtRaw == null) return;

    await _db.userDao.updateLastSeen(userId, DateTime.parse(lastSeenAtRaw));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  MessagesTableCompanion _messageCompanionFromJson(Map<String, dynamic> json) {
    final deletedAtRaw = json['deleted_at'] as String?;
    return MessagesTableCompanion(
      id: Value(json['id'] as String),
      channelId: Value(json['channel_id'] as String),
      senderId: Value(json['sender_id'] as String),
      messageText: Value(json['text'] as String),
      parentId: Value(json['parent_id'] as String?),
      status: Value((json['status'] as String?) ?? 'sent'),
      syncStatus: const Value('synced'),
      createdAt: Value(DateTime.parse(json['created_at'] as String)),
      updatedAt: Value(DateTime.parse(json['updated_at'] as String)),
      deletedAt: Value(
        deletedAtRaw != null ? DateTime.parse(deletedAtRaw) : null,
      ),
    );
  }
}
