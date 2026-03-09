import 'package:equatable/equatable.dart';

// Sentinel used to distinguish "not provided" from explicit null in copyWith.
const _kUnset = Object();

/// The type of a [Channel].
enum ChannelType {
  /// One-to-one private conversation.
  direct,

  /// Private group conversation — members must be explicitly added.
  group,

  /// Open channel — any app user can join.
  public,
}

/// A snapshot of the most recent message in a [Channel].
///
/// Displayed in channel list tiles as a preview.
class LastMessage extends Equatable {
  const LastMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.createdAt,
  });

  /// Internal message ID.
  final String id;

  /// Message text content.
  final String text;

  /// ID of the user who sent the message.
  final String senderId;

  /// When the message was created.
  final DateTime createdAt;

  @override
  List<Object> get props => [id, text, senderId, createdAt];

  /// Deserializes a [LastMessage] from the TunaChat API JSON response.
  factory LastMessage.fromJson(Map<String, dynamic> json) => LastMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        senderId: json['sender_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Serializes this last-message snapshot to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender_id': senderId,
        'created_at': createdAt.toIso8601String(),
      };
}

/// A TunaChat channel — the container for messages and members.
///
/// Channels can be [ChannelType.direct] (1-to-1), [ChannelType.group]
/// (invite-only), or [ChannelType.public] (open). Use [ChannelRepository] to
/// create, update, and manage membership.
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

  /// Internal ULID of this channel.
  final String id;

  /// Whether this is a direct, group, or public channel.
  final ChannelType type;

  /// Display name of the channel.
  final String name;

  /// Optional description or topic.
  final String? description;

  /// Optional channel avatar image URL.
  final String? avatarUrl;

  /// Internal ID of the user who created the channel.
  final String createdBy;

  /// Current number of members.
  final int memberCount;

  /// Preview of the most recent message, or null if no messages yet.
  final LastMessage? lastMessage;

  /// Number of unread messages for the currently connected user.
  final int unreadCount;

  /// When this channel was created.
  final DateTime createdAt;

  /// When this channel was last updated (e.g. name change, new message).
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

  /// Returns a copy of this channel with the given fields replaced.
  ///
  /// Pass an explicit `null` to clear [description], [avatarUrl], or [lastMessage].
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

  /// Deserializes a [Channel] from the TunaChat API JSON response.
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

  /// Serializes this channel to a JSON map.
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
