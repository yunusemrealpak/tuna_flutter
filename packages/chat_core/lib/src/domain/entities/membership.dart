import 'package:equatable/equatable.dart';

enum MemberRole { owner, admin, member }

class Membership extends Equatable {
  const Membership({
    required this.userId,
    required this.channelId,
    required this.role,
    this.lastReadMessageId,
    this.lastReadAt,
    required this.joinedAt,
  });

  final String userId;
  final String channelId;
  final MemberRole role;
  final String? lastReadMessageId;
  final DateTime? lastReadAt;
  final DateTime joinedAt;

  @override
  List<Object?> get props =>
      [userId, channelId, role, lastReadMessageId, lastReadAt, joinedAt];

  Membership copyWith({
    String? userId,
    String? channelId,
    MemberRole? role,
    String? lastReadMessageId,
    DateTime? lastReadAt,
    DateTime? joinedAt,
  }) {
    return Membership(
      userId: userId ?? this.userId,
      channelId: channelId ?? this.channelId,
      role: role ?? this.role,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  static MemberRole _roleFromString(String raw) {
    switch (raw) {
      case 'owner':
        return MemberRole.owner;
      case 'admin':
        return MemberRole.admin;
      default:
        return MemberRole.member;
    }
  }

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

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'channel_id': channelId,
        'role': role.name,
        'last_read_message_id': lastReadMessageId,
        'last_read_at': lastReadAt?.toIso8601String(),
        'joined_at': joinedAt.toIso8601String(),
      };
}
