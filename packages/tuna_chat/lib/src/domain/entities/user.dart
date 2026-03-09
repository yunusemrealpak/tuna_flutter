import 'package:equatable/equatable.dart';

// Sentinel used to distinguish "not provided" from explicit null in copyWith.
const _kUnset = Object();

/// A TunaChat user.
///
/// Users are created by the host backend via the Server-to-Server API and
/// identified by their [id] (internal ULID) and [username] (the host app's
/// `external_id`).
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.lastSeenAt,
    required this.createdAt,
  });

  /// Internal ULID assigned by TunaChat.
  final String id;

  /// Unique username within the app (mapped from host app's `external_id`).
  final String username;

  /// Human-readable display name. Falls back to [username] if not set.
  final String displayName;

  /// Optional avatar image URL.
  final String? avatarUrl;

  /// Timestamp of the user's last known activity.
  final DateTime? lastSeenAt;

  /// When the user record was created in TunaChat.
  final DateTime createdAt;

  @override
  List<Object?> get props =>
      [id, username, displayName, avatarUrl, lastSeenAt, createdAt];

  /// Returns a copy of this user with the given fields replaced.
  ///
  /// Pass an explicit `null` to clear [avatarUrl] or [lastSeenAt]:
  /// ```dart
  /// user.copyWith(avatarUrl: null); // clears the avatar
  /// ```
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

  /// Deserializes a [User] from the TunaChat API JSON response.
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

  /// Serializes this user to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'last_seen_at': lastSeenAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
