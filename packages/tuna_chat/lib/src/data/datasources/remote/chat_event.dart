/// WebSocket event type constants (server → client and client → server).
abstract class WsEventType {
  // Server → Client
  static const String connectionAck = 'connection.ack';
  static const String messageNew = 'message.new';
  static const String messageUpdated = 'message.updated';
  static const String messageDeleted = 'message.deleted';
  static const String channelUpdated = 'channel.updated';
  static const String channelMemberAdded = 'channel.member_added';
  static const String channelMemberRemoved = 'channel.member_removed';
  static const String userPresenceChanged = 'user.presence_changed';
  static const String userTypingStart = 'user.typing_start';
  static const String userTypingStop = 'user.typing_stop';

  // Client → Server
  static const String typingStart = 'typing.start';
  static const String typingStop = 'typing.stop';
  static const String presenceUpdate = 'presence.update';
  static const String connectionResume = 'connection.resume';
}

/// A parsed WebSocket event.
class ChatEvent {
  const ChatEvent({
    required this.type,
    required this.data,
    this.channelId,
    required this.timestamp,
  });

  final String type;
  final Map<String, dynamic> data;
  final String? channelId;
  final DateTime timestamp;

  factory ChatEvent.fromJson(Map<String, dynamic> json) => ChatEvent(
        type: json['type'] as String,
        data: (json['data'] as Map<String, dynamic>?) ?? {},
        channelId: json['channel_id'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now().toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
        if (channelId != null) 'channel_id': channelId,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'ChatEvent(type: $type, channelId: $channelId)';
}
