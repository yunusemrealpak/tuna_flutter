import 'package:equatable/equatable.dart';

// Sentinel used to distinguish "not provided" from explicit null in copyWith.
const _kUnset = Object();

enum ChannelType { direct, group, public }

class LastMessage extends Equatable {
  const LastMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String senderId;
  final DateTime createdAt;

  @override
  List<Object> get props => [id, text, senderId, createdAt];

  factory LastMessage.fromJson(Map<String, dynamic> json) => LastMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        senderId: json['sender_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender_id': senderId,
        'created_at': createdAt.toIso8601String(),
      };
}

class Channel extends Equatable {
  const Channel({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.createdBy,
    required this.memberCount,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ChannelType type;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String createdBy;
  final int memberCount;
  final LastMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        description,
        avatarUrl,
        createdBy,
        memberCount,
        lastMessage,
        unreadCount,
        createdAt,
        updatedAt,
      ];

  Channel copyWith({
    String? id,
    ChannelType? type,
    String? name,
    Object? description = _kUnset,
    Object? avatarUrl = _kUnset,
    String? createdBy,
    int? memberCount,
    Object? lastMessage = _kUnset,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Channel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description:
          description == _kUnset ? this.description : description as String?,
      avatarUrl: avatarUrl == _kUnset ? this.avatarUrl : avatarUrl as String?,
      createdBy: createdBy ?? this.createdBy,
      memberCount: memberCount ?? this.memberCount,
      lastMessage:
          lastMessage == _kUnset ? this.lastMessage : lastMessage as LastMessage?,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static ChannelType _typeFromString(String raw) {
    switch (raw) {
      case 'direct':
        return ChannelType.direct;
      case 'group':
        return ChannelType.group;
      case 'public':
        return ChannelType.public;
      default:
        // R010: warn on unknown enum values to surface API contract regressions.
        // ignore: avoid_print
        print('[chat_core] WARNING: Unknown ChannelType value "$raw", defaulting to group.');
        return ChannelType.group;
    }
  }

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as String,
        type: _typeFromString(json['type'] as String),
        name: (json['name'] as String?) ?? '',
        description: json['description'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdBy: (json['created_by'] as String?) ?? '',
        memberCount: (json['member_count'] as int?) ?? 0,
        lastMessage: json['last_message'] != null
            ? LastMessage.fromJson(
                json['last_message'] as Map<String, dynamic>)
            : null,
        unreadCount: (json['unread_count'] as int?) ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'description': description,
        'avatar_url': avatarUrl,
        'created_by': createdBy,
        'member_count': memberCount,
        'last_message': lastMessage?.toJson(),
        'unread_count': unreadCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
