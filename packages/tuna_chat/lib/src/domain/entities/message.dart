import 'package:equatable/equatable.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

class Message extends Equatable {
  const Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.text,
    this.parentId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.replyCount = 0,
  });

  final String id;
  final String channelId;
  final String senderId;
  final String text;
  final String? parentId;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Number of direct thread replies (non-deleted). Populated from the
  /// server's `reply_count` field; defaults to 0 for sent/local messages.
  final int replyCount;

  bool get isDeleted => deletedAt != null;
  bool get isThread => parentId != null;

  @override
  List<Object?> get props => [
        id,
        channelId,
        senderId,
        text,
        parentId,
        status,
        createdAt,
        updatedAt,
        deletedAt,
        replyCount,
      ];

  Message copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? text,
    String? parentId,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? replyCount,
  }) {
    return Message(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      parentId: parentId ?? this.parentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      replyCount: replyCount ?? this.replyCount,
    );
  }

  static MessageStatus _statusFromString(String raw) {
    switch (raw) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        // R010: warn on unknown enum values to surface API contract regressions.
        // ignore: avoid_print
        print('[chat_core] WARNING: Unknown MessageStatus value "$raw", defaulting to sent.');
        return MessageStatus.sent;
    }
  }

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        channelId: json['channel_id'] as String,
        senderId: json['sender_id'] as String,
        text: json['text'] as String,
        parentId: json['parent_id'] as String?,
        status: _statusFromString((json['status'] as String?) ?? 'sent'),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        replyCount: (json['reply_count'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_id': channelId,
        'sender_id': senderId,
        'text': text,
        'parent_id': parentId,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'reply_count': replyCount,
      };
}
