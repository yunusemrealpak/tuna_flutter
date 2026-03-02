import 'package:equatable/equatable.dart';

// Sentinel used to distinguish "not provided" from explicit null in copyWith.
const _kUnset = Object();

class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.lastSeenAt,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final DateTime? lastSeenAt;
  final DateTime createdAt;

  @override
  List<Object?> get props =>
      [id, username, displayName, avatarUrl, lastSeenAt, createdAt];

  User copyWith({
    String? id,
    String? username,
    String? displayName,
    Object? avatarUrl = _kUnset,
    Object? lastSeenAt = _kUnset,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl == _kUnset ? this.avatarUrl : avatarUrl as String?,
      lastSeenAt:
          lastSeenAt == _kUnset ? this.lastSeenAt : lastSeenAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: (json['display_name'] as String?) ?? json['username'] as String,
        avatarUrl: json['avatar_url'] as String?,
        lastSeenAt: json['last_seen_at'] != null
            ? DateTime.parse(json['last_seen_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'last_seen_at': lastSeenAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
