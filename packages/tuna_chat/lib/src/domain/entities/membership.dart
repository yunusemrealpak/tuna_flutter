import 'package:equatable/equatable.dart';

// Sentinel used to distinguish "not provided" from explicit null in copyWith.
const _kUnset = Object();

enum MemberRole { owner, admin, member }

class Membership extends Equatable {
  const Membership({
    required this.userId,
    required this.channelId,
    required this.role,
    this.lastReadMessageId,
    this.lastReadAt,
    required this.joinedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String channelId;
  final MemberRole role;
  final String? lastReadMessageId;
  final DateTime? lastReadAt;
  final DateTime joinedAt;

  /// Populated when loaded from the `/channels/:id/members` endpoint.
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [
        userId,
        channelId,
        role,
        lastReadMessageId,
        lastReadAt,
        joinedAt,
        username,
        displayName,
        avatarUrl,
      ];

  Membership copyWith({
    String? userId,
    String? channelId,
    MemberRole? role,
    Object? lastReadMessageId = _kUnset,
    Object? lastReadAt = _kUnset,
    DateTime? joinedAt,
    Object? username = _kUnset,
    Object? displayName = _kUnset,
    Object? avatarUrl = _kUnset,
  }) {
    return Membership(
      userId: userId ?? this.userId,
      channelId: channelId ?? this.channelId,
      role: role ?? this.role,
      lastReadMessageId: lastReadMessageId == _kUnset
          ? this.lastReadMessageId
          : lastReadMessageId as String?,
      lastReadAt:
          lastReadAt == _kUnset ? this.lastReadAt : lastReadAt as DateTime?,
      joinedAt: joinedAt ?? this.joinedAt,
      username: username == _kUnset ? this.username : username as String?,
      displayName:
          displayName == _kUnset ? this.displayName : displayName as String?,
      avatarUrl: avatarUrl == _kUnset ? this.avatarUrl : avatarUrl as String?,
    );
  }

  static MemberRole _roleFromString(String raw) {
    switch (raw) {
      case 'owner':
        return MemberRole.owner;
      case 'admin':
        return MemberRole.admin;
      case 'member':
        return MemberRole.member;
      default:
        // R009/R010: warn on unknown role values to surface API contract regressions.
        // ignore: avoid_print
        print('[chat_core] WARNING: Unknown MemberRole value "$raw", defaulting to member.');
        return MemberRole.member;
    }
  }

  /// Parses a membership from the standard membership JSON (includes channel_id).
  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        userId: json['user_id'] as String,
        channelId: json['channel_id'] as String,
        role: _roleFromString((json['role'] as String?) ?? 'member'),
        lastReadMessageId: json['last_read_message_id'] as String?,
        lastReadAt: json['last_read_at'] != null
            ? DateTime.parse(json['last_read_at'] as String)
            : null,
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );

  /// Parses a membership from the `GET /channels/:id/members` response, where
  /// `channel_id` is not present per item but user display fields are included.
  factory Membership.fromMembersJson(
    Map<String, dynamic> json, {
    required String channelId,
  }) =>
      Membership(
        userId: json['user_id'] as String,
        channelId: channelId,
        role: _roleFromString((json['role'] as String?) ?? 'member'),
        joinedAt: DateTime.parse(json['joined_at'] as String),
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'channel_id': channelId,
        'role': role.name,
        'last_read_message_id': lastReadMessageId,
        'last_read_at': lastReadAt?.toIso8601String(),
        'joined_at': joinedAt.toIso8601String(),
      };
}
